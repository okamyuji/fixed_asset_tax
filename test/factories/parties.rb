FactoryBot.define do
  factory :party do
    tenant
    type { "Individual" }
    display_name { "田中太郎" }
    birth_date { Date.new(1980, 1, 1) }

    factory :individual, class: "Individual" do
      type { "Individual" }
    end

    factory :corporation, class: "Corporation" do
      type { "Corporation" }
      display_name { "株式会社テスト" }
      sequence(:corporate_number) { |n| "#{1234567890123 + n}" }
      birth_date { nil }
    end
  end
end
