class AssetValuation < ApplicationRecord
  include TenantScoped

  belongs_to :municipality
  belongs_to :fiscal_year
  belongs_to :property

  validates :source, presence: true
  validates :property_id, uniqueness: { scope: [ :tenant_id, :municipality_id, :fiscal_year_id ] }
  validates :assessed_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :tax_base_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
