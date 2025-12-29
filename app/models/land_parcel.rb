class LandParcel < ApplicationRecord
  include TenantScoped

  belongs_to :property

  validates :area_sqm, numericality: { greater_than: 0 }, allow_nil: true
end
