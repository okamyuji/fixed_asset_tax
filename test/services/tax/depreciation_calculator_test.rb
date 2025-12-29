require "test_helper"

module Tax
  class DepreciationCalculatorTest < ActiveSupport::TestCase
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
        useful_life_years: 10,
        residual_rate: 0.1
      )
      @policy.update_column(:method, "straight_line")
      @fiscal_year = create(:fiscal_year, year: 2025)
    end

    # ==================== 定額法のテスト ====================

    test "calculates straight line depreciation for first year" do
      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 1_000_000, result[:opening_book_value]
      # (1,000,000 * (1 - 0.1)) / 10 = 90,000
      assert_equal 90_000, result[:depreciation_amount]
      assert_equal 910_000, result[:closing_book_value]
    end

    test "straight line depreciation uses previous year closing value" do
      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 1_000_000,
        depreciation_amount: 90_000,
        closing_book_value: 910_000
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 910_000, result[:opening_book_value]
      assert_equal 90_000, result[:depreciation_amount]
      assert_equal 820_000, result[:closing_book_value]
    end

    test "straight line depreciation respects residual value limit" do
      # 残存価額近くまで償却済み
      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 150_000,
        depreciation_amount: 90_000,
        closing_book_value: 110_000
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 110_000, result[:opening_book_value]
      # 残存価額 = 1,000,000 * 0.1 = 100,000
      # 償却可能額 = 110,000 - 100,000 = 10,000（90,000より小さい）
      assert_equal 10_000, result[:depreciation_amount]
      assert_equal 100_000, result[:closing_book_value]
    end

    test "straight line depreciation with zero residual rate" do
      @policy.update!(residual_rate: 0.0)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # (1,000,000 * (1 - 0.0)) / 10 = 100,000
      assert_equal 100_000, result[:depreciation_amount]
      assert_equal 900_000, result[:closing_book_value]
    end

    # ==================== 定率法のテスト（200%定率法） ====================

    test "calculates 200% declining balance depreciation for first year" do
      @policy.update_column(:method, "declining_balance")

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 1_000_000, result[:opening_book_value]
      # 償却率 = 1/10 * 2 = 0.2
      # 償却額 = 1,000,000 * 0.2 = 200,000
      assert_equal 200_000, result[:depreciation_amount]
      assert_equal 800_000, result[:closing_book_value]
    end

    test "200% declining balance depreciation for second year" do
      @policy.update_column(:method, "declining_balance")

      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 1_000_000,
        depreciation_amount: 200_000,
        closing_book_value: 800_000
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 800_000, result[:opening_book_value]
      # 償却額 = 800,000 * 0.2 = 160,000
      assert_equal 160_000, result[:depreciation_amount]
      assert_equal 640_000, result[:closing_book_value]
    end

    test "200% declining balance switches to revised rate when below guarantee" do
      @policy.update_column(:method, "declining_balance")

      # 6年目: 償却保証額を下回る年
      # 期首帳簿価額: 262,144
      # 通常償却額: 262,144 * 0.2 = 52,428.8
      # 償却保証額: 1,000,000 * 0.11430 = 114,300
      # 52,428.8 < 114,300 なので改定償却率に切り替え
      # 改定償却額 = 262,144 * 0.100 = 26,214.4

      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 262_144,
        depreciation_amount: 52_429, # 通常償却
        closing_book_value: 209_715
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 209_715, result[:opening_book_value]
      # 改定償却率 0.100 を使用（耐用年数10年）
      # 改定取得価額 262,144（切り替わった年の期首）
      # 償却額 = 262,144 * 0.100 = 26,214.4 ≒ 26,214
      assert_in_delta 26_214, result[:depreciation_amount], 100
    end

    test "200% declining balance respects residual value limit" do
      @policy.update_column(:method, "declining_balance")

      # 残存価額近くまで償却済み
      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 150_000,
        depreciation_amount: 30_000,
        closing_book_value: 120_000
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 120_000, result[:opening_book_value]
      # 通常償却額 = 120,000 * 0.2 = 24,000
      # 残存価額 = 1,000,000 * 0.1 = 100,000
      # 償却可能額 = 120,000 - 100,000 = 20,000（24,000より小さい）
      assert_equal 20_000, result[:depreciation_amount]
      assert_equal 100_000, result[:closing_book_value]
    end

    test "declining balance with different useful life years" do
      @policy.update!(method: "declining_balance", useful_life_years: 5)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # 償却率 = 1/5 * 2 = 0.4
      # 償却額 = 1,000,000 * 0.4 = 400,000
      assert_equal 400_000, result[:depreciation_amount]
      assert_equal 600_000, result[:closing_book_value]
    end

    # ==================== エッジケースと境界値テスト ====================

    test "handles zero opening value" do
      previous_year = create(:fiscal_year, year: 2024)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: previous_year,
        opening_book_value: 0,
        depreciation_amount: 0,
        closing_book_value: 0
      )

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 0, result[:opening_book_value]
      assert_equal 0, result[:depreciation_amount]
      assert_equal 0, result[:closing_book_value]
    end

    test "handles very small acquisition cost" do
      @fixed_asset.update!(acquisition_cost: 100)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # (100 * (1 - 0.1)) / 10 = 9
      assert_equal 9, result[:depreciation_amount]
    end

    test "handles very large acquisition cost" do
      @fixed_asset.update!(acquisition_cost: 1_000_000_000)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # (1,000,000,000 * (1 - 0.1)) / 10 = 90,000,000
      assert_equal 90_000_000, result[:depreciation_amount]
    end

    test "handles useful life of 1 year" do
      @policy.update!(useful_life_years: 1)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # (1,000,000 * (1 - 0.1)) / 1 = 900,000
      assert_equal 900_000, result[:depreciation_amount]
      assert_equal 100_000, result[:closing_book_value]
    end

    test "handles useful life of 20 years" do
      @policy.update!(useful_life_years: 20)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # (1,000,000 * (1 - 0.1)) / 20 = 45,000
      assert_equal 45_000, result[:depreciation_amount]
    end

    # ==================== 異常系テスト ====================

    test "returns error when policy not found" do
      @policy.destroy
      @fixed_asset.reload

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert_equal false, result[:success]
      assert_equal "Depreciation policy not found", result[:error]
    end

    test "handles unknown depreciation method" do
      @policy.update_column(:method, "unknown_method")

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      # 未知のメソッドの場合は償却額0
      assert_equal 0, result[:depreciation_amount]
      assert_equal 1_000_000, result[:closing_book_value]
    end

    test "handles nil fiscal year gracefully" do
      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: nil
      )

      # fiscal_yearがnilでも動作する（前年度検索がスキップされる）
      result = calculator.call

      assert result[:success]
      assert_equal 1_000_000, result[:opening_book_value]
    end

    # ==================== 保証率・改定償却率テーブルのテスト ====================

    test "uses guarantee rate from table for standard useful life" do
      @policy.update_column(:method, "declining_balance")

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      # 耐用年数10年の保証率は 0.11430
      guarantee_rate = calculator.send(:guarantee_rate)
      assert_equal 0.11430, guarantee_rate
    end

    test "calculates guarantee rate for non-standard useful life" do
      @policy.update!(method: "declining_balance", useful_life_years: 12)

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      # テーブルにない耐用年数は計算で求める
      guarantee_rate = calculator.send(:guarantee_rate)
      # 1/12 * 0.11430 ≒ 0.009525
      assert_in_delta 0.009525, guarantee_rate, 0.0001
    end

    test "uses revised rate from table for standard useful life" do
      @policy.update_column(:method, "declining_balance")

      calculator = DepreciationCalculator.new(
        fixed_asset: @fixed_asset,
        fiscal_year: @fiscal_year
      )

      # 耐用年数10年の改定償却率は 0.100
      revised_rate = calculator.send(:revised_depreciation_rate)
      assert_equal 0.100, revised_rate
    end
  end
end
