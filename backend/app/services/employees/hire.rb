module Employees
  # Creates an employee together with their first assignment and first salary
  # revision, all dated on the hire date. Nothing is saved unless all three are.
  class Hire
    DUPLICATE_MESSAGE = "An employee with this email or employee code already exists".freeze

    def self.call(...) = new(...).call

    def initialize(attributes:, salary:, reason: "Hired")
      @attributes = attributes
      @salary = salary
      @reason = reason
    end

    def call
      employee = build_employee
      errors = pre_save_violations(employee)
      return ServiceResult.failure(errors, record: employee) if errors.any?

      ApplicationRecord.transaction do
        employee.save!
        create_first_assignment!(employee)
        create_first_revision!(employee)
      end

      ServiceResult.success(employee)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.record.errors.full_messages, record: employee)
    rescue ActiveRecord::RecordNotUnique
      # Uniqueness validations passed, but a concurrent hire inserted the same
      # email or employee code first; the unique index caught it.
      ServiceResult.failure(DUPLICATE_MESSAGE, record: employee)
    end

    private

    attr_reader :attributes, :salary, :reason

    def pre_save_violations(employee)
      errors = []
      errors << "Hire date can't be in the future" if employee.hire_date&.future?
      errors << "Amount can have at most 2 decimal places" if too_many_decimal_places?
      errors
    end

    # Checked on the raw salary: assigning it to the decimal(15,2) column
    # would already have rounded it. Blank or unparseable salaries are left
    # to the Employee validations.
    def too_many_decimal_places?
      return false if salary.blank?

      decimal = BigDecimal(salary.to_s, exception: false)
      decimal&.finite? && decimal.round(2) != decimal
    end

    def build_employee
      Employee.new(attributes).tap do |employee|
        # Salary always comes from the salary argument, in the country's currency.
        employee.current_salary = salary
        employee.salary_currency = employee.country&.currency_code
      end
    end

    def create_first_assignment!(employee)
      employee.employee_assignments.create!(
        country: employee.country,
        department: employee.department,
        job_title: employee.job_title,
        effective_date: employee.hire_date,
        reason: reason
      )
    end

    def create_first_revision!(employee)
      employee.salary_revisions.create!(
        amount: employee.current_salary,
        currency: employee.salary_currency,
        previous_amount: nil,
        effective_date: employee.hire_date,
        reason: reason
      )
    end
  end
end
