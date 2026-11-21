class Department < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error
  has_many :employee_assignments, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
