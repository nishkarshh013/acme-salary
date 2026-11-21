class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  normalizes :code, :currency_code, with: ->(value) { value.strip.upcase }

  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2}\z/ }
  validates :name, presence: true
  validates :currency_code, presence: true, format: { with: /\A[A-Z]{3}\z/ }
end
