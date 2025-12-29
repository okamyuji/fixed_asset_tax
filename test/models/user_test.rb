require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires valid email format" do
    user = build(:user, email: "invalid")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "requires password on create" do
    user = User.new(email: "test@example.com", name: "Test")
    assert_not user.valid?
  end

  test "authenticates with correct password" do
    user = create(:user, password: "password123")
    assert user.authenticate("password123")
  end

  test "does not authenticate with incorrect password" do
    user = create(:user, password: "password123")
    assert_not user.authenticate("wrong")
  end
end
