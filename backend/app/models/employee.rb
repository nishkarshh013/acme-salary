class Employee < ApplicationRecord
  # Optimistic locking is enabled automatically by the lock_version column.

  belongs_to :country
  belongs_to :department
  belongs_to :job_title

  # Employees are made inactive, never deleted, so their history is kept.
  has_many :salary_revisions, dependent: :restrict_with_error
  has_many :employee_assignments, dependent: :restrict_with_error

  enum :status, { active: "active", inactive: "inactive" }, default: :active, validate: true

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :salary_currency, with: ->(value) { value.strip.upcase }

  validates :employee_code, presence: true, uniqueness: true
  validates :first_name, :last_name, :hire_date, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :current_salary, presence: true, numericality: { greater_than: 0 }
  validates :salary_currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validate :salary_currency_matches_country

  private

  # Salaries are held in the local currency of the employee's country.
  def salary_currency_matches_country
    return if country.nil? || salary_currency.blank?
    return if salary_currency == country.currency_code

    errors.add(:salary_currency, "must match the country's currency (#{country.currency_code})")
  end
end
