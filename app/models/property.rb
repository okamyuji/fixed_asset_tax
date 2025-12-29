class Property < ApplicationRecord
  include TenantScoped

  belongs_to :party
  belongs_to :municipality

  has_many :land_parcels, dependent: :destroy
  has_many :fixed_assets, dependent: :destroy
  has_many :asset_valuations, dependent: :destroy
  has_many :calculation_results, dependent: :destroy

  validates :category, presence: true, inclusion: { in: %w[land building depreciable_group] }
  validates :name, presence: true
end
