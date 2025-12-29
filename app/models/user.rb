class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :tenants, through: :memberships

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end
