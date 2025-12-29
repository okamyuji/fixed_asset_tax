class CalculationRun < ApplicationRecord
  include TenantScoped

  belongs_to :municipality
  belongs_to :fiscal_year
  has_many :calculation_results, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[queued running succeeded failed] }

  scope :succeeded, -> { where(status: "succeeded") }
  scope :failed, -> { where(status: "failed") }
end
