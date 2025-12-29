class Tenant < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :parties, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :land_parcels, dependent: :destroy
  has_many :fixed_assets, dependent: :destroy
  has_many :depreciation_policies, dependent: :destroy
  has_many :asset_valuations, dependent: :destroy
  has_many :depreciation_years, dependent: :destroy
  has_many :calculation_runs, dependent: :destroy
  has_many :calculation_results, dependent: :destroy

  validates :name, presence: true
  validates :plan, presence: true
end
