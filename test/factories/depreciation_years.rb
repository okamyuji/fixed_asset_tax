FactoryBot.define do
  factory :depreciation_year do
    tenant
    fixed_asset
    fiscal_year
    opening_book_value { 1_000_000 }
    depreciation_amount { 100_000 }
    closing_book_value { 900_000 }
  end
end
