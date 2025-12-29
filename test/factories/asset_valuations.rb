FactoryBot.define do
  factory :asset_valuation do
    tenant
    municipality
    fiscal_year
    property
    source { "calculated" }
    assessed_value { 1_000_000 }
    tax_base_value { 1_000_000 }
  end
end
