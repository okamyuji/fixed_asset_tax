class CalculationResult < ApplicationRecord
  include TenantScoped

  belongs_to :calculation_run
  belongs_to :property

  validates :tax_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
