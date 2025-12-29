FactoryBot.define do
  factory :land_parcel do
    tenant
    property
    parcel_no { "123-4" }
    area_sqm { 100.0 }
  end
end
