FactoryBot.define do
  factory :fiscal_year do
    sequence(:year) { |n| 2020 + n }
    starts_on { Date.new(year, 4, 1) }
    ends_on { Date.new(year + 1, 3, 31) }
  end
end
