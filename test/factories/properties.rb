FactoryBot.define do
  factory :property do
    tenant
    party
    municipality
    category { "land" }
    name { "テスト土地" }

    factory :land_property do
      category { "land" }
      name { "土地物件" }
    end

    factory :building_property do
      category { "building" }
      name { "建物物件" }
    end

    factory :depreciable_property do
      category { "depreciable_group" }
      name { "償却資産グループ" }
    end
  end
end
