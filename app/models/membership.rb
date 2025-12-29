class Membership < ApplicationRecord
  belongs_to :tenant
  belongs_to :user

  validates :role, presence: true, inclusion: { in: %w[admin member viewer] }
  validates :user_id, uniqueness: { scope: :tenant_id }
end
