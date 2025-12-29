class Municipality < ApplicationRecord
  has_many :properties, dependent: :restrict_with_error
  has_many :asset_valuations, dependent: :restrict_with_error
  has_many :calculation_runs, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
