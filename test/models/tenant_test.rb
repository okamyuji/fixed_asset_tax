require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "valid tenant" do
    tenant = build(:tenant)
    assert tenant.valid?
  end

  test "requires name" do
    tenant = build(:tenant, name: nil)
    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"
  end

  test "requires plan" do
    tenant = build(:tenant, plan: nil)
    assert_not tenant.valid?
    assert_includes tenant.errors[:plan], "can't be blank"
  end
end
