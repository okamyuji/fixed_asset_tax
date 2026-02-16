require "test_helper"

module Tax
  class FixedAssetTaxValuationCalculatorTest < ActiveSupport::TestCase
    setup do
      @tenant = create(:tenant)
      @party = create(:party, tenant: @tenant)
      @municipality = create(:municipality)
      @property = create(:depreciable_property, tenant: @tenant, party: @party, municipality: @municipality)
      @fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: @property,
        acquisition_cost: 1_000_000,
        acquired_on: Date.new(2019, 4, 1)
      )
      @policy = create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        method: "declining_balance_200",
        useful_life_years: 10,
        residual_rate: 0.0
      )
      @fiscal_year_2020 = create(:fiscal_year, year: 2020)
      @fiscal_year_2021 = create(:fiscal_year, year: 2021)
      @fiscal_year_2025 = create(:fiscal_year, year: 2025)
    end

    # ==================== 初年度の計算テスト ====================

    test "calculates first year valuation with half-year depreciation" do
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      assert_equal 0, result[:years_elapsed]
      # 減価率: 0.206 (耐用年数10年)
      # 初年度: 1,000,000 × (1 - 0.206 × 0.5) = 897,000
      assert_equal 897_000, result[:valuation]
      assert_equal 0.206, result[:depreciation_rate]
      assert_equal false, result[:is_minimum]
    end

    test "first year valuation respects minimum threshold" do
      @fixed_asset.update!(acquisition_cost: 100_000)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      # 100,000 × (1 - 0.206 × 0.5) = 89,700
      assert_equal 89_700, result[:valuation]
      assert_equal false, result[:is_minimum]
    end

    # ==================== 2年目以降の計算テスト ====================

    test "calculates second year valuation" do
      create(:asset_valuation,
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year_2020,
        property: @property,
        assessed_value: 897_000
      )

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2021
      )

      result = calculator.call

      assert result[:success]
      assert_equal 1, result[:years_elapsed]
      assert_equal 897_000, result[:previous_valuation]
      # 2年目: 897,000 × (1 - 0.206) = 712,218
      assert_equal 712_218, result[:valuation]
    end

    test "calculates valuation retroactively when no previous data" do
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2021
      )

      result = calculator.call

      assert result[:success]
      assert_equal 1, result[:years_elapsed]
      assert_equal 712_218, result[:valuation]
    end

    test "respects minimum threshold in subsequent years" do
      create(:asset_valuation,
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year_2020,
        property: @property,
        assessed_value: 60_000
      )

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2021
      )

      result = calculator.call

      assert result[:success]
      # 60,000 × (1 - 0.206) = 47,640 → 最低限度額 50,000
      assert_equal 50_000, result[:valuation]
      assert_equal true, result[:is_minimum]
    end

    # ==================== 耐用年数別のテスト ====================

    test "uses correct depreciation rate for different useful lives" do
      test_cases = [
        { years: 2, rate: 0.684 },
        { years: 5, rate: 0.369 },
        { years: 10, rate: 0.206 },
        { years: 15, rate: 0.142 },
        { years: 20, rate: 0.109 },
        { years: 30, rate: 0.074 },
        { years: 50, rate: 0.045 }
      ]

      test_cases.each do |test_case|
        @policy.update!(useful_life_years: test_case[:years])

        calculator = FixedAssetTaxValuationCalculator.new(
          fixed_asset: @fixed_asset,
          fiscal_year: @fiscal_year_2020
        )

        result = calculator.call

        assert result[:success]
        assert_equal test_case[:rate], result[:depreciation_rate],
                     "Expected rate #{test_case[:rate]} for #{test_case[:years]} years"
      end
    end

    test "uses exact rate for useful life 12 from full table" do
      @policy.update!(useful_life_years: 12)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      # OLD_DECLINING_BALANCE_RATES[12] = 0.175（補間なし、テーブルから直接取得）
      assert_equal 0.175, result[:depreciation_rate]
    end

    # ==================== 1月1日取得ルール ====================

    test "january 1 acquisition assessed in same year" do
      @fixed_asset.update!(acquired_on: Date.new(2020, 1, 1))

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      # 2020年1月1日取得 → 賦課期日に所有 → 2020年度が初年度
      assert_equal 0, result[:years_elapsed]
    end

    test "january 2 acquisition assessed next year" do
      @fixed_asset.update!(acquired_on: Date.new(2020, 1, 2))

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2021
      )

      result = calculator.call

      assert result[:success]
      # 2020年1月2日取得 → 初回賦課は2021年度
      assert_equal 0, result[:years_elapsed]
    end

    # ==================== 東京都手引き計算例 ====================

    test "tokyo guide example 1: pavement R4/9, 2,700,000, useful life 15" do
      @fixed_asset.update!(acquisition_cost: 2_700_000, acquired_on: Date.new(2022, 9, 1))
      @policy.update!(useful_life_years: 15)

      fy_r5 = create(:fiscal_year, year: 2023)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: fy_r5
      )

      result = calculator.call

      assert result[:success]
      assert_equal 0.142, result[:depreciation_rate]
      # R5年度（初年度）: 2,700,000 × (1 - 0.142/2) = 2,700,000 × 0.929 = 2,508,300
      assert_equal 2_508_300, result[:valuation]
    end

    test "tokyo guide example 2: room air conditioner R3/11, 500,000, useful life 6" do
      @fixed_asset.update!(acquisition_cost: 500_000, acquired_on: Date.new(2021, 11, 1))
      @policy.update!(useful_life_years: 6)

      fy_r4 = create(:fiscal_year, year: 2022)
      fy_r5 = create(:fiscal_year, year: 2023)

      # R4年度（初年度）
      calc_r4 = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: fy_r4
      )
      result_r4 = calc_r4.call
      assert result_r4[:success]
      assert_equal 0.319, result_r4[:depreciation_rate]
      # 500,000 × (1 - 0.319/2) = 500,000 × 0.8405 = 420,250
      assert_equal 420_250, result_r4[:valuation]

      # R5年度（2年目）- 前年度評価額を保存
      create(:asset_valuation,
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: fy_r4,
        property: @property,
        assessed_value: 420_250
      )

      calc_r5 = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: fy_r5
      )
      result_r5 = calc_r5.call
      assert result_r5[:success]
      # 420,250 × (1 - 0.319) = 420,250 × 0.681 = 286,190.25 → 286,190
      assert_equal 286_190, result_r5[:valuation]
    end

    test "tokyo guide example 3: signboard R3/2, 1,655,300, useful life 3" do
      @fixed_asset.update!(acquisition_cost: 1_655_300, acquired_on: Date.new(2021, 2, 1))
      @policy.update!(useful_life_years: 3)

      fy_r4 = create(:fiscal_year, year: 2022)
      fy_r5 = create(:fiscal_year, year: 2023)

      # R4年度（初年度）
      calc_r4 = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: fy_r4
      )
      result_r4 = calc_r4.call
      assert result_r4[:success]
      assert_equal 0.536, result_r4[:depreciation_rate]
      # 1,655,300 × (1 - 0.536/2) = 1,655,300 × 0.732 = 1,211,679.6 → 1,211,680
      assert_equal 1_211_680, result_r4[:valuation]

      # R5年度
      create(:asset_valuation,
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: fy_r4,
        property: @property,
        assessed_value: 1_211_680
      )

      calc_r5 = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: fy_r5
      )
      result_r5 = calc_r5.call
      assert result_r5[:success]
      # 1,211,680 × (1 - 0.536) = 1,211,680 × 0.464 = 562,219.52 → 562,220
      assert_equal 562_220, result_r5[:valuation]
    end

    # ==================== エッジケースと境界値テスト ====================

    test "handles very small acquisition cost" do
      @fixed_asset.update!(acquisition_cost: 1_000)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      assert_equal 897, result[:valuation]
    end

    test "handles very large acquisition cost" do
      @fixed_asset.update!(acquisition_cost: 100_000_000)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      assert_equal 89_700_000, result[:valuation]
    end

    test "handles acquisition in future year" do
      @fixed_asset.update!(acquired_on: Date.new(2025, 6, 1))

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2025
      )

      result = calculator.call

      # 2025年6月取得 → 初回賦課は2026年度 → 2025年度はまだ対象外
      assert_equal false, result[:success]
      assert_equal "Fiscal year is before acquisition date", result[:error]
    end

    test "calculates valuation many years after acquisition" do
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2025
      )

      result = calculator.call

      assert result[:success]
      assert_equal 5, result[:years_elapsed]
      assert result[:valuation] >= 50_000
    end

    # ==================== 異常系テスト ====================

    test "returns error when fixed asset is nil" do
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: nil,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert_equal false, result[:success]
      assert_equal "Fixed asset not found", result[:error]
    end

    test "returns error when fiscal year is nil" do
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: nil
      )

      result = calculator.call

      assert_equal false, result[:success]
      assert_equal "Fiscal year not found", result[:error]
    end

    test "handles missing depreciation policy gracefully" do
      @policy.destroy
      @fixed_asset.reload

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      assert_not_nil result[:valuation]
    end

    test "handles unusual useful life not in table" do
      @policy.update!(useful_life_years: 99)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      # テーブルにない場合はデフォルト10年（0.206）にフォールバック
      assert_equal 0.206, result[:depreciation_rate]
    end
  end
end
