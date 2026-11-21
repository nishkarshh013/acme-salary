module Employees
  # Creates an employee together with their first assignment and first salary
  # revision, all dated on the hire date. Nothing is saved unless all three are.
  #
  # The employee code is assigned here, never taken from the caller: the next
  # number after the highest in use (EMP10001 after EMP10000). If a concurrent
  # hire takes that code first, the whole hire is retried with the next
  # number, up to CODE_ATTEMPTS times.
  class Hire
    CODE_ATTEMPTS = 3
    DUPLICATE_EMAIL_MESSAGE = "An employee with this email already exists".freeze
    CODE_EXHAUSTED_MESSAGE = "Couldn't assign an employee code because of other hires at the same time. " \
                             "Please try again.".freeze

    def self.call(...) = new(...).call

    def initialize(attributes:, salary:, reason: "Hired")
      @attributes = attributes.to_h.with_indifferent_access.except(:employee_code)
      @salary = Salaries::Amount.new(salary, label: "Salary")
      @reason = reason
    end

    def call
      employee = build_employee
      errors = pre_save_violations(employee)
      return ServiceResult.failure(errors, record: employee) if errors.any?

      save_with_new_code(employee)
    end

    private

    attr_reader :attributes, :salary, :reason

    def save_with_new_code(employee)
      last_tried = 0
      CODE_ATTEMPTS.times do
        last_tried = [ Employee.highest_code_number, last_tried ].max + 1
        employee.employee_code = Employee.code_for(last_tried)
        begin
          save_all!(employee)
          return ServiceResult.success(employee)
        rescue ActiveRecord::RecordInvalid => e
          raise unless code_taken?(e)
        rescue ActiveRecord::RecordNotUnique => e
          raise unless e.message.include?("index_employees_on_employee_code")
        end
      end
      ServiceResult.failure(CODE_EXHAUSTED_MESSAGE, record: employee)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.record.errors.full_messages, record: employee)
    rescue ActiveRecord::RecordNotUnique
      # The email validation passed, but a concurrent hire inserted the same
      # email first; the unique index caught it.
      ServiceResult.failure(DUPLICATE_EMAIL_MESSAGE, record: employee)
    end

    def save_all!(employee)
      ApplicationRecord.transaction do
        employee.save!
        create_first_assignment!(employee)
        create_first_revision!(employee)
      end
    end

    # A concurrent hire committed the code after it was chosen; the
    # uniqueness validation (rather than the index) noticed.
    def code_taken?(error)
      error.record.is_a?(Employee) && error.record.errors.of_kind?(:employee_code, :taken)
    end

    def pre_save_violations(employee)
      errors = []
      errors << "Hire date can't be in the future" if employee.hire_date && employee.hire_date > Date.current
      # Checked on the raw salary: assigning it to the decimal(15,2) column
      # would already have rounded it.
      errors.concat(salary.errors)
    end

    def build_employee
      Employee.new(attributes).tap do |employee|
        # Salary always comes from the salary argument, in the country's currency.
        employee.current_salary = salary.value
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
        previous_currency: nil,
        effective_date: employee.hire_date,
        reason: reason
      )
    end
  end
end
