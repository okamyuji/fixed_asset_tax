FactoryBot.define do
  factory :depreciation_policy do
    tenant
    fixed_asset
    useful_life_years { 10 }
    residual_rate { 0.1 }

    # methodカラムを直接設定（Rubyのmethodメソッドと衝突するため）
    after(:build) do |policy|
      policy.write_attribute(:method, "straight_line")
    end
  end
end
