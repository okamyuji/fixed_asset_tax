require "test_helper"

class TaxCalculationFlowTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Test Company", plan: "free")
    @municipality = Municipality.create!(code: "13101", name: "東京都千代田区")
    @fiscal_year = FiscalYear.create!(
      year: 2025,
      starts_on: Date.new(2025, 4, 1),
      ends_on: Date.new(2026, 3, 31)
    )
    @party = Individual.create!(
      tenant: @tenant,
      display_name: "田中太郎",
      birth_date: Date.new(1980, 1, 1)
    )
  end

  def test_complete_tax_calculation_flow
    # 1. 土地物件を作成
    property = Property.create!(
      tenant: @tenant,
      party: @party,
      municipality: @municipality,
      category: "land",
      name: "テスト土地"
    )

    # 2. 土地の詳細情報を追加
    land_parcel = LandParcel.create!(
      tenant: @tenant,
      property: property,
      parcel_no: "123-4",
      area_sqm: 150.0
    )

    # 3. 資産評価を作成
    valuation = AssetValuation.create!(
      tenant: @tenant,
      municipality: @municipality,
      fiscal_year: @fiscal_year,
      property: property,
      assessed_value: 15_000_000,
      tax_base_value: 15_000_000,
      source: "user"
    )

    # 4. 固定資産税を計算
    Current.tenant = @tenant
    result = Tax::PropertyTaxCalculator.new(
      tenant: @tenant,
      municipality: @municipality,
      fiscal_year: @fiscal_year
    ).call

    # 5. 計算結果を検証
    assert result[:success], "計算が成功すること"
    assert_equal "succeeded", result[:calculation_run].status
    assert_equal 1, result[:calculation_run].calculation_results.count

    calc_result = result[:calculation_run].calculation_results.first
    expected_tax = 15_000_000 * 0.014 # 210,000円
    assert_equal expected_tax, calc_result.tax_amount.to_f

    # 6. 計算結果の内訳を確認
    assert_not_nil calc_result.breakdown_json
    assert_equal 15_000_000.0, calc_result.breakdown_json["assessed_value"].to_f
    assert_equal 15_000_000.0, calc_result.breakdown_json["tax_base_value"].to_f

    Current.tenant = nil
  end

  def test_depreciation_calculation_flow
    # 1. 償却資産グループを作成
    property = Property.create!(
      tenant: @tenant,
      party: @party,
      municipality: @municipality,
      category: "depreciable_group",
      name: "機械設備グループ"
    )

    # 2. 固定資産を作成
    fixed_asset = FixedAsset.create!(
      tenant: @tenant,
      property: property,
      name: "製造機械",
      acquired_on: Date.new(2020, 1, 1),
      acquisition_cost: 10_000_000,
      asset_type: "machinery"
    )

    # 3. 減価償却ポリシーを作成
    policy = DepreciationPolicy.create!(
      tenant: @tenant,
      fixed_asset: fixed_asset,
      method: "straight_line",
      useful_life_years: 10,
      residual_rate: 0.1
    )

    # 4. 減価償却を計算
    result = Tax::DepreciationCalculator.new(
      fixed_asset: fixed_asset,
      fiscal_year: @fiscal_year
    ).call

    # 5. 計算結果を検証
    assert result[:success], "減価償却計算が成功すること"
    assert_equal 10_000_000, result[:opening_book_value]
    # (10,000,000 * (1 - 0.1)) / 10 = 900,000
    assert_equal 900_000, result[:depreciation_amount]
    assert_equal 9_100_000, result[:closing_book_value]

    # 6. 減価償却結果を保存
    depreciation_year = DepreciationYear.create!(
      tenant: @tenant,
      fixed_asset: fixed_asset,
      fiscal_year: @fiscal_year,
      opening_book_value: result[:opening_book_value],
      depreciation_amount: result[:depreciation_amount],
      closing_book_value: result[:closing_book_value]
    )

    assert depreciation_year.persisted?
    assert_equal 9_100_000, depreciation_year.closing_book_value.to_f
  end
end
