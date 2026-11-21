module Employees
  # Edits an employee's own details: name, email and status. Everything else
  # has its own path, so asking to change it here is rejected with a message
  # saying where to go instead, rather than silently ignored.
  class Update
    include OptimisticLocking

    EDITABLE = %w[ first_name last_name email status ].freeze
    LOCKED = {
      "salary" => "Salary can't be changed here; record a salary revision instead",
      "current_salary" => "Salary can't be changed here; record a salary revision instead",
      "salary_currency" => "Salary currency can't be changed here; it follows the employee's country",
      "country_id" => "Country can't be changed here; record an assignment change instead",
      "department_id" => "Department can't be changed here; record an assignment change instead",
      "job_title_id" => "Job title can't be changed here; record an assignment change instead",
      "hire_date" => "Hire date can't be changed",
      "employee_code" => "Employee code can't be changed"
    }.freeze
    DUPLICATE_EMAIL_MESSAGE = "An employee with this email already exists".freeze

    def self.call(...) = new(...).call

    # attributes may contain any of EDITABLE and LOCKED keys.
    def initialize(employee:, attributes:, lock_version:)
      @employee = employee
      @attributes = attributes.to_h.stringify_keys
      @lock_version = lock_version
    end

    def call
      return stale_failure if stale?(employee, lock_version)

      errors = LOCKED.slice(*attributes.keys).values.uniq
      return ServiceResult.failure(errors) if errors.any?

      employee.update!(attributes.slice(*EDITABLE))
      ServiceResult.success(employee)
    rescue ActiveRecord::StaleObjectError
      employee.reload
      stale_failure
    rescue ActiveRecord::RecordInvalid => e
      employee.reload
      ServiceResult.failure(e.record.errors.full_messages)
    rescue ActiveRecord::RecordNotUnique
      employee.reload
      ServiceResult.failure(DUPLICATE_EMAIL_MESSAGE)
    end

    private

    attr_reader :employee, :attributes, :lock_version
  end
end
