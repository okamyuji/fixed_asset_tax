class DepreciationPolicy < ApplicationRecord
  include TenantScoped

  belongs_to :fixed_asset

  validates :method, presence: true, inclusion: { in: %w[straight_line declining_balance] }
  validates :useful_life_years, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :residual_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :fixed_asset_id, uniqueness: { scope: :tenant_id }
end
