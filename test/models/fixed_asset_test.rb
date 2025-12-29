require "test_helper"

class FixedAssetTest < ActiveSupport::TestCase
  test "valid fixed asset" do
    tenant = create(:tenant)
    property = create(:property, tenant: tenant)
    fixed_asset = build(:fixed_asset, tenant: tenant, property: property)
    assert fixed_asset.valid?
  end

  test "requires name" do
    fixed_asset = build(:fixed_asset, name: nil)
    assert_not fixed_asset.valid?
    assert_includes fixed_asset.errors[:name], "can't be blank"
  end

  test "requires acquired_on" do
    fixed_asset = build(:fixed_asset, acquired_on: nil)
    assert_not fixed_asset.valid?
    assert_includes fixed_asset.errors[:acquired_on], "can't be blank"
  end

  test "requires acquisition_cost" do
    fixed_asset = build(:fixed_asset, acquisition_cost: nil)
    assert_not fixed_asset.valid?
    assert_includes fixed_asset.errors[:acquisition_cost], "can't be blank"
  end

  test "validates acquisition_cost is positive" do
    fixed_asset = build(:fixed_asset, acquisition_cost: 0)
    assert_not fixed_asset.valid?
    assert_includes fixed_asset.errors[:acquisition_cost], "must be greater than 0"
  end
end
