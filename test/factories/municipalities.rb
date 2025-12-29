FactoryBot.define do
  factory :municipality do
    sequence(:code) { |n| "#{13000 + n}" }
    name { "東京都" }
  end
end
