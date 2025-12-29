class Party < ApplicationRecord
  include TenantScoped

  has_many :properties, dependent: :destroy

  validates :type, presence: true, inclusion: { in: %w[Individual Corporation] }
  validates :display_name, presence: true
  validates :corporate_number, uniqueness: { scope: :tenant_id }, allow_nil: true
end
