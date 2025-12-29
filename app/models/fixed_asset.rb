class FixedAsset < ApplicationRecord
  include TenantScoped

  belongs_to :property
  has_one :depreciation_policy, dependent: :destroy
  has_many :depreciation_years, dependent: :destroy

  validates :name, presence: true
  validates :acquired_on, presence: true
  validates :acquisition_cost, presence: true, numericality: { greater_than: 0 }
  validates :asset_type, presence: true
end
