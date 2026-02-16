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
      @fiscal_year = create(:fiscal_year, year: 2025)
    end

    private

    def create_policy_with_method(method, useful_life: 10)
      policy = create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        useful_life_years: useful_life,
        residual_rate: 0.0
      )
      policy.update_column(:method, method)
      policy
    end

    def create_previous_year(year:, opening:, depreciation:, closing:)
      fy = FiscalYear.find_by(year: year) || create(:fiscal_year, year: year)
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: @fixed_asset,
        fiscal_year: fy,
        opening_book_value: opening,
        depreciation_amount: depreciation,
        closing_book_value: closing
      )
    end

    def calculate
      DepreciationCalculator.new(fixed_asset: @fixed_asset.reload, fiscal_year: @fiscal_year).call
    end

    public

    # ==================== 旧定額法 ====================

    test "old_straight_line: first year calculates correctly" do
      create_policy_with_method("old_straight_line")
      result = calculate
      assert result[:success]
      assert_equal 1_000_000, result[:opening_book_value]
      # base = 1,000,000 * 0.9 = 900,000
      # rate = 0.100, annual = 90,000
      assert_equal 90_000, result[:depreciation_amount]
      assert_equal 910_000, result[:closing_book_value]
    end

    test "old_straight_line: clamped at 5% threshold" do
      create_policy_with_method("old_straight_line")
      # opening=60,000 > threshold=50,000
      # annual = 90,000, but clamped to 60,000-50,000 = 10,000
      create_previous_year(year: 2024, opening: 140_000, depreciation: 80_000, closing: 60_000)
      result = calculate
      assert result[:success]
      assert_equal 60_000, result[:opening_book_value]
      assert_equal 10_000, result[:depreciation_amount]
      assert_equal 50_000, result[:closing_book_value]
    end

    test "old_straight_line: kintoushoukyaku phase" do
      create_policy_with_method("old_straight_line")
      # opening=50,000 = threshold, so enters kintoushoukyaku
      create_previous_year(year: 2024, opening: 60_000, depreciation: 10_000, closing: 50_000)
      result = calculate
      assert result[:success]
      assert_equal 50_000, result[:opening_book_value]
      # kintoushoukyaku: (50,000 - 1) / 5 = 9,999.8
      assert_in_delta 9_999.8, result[:depreciation_amount], 0.01
      assert_in_delta 40_000.2, result[:closing_book_value], 0.01
    end

    test "old_straight_line: last kintoushoukyaku year reaches 1 yen" do
      create_policy_with_method("old_straight_line")
      # opening = 9,999.8 (in last year of kintoushoukyaku)
      create_previous_year(year: 2024, opening: 19_999.6, depreciation: 9_999.8, closing: 9_999.8)
      result = calculate
      assert result[:success]
      assert_in_delta 9_999.8, result[:opening_book_value], 0.01
      # kintoushoukyaku = 9,999.8, but opening - 1 = 9,998.8, clamped
      assert_in_delta 9_998.8, result[:depreciation_amount], 0.01
      assert_equal 1, result[:closing_book_value]
    end

    # ==================== 旧定率法 ====================

    test "old_declining_balance: first year" do
      create_policy_with_method("old_declining_balance")
      result = calculate
      assert result[:success]
      # rate = 0.206
      # annual = 1,000,000 * 0.206 = 206,000
      assert_equal 206_000, result[:depreciation_amount]
      assert_equal 794_000, result[:closing_book_value]
    end

    test "old_declining_balance: second year" do
      create_policy_with_method("old_declining_balance")
      create_previous_year(year: 2024, opening: 1_000_000, depreciation: 206_000, closing: 794_000)
      result = calculate
      assert result[:success]
      assert_equal 794_000, result[:opening_book_value]
      # annual = 794,000 * 0.206 = 163,564
      assert_in_delta 163_564, result[:depreciation_amount], 1
    end

    test "old_declining_balance: clamped at 5% threshold" do
      create_policy_with_method("old_declining_balance")
      # opening = 55,000, threshold = 50,000
      # annual = 55,000 * 0.206 = 11,330, but clamped to 55,000 - 50,000 = 5,000
      create_previous_year(year: 2024, opening: 100_000, depreciation: 45_000, closing: 55_000)
      result = calculate
      assert result[:success]
      assert_equal 55_000, result[:opening_book_value]
      assert_equal 5_000, result[:depreciation_amount]
      assert_equal 50_000, result[:closing_book_value]
    end

    test "old_declining_balance: kintoushoukyaku phase" do
      create_policy_with_method("old_declining_balance")
      create_previous_year(year: 2024, opening: 55_000, depreciation: 5_000, closing: 50_000)
      result = calculate
      assert result[:success]
      assert_in_delta 9_999.8, result[:depreciation_amount], 0.01
    end

    # ==================== 定額法 (新) ====================

    test "straight_line: first year" do
      create_policy_with_method("straight_line")
      result = calculate
      assert result[:success]
      # rate = 0.100, annual = 100,000
      assert_equal 100_000, result[:depreciation_amount]
      assert_equal 900_000, result[:closing_book_value]
    end

    test "straight_line: uses previous year closing value" do
      create_policy_with_method("straight_line")
      create_previous_year(year: 2024, opening: 1_000_000, depreciation: 100_000, closing: 900_000)
      result = calculate
      assert result[:success]
      assert_equal 900_000, result[:opening_book_value]
      assert_equal 100_000, result[:depreciation_amount]
      assert_equal 800_000, result[:closing_book_value]
    end

    test "straight_line: clamped to 1 yen minimum" do
      create_policy_with_method("straight_line")
      # opening = 50,000, annual = 100,000, clamped to 50,000 - 1 = 49,999
      create_previous_year(year: 2024, opening: 100_001, depreciation: 50_001, closing: 50_000)
      result = calculate
      assert result[:success]
      assert_equal 49_999, result[:depreciation_amount]
      assert_equal 1, result[:closing_book_value]
    end

    test "straight_line: already at 1 yen" do
      create_policy_with_method("straight_line")
      create_previous_year(year: 2024, opening: 49_999, depreciation: 49_998, closing: 1)
      result = calculate
      assert result[:success]
      assert_equal 1, result[:opening_book_value]
      assert_equal 0, result[:depreciation_amount]
      assert_equal 1, result[:closing_book_value]
    end

    test "straight_line: different useful life (5 years)" do
      create_policy_with_method("straight_line", useful_life: 5)
      result = calculate
      assert result[:success]
      # rate = 0.200, annual = 200,000
      assert_equal 200_000, result[:depreciation_amount]
    end

    # ==================== 250%定率法 ====================

    test "declining_balance_250: first year" do
      create_policy_with_method("declining_balance_250")
      result = calculate
      assert result[:success]
      # rate = 0.250, annual = 250,000
      assert_equal 250_000, result[:depreciation_amount]
      assert_equal 750_000, result[:closing_book_value]
    end

    test "declining_balance_250: switches to revised rate when below guarantee" do
      create_policy_with_method("declining_balance_250")
      # For useful_life=10: rate=0.250, guarantee_rate=0.04448, revised_rate=0.334
      # guarantee_amount = 1,000,000 * 0.04448 = 44,480
      # Need opening where opening * 0.250 < 44,480 -> opening < 177,920
      # Previous year: opening=200,000 * 0.250 = 50,000 >= 44,480 (still normal)
      # Current year: opening=150,000 * 0.250 = 37,500 < 44,480 (switches)
      create_previous_year(year: 2024, opening: 200_000, depreciation: 50_000, closing: 150_000)
      result = calculate
      assert result[:success]
      assert_equal 150_000, result[:opening_book_value]
      # revised_acquisition = 150,000 (first year below guarantee)
      # revised_depreciation = 150,000 * 0.334 = 50,100
      assert_in_delta 50_100, result[:depreciation_amount], 1
    end

    # ==================== 200%定率法 ====================

    test "declining_balance_200: first year" do
      create_policy_with_method("declining_balance_200")
      result = calculate
      assert result[:success]
      # rate = 0.200
      assert_equal 200_000, result[:depreciation_amount]
      assert_equal 800_000, result[:closing_book_value]
    end

    test "declining_balance_200: second year" do
      create_policy_with_method("declining_balance_200")
      create_previous_year(year: 2024, opening: 1_000_000, depreciation: 200_000, closing: 800_000)
      result = calculate
      assert result[:success]
      assert_equal 800_000, result[:opening_book_value]
      # annual = 800,000 * 0.200 = 160,000
      assert_equal 160_000, result[:depreciation_amount]
    end

    test "declining_balance_200: switches to revised rate" do
      create_policy_with_method("declining_balance_200")
      # guarantee_rate = 0.06552, guarantee_amount = 65,520
      # Need opening where opening * 0.200 < 65,520 -> opening < 327,600
      # Previous: 350,000 * 0.200 = 70,000 >= 65,520 (normal)
      # Current: 280,000 * 0.200 = 56,000 < 65,520 (switches)
      create_previous_year(year: 2024, opening: 350_000, depreciation: 70_000, closing: 280_000)
      result = calculate
      assert result[:success]
      assert_equal 280_000, result[:opening_book_value]
      # revised_acquisition = 280,000
      # revised_depreciation = 280,000 * 0.250 = 70,000
      assert_equal 70_000, result[:depreciation_amount]
    end

    test "declining_balance_200: different useful life (5 years)" do
      create_policy_with_method("declining_balance_200", useful_life: 5)
      result = calculate
      assert result[:success]
      # rate = 0.400
      assert_equal 400_000, result[:depreciation_amount]
    end

    test "declining_balance_200: useful life 2 (no guarantee)" do
      create_policy_with_method("declining_balance_200", useful_life: 2)
      result = calculate
      assert result[:success]
      # rate = 1.000
      # annual = 1,000,000, clamped to 1,000,000 - 1 = 999,999
      assert_equal 999_999, result[:depreciation_amount]
      assert_equal 1, result[:closing_book_value]
    end

    # ==================== 特殊償却タイプ ====================

    test "immediate depreciation" do
      policy = create_policy_with_method("straight_line")
      policy.update_column(:depreciation_type, "immediate")
      result = calculate
      assert result[:success]
      assert_equal 1_000_000, result[:depreciation_amount]
      assert_equal 0, result[:closing_book_value]
    end

    test "lump sum depreciation" do
      policy = create_policy_with_method("straight_line")
      policy.update_column(:depreciation_type, "lump_sum")
      result = calculate
      assert result[:success]
      assert_in_delta 333_333.33, result[:depreciation_amount], 1
    end

    test "small value depreciation" do
      policy = create_policy_with_method("straight_line")
      policy.update_column(:depreciation_type, "small_value")
      result = calculate
      assert result[:success]
      assert_equal 1_000_000, result[:depreciation_amount]
      assert_equal 0, result[:closing_book_value]
    end

    # ==================== エッジケース ====================

    test "returns error when policy not found" do
      @fixed_asset.depreciation_policy&.destroy
      result = calculate
      assert_equal false, result[:success]
      assert_equal "Depreciation policy not found", result[:error]
    end

    test "unknown depreciation method returns 0" do
      create_policy_with_method("straight_line")
      @fixed_asset.depreciation_policy.update_column(:method, "unknown_method")
      result = calculate
      assert result[:success]
      assert_equal 0, result[:depreciation_amount]
      assert_equal 1_000_000, result[:closing_book_value]
    end

    test "handles nil fiscal year" do
      create_policy_with_method("straight_line")
      result = DepreciationCalculator.new(fixed_asset: @fixed_asset.reload, fiscal_year: nil).call
      assert result[:success]
      assert_equal 1_000_000, result[:opening_book_value]
    end

    test "handles rate not found for unusual useful life" do
      create_policy_with_method("straight_line", useful_life: 99)
      result = calculate
      assert result[:success]
      assert_equal 0, result[:depreciation_amount]
    end
  end
end
