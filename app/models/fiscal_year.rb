class FiscalYear < ApplicationRecord
  has_many :asset_valuations, dependent: :restrict_with_error
  has_many :depreciation_years, dependent: :restrict_with_error
  has_many :calculation_runs, dependent: :restrict_with_error

  validates :year, presence: true, uniqueness: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validate :ends_on_after_starts_on

  private

  def ends_on_after_starts_on
    return if ends_on.blank? || starts_on.blank?

    if ends_on <= starts_on
      errors.add(:ends_on, "must be after starts_on")
    end
  end
end
