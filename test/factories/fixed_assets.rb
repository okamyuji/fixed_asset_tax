FactoryBot.define do
  factory :fixed_asset do
    tenant
    property
    name { "テスト機械" }
    acquired_on { Date.new(2020, 1, 1) }
    acquisition_cost { 1_000_000 }
    asset_type { "machinery" }
  end
end
