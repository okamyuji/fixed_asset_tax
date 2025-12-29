class DepreciationYear < ApplicationRecord
  include TenantScoped

  belongs_to :fixed_asset
  belongs_to :fiscal_year

  validates :opening_book_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :depreciation_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :closing_book_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fixed_asset_id, uniqueness: { scope: [ :tenant_id, :fiscal_year_id ] }
end
