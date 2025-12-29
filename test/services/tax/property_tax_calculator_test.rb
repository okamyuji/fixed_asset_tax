require "test_helper"

module Tax
  class PropertyTaxCalculatorTest < ActiveSupport::TestCase
    setup do
      @tenant = create(:tenant)
      @municipality = create(:municipality)
      @fiscal_year = create(:fiscal_year, year: 2025)
      @party = create(:party, tenant: @tenant)
    end

    test "calculates tax for land property" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      create(:land_parcel,
        tenant: @tenant,
        property: property,
        area_sqm: 100
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal "succeeded", result[:calculation_run].status
      assert_equal 1, result[:calculation_run].calculation_results.count

      calc_result = result[:calculation_run].calculation_results.first
      # 100㎡ × 100,000円/㎡ × 1.4% = 140,000円
      assert_equal 140_000, calc_result.tax_amount
    end

    test "calculates tax for depreciable property" do
      property = create(:depreciable_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 1_000_000
      )
      create(:depreciation_year,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        fiscal_year: @fiscal_year,
        opening_book_value: 1_000_000,
        depreciation_amount: 100_000,
        closing_book_value: 900_000
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first
      # 900,000円 × 1.4% = 12,600円
      assert_equal 12_600, calc_result.tax_amount
    end

    test "creates calculation run with correct status" do
      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_instance_of CalculationRun, result[:calculation_run]
      assert_equal "succeeded", result[:calculation_run].status
      assert_equal @tenant, result[:calculation_run].tenant
      assert_equal @municipality, result[:calculation_run].municipality
      assert_equal @fiscal_year, result[:calculation_run].fiscal_year
    end

    test "handles multiple properties" do
      property1 = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      create(:land_parcel, tenant: @tenant, property: property1, area_sqm: 100)

      property2 = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      create(:land_parcel, tenant: @tenant, property: property2, area_sqm: 200)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      assert_equal 2, result[:calculation_run].calculation_results.count
    end

    # ==================== 住宅用地の課税標準の特例テスト ====================

    test "applies small-scale residential land exemption (200㎡ or less)" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality,
        property_type: "residential"
      )
      create(:land_parcel, tenant: @tenant, property: property, area_sqm: 150)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 評価額: 150㎡ × 100,000円 = 15,000,000円
      # 小規模住宅用地: 15,000,000 / 6 = 2,500,000円（課税標準額）
      # 税額: 2,500,000 × 1.4% = 35,000円
      assert_equal 15_000_000, calc_result.breakdown_json["assessed_value"]
      assert_equal 2_500_000, calc_result.breakdown_json["tax_base_value"]
      assert_equal 35_000, calc_result.tax_amount
    end

    test "applies mixed residential land exemption (over 200㎡)" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality,
        property_type: "residential"
      )
      create(:land_parcel, tenant: @tenant, property: property, area_sqm: 300)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 評価額: 300㎡ × 100,000円 = 30,000,000円
      # 小規模部分（200㎡）: 30,000,000 × (200/300) / 6 = 3,333,333.33円
      # 一般部分（100㎡）: 30,000,000 × (100/300) / 3 = 3,333,333.33円
      # 課税標準額: 3,333,333.33 + 3,333,333.33 = 6,666,666.66円
      # 税額: 6,666,666.66 × 1.4% ≒ 93,333円
      assert_equal 30_000_000, calc_result.breakdown_json["assessed_value"]
      assert_in_delta 6_666_667, calc_result.breakdown_json["tax_base_value"], 1
      assert_in_delta 93_333, calc_result.tax_amount, 1
    end

    test "does not apply residential exemption to non-residential land" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality,
        property_type: "commercial"
      )
      create(:land_parcel, tenant: @tenant, property: property, area_sqm: 150)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 商業用地は特例なし
      # 評価額: 15,000,000円 = 課税標準額
      # 税額: 15,000,000 × 1.4% = 210,000円
      assert_equal 15_000_000, calc_result.breakdown_json["assessed_value"]
      assert_equal 15_000_000, calc_result.breakdown_json["tax_base_value"]
      assert_equal 210_000, calc_result.tax_amount
    end

    # ==================== 新築住宅の減額特例テスト ====================

    test "applies new construction reduction within 3 years" do
      property = create(:building_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 10_000_000,
        acquired_on: Date.new(2023, 1, 1) # 2年前
      )
      create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        method: "straight_line",
        useful_life_years: 20,
        residual_rate: 0.1
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 新築後3年以内なので、課税標準額が1/2
      # 評価額 > 課税標準額 × 2
      assert calc_result.breakdown_json["assessed_value"] > calc_result.breakdown_json["tax_base_value"]
    end

    test "does not apply new construction reduction after 3 years" do
      property = create(:building_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 10_000_000,
        acquired_on: Date.new(2020, 1, 1) # 5年前
      )
      create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        method: "straight_line",
        useful_life_years: 20,
        residual_rate: 0.1
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 新築後3年超なので、減額なし
      # 評価額 = 課税標準額
      assert_equal calc_result.breakdown_json["assessed_value"],
                   calc_result.breakdown_json["tax_base_value"]
    end

    # ==================== 免税点判定テスト ====================

    test "applies exemption for land below threshold" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      # 評価額: 2㎡ × 100,000円 = 200,000円（免税点300,000円未満）
      create(:land_parcel, tenant: @tenant, property: property, area_sqm: 2)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 免税点未満なので税額0
      assert_equal 0, calc_result.tax_amount
      assert_equal "Below exemption threshold", calc_result.breakdown_json["exempt_reason"]
    end

    test "applies exemption for building below threshold" do
      property = create(:building_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 150_000, # 免税点200,000円未満
        acquired_on: Date.new(2020, 1, 1)
      )
      create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        method: "straight_line",
        useful_life_years: 10,
        residual_rate: 0.1
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 免税点未満なので税額0
      assert_equal 0, calc_result.tax_amount
      assert_equal "Below exemption threshold", calc_result.breakdown_json["exempt_reason"]
    end

    test "applies exemption for depreciable assets below threshold" do
      property = create(:depreciable_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 1_000_000, # 免税点1,500,000円未満
        acquired_on: Date.new(2020, 1, 1)
      )
      create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        method: "straight_line",
        useful_life_years: 10,
        residual_rate: 0.0
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 免税点未満なので税額0
      assert_equal 0, calc_result.tax_amount
      assert_equal "Below exemption threshold", calc_result.breakdown_json["exempt_reason"]
    end

    test "does not apply exemption above threshold" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      # 評価額: 5㎡ × 100,000円 = 500,000円（免税点300,000円以上）
      create(:land_parcel, tenant: @tenant, property: property, area_sqm: 5)

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 免税点以上なので課税
      assert calc_result.tax_amount > 0
      assert_nil calc_result.breakdown_json["exempt_reason"]
    end

    # ==================== 固定資産税評価上の減価計算テスト ====================

    test "uses fixed asset tax valuation for depreciable assets" do
      property = create(:depreciable_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      fixed_asset = create(:fixed_asset,
        tenant: @tenant,
        property: property,
        acquisition_cost: 10_000_000,
        acquired_on: Date.new(2025, 1, 1) # 初年度
      )
      create(:depreciation_policy,
        tenant: @tenant,
        fixed_asset: fixed_asset,
        method: "straight_line",
        useful_life_years: 10,
        residual_rate: 0.0
      )

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 固定資産税評価: 10,000,000 × (1 - 0.206 × 0.5) = 8,970,000
      # 税額: 8,970,000 × 1.4% = 125,580
      assert_in_delta 8_970_000, calc_result.breakdown_json["assessed_value"], 1000
      assert_in_delta 125_580, calc_result.tax_amount, 1000
    end

    # ==================== エッジケースと異常系テスト ====================

    test "handles property without land parcel gracefully" do
      property = create(:land_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      # land_parcelを作成しない

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 評価額0なので税額0
      assert_equal 0, calc_result.tax_amount
    end

    test "handles property without fixed asset gracefully" do
      property = create(:building_property,
        tenant: @tenant,
        party: @party,
        municipality: @municipality
      )
      # fixed_assetを作成しない

      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: @municipality,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert result[:success]
      calc_result = result[:calculation_run].calculation_results.first

      # 評価額0なので税額0
      assert_equal 0, calc_result.tax_amount
    end

    test "marks calculation as failed on error" do
      # エラーを発生させるために、municipality_idをnilにする
      calculator = PropertyTaxCalculator.new(
        tenant: @tenant,
        municipality: nil,
        fiscal_year: @fiscal_year
      )

      result = calculator.call

      assert_equal false, result[:success]
      assert_not_nil result[:error]
    end
  end
end
