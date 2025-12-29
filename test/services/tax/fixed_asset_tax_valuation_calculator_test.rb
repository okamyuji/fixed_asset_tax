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
        acquired_on: Date.new(2020, 1, 1)
      )
      @policy = create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        method: "declining_balance",
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

      # 最低限度額: 100,000 × 0.05 = 5,000
      # 通常評価: 100,000 × (1 - 0.206 × 0.5) = 89,700
      # 89,700 > 5,000 なので通常評価額を使用

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      assert_equal 89_700, result[:valuation]
      assert_equal false, result[:is_minimum]
    end

    # ==================== 2年目以降の計算テスト ====================

    test "calculates second year valuation" do
      # 前年度の評価額を設定
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
      # 前年度データなしで2年目を計算
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2021
      )

      result = calculator.call

      assert result[:success]
      assert_equal 1, result[:years_elapsed]
      # 遡って計算: 1年目 897,000 → 2年目 712,218
      assert_equal 712_218, result[:valuation]
    end

    test "respects minimum threshold in subsequent years" do
      # 何年も償却して最低限度額近くになった場合
      # 最低限度額: 1,000,000 × 0.05 = 50,000

      # 前年度の評価額を最低限度額ギリギリに設定
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
      # 通常計算: 60,000 × (1 - 0.206) = 47,640
      # 最低限度額: 50,000
      # 最低限度額の方が大きいので、50,000
      assert_equal 50_000, result[:valuation]
      assert_equal true, result[:is_minimum]
    end

    # ==================== 耐用年数別のテスト ====================

    test "uses correct depreciation rate for different useful lives" do
      test_cases = [
        { years: 5, rate: 0.369 },
        { years: 10, rate: 0.206 },
        { years: 15, rate: 0.142 },
        { years: 20, rate: 0.109 }
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

    test "interpolates depreciation rate for non-standard useful life" do
      # 耐用年数12年（テーブルになし）
      @policy.update!(useful_life_years: 12)

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2020
      )

      result = calculator.call

      assert result[:success]
      # 10年: 0.206, 15年: 0.142の間で補間
      # 計算: 0.206 + (0.142 - 0.206) * (12 - 10) / (15 - 10) = 0.1804
      assert_in_delta 0.1804, result[:depreciation_rate], 0.001
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
      # 1,000 × (1 - 0.206 × 0.5) = 897
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
      # 100,000,000 × (1 - 0.206 × 0.5) = 89,700,000
      assert_equal 89_700_000, result[:valuation]
    end

    test "handles acquisition in future year" do
      @fixed_asset.update!(acquired_on: Date.new(2026, 1, 1))

      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2025
      )

      result = calculator.call

      assert_equal false, result[:success]
      assert_equal "Fiscal year is before acquisition date", result[:error]
    end

    test "calculates valuation many years after acquisition" do
      # 5年経過
      calculator = FixedAssetTaxValuationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year_2025
      )

      result = calculator.call

      assert result[:success]
      assert_equal 5, result[:years_elapsed]
      # 最低限度額: 50,000 を下回らないこと
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

      # depreciation_policyがない場合は、デフォルト耐用年数で計算
      assert result[:success]
      assert_not_nil result[:valuation]
    end
  end
end
