require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  test "valid property" do
    tenant = create(:tenant)
    party = create(:party, tenant: tenant)
    municipality = create(:municipality)
    property = build(:property, tenant: tenant, party: party, municipality: municipality)
    assert property.valid?
  end

  test "requires tenant" do
    property = build(:property, tenant: nil)
    assert_not property.valid?
    assert_includes property.errors[:tenant_id], "can't be blank"
  end

  test "requires category" do
    property = build(:property, category: nil)
    assert_not property.valid?
    assert_includes property.errors[:category], "can't be blank"
  end

  test "validates category inclusion" do
    property = build(:property, category: "invalid")
    assert_not property.valid?
    assert_includes property.errors[:category], "is not included in the list"
  end

  test "requires name" do
    property = build(:property, name: nil)
    assert_not property.valid?
    assert_includes property.errors[:name], "can't be blank"
  end

  test "sets tenant from current on create" do
    tenant = create(:tenant)
    Current.tenant = tenant

    property = Property.new(
      party: create(:party, tenant: tenant),
      municipality: create(:municipality),
      category: "land",
      name: "Test"
    )

    assert property.save
    assert_equal tenant, property.tenant

    Current.tenant = nil
  end
end
