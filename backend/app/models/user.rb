# The HR Manager. There is a single user and no self-service, so there is no
# sign-up or password reset; the account is seeded from HR_EMAIL/HR_PASSWORD.
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
