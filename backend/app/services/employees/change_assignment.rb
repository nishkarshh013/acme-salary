module Employees
  # Moves an employee to a new country, department and/or job title. Records
  # the assignment, updates the employee's current values and, when
  # new_salary is given, records a salary revision with the same date and
  # reason, all in one transaction. Moving to a country with a different
  # currency requires new_salary, because the salary must be restated in the
  # new currency; a same-currency move keeps the current salary if none is given.
  class ChangeAssignment
    include OptimisticLocking

    def self.call(...) = new(...).call

    # Omitted country, department or job_title keep the employee's current one.
    def initialize(employee:, effective_date:, reason:, lock_version:,
                   country: nil, department: nil, job_title: nil, new_salary: nil)
      @employee = employee
      @reason = reason
      @lock_version = lock_version
      @country = country || employee.country
      @department = department || employee.department
      @job_title = job_title || employee.job_title
      @effective_date = EffectiveDate.new(effective_date)
      @new_revision = build_new_revision(new_salary)
    end

    def call
      return ServiceResult.failure(STALE_MESSAGE) if stale?(employee, lock_version)

      errors = rule_violations
      return ServiceResult.failure(errors) if errors.any?

      assignment = nil
      ApplicationRecord.transaction do
        assignment = create_assignment!
        new_revision&.record!
        employee.assign_attributes(country: country, department: department, job_title: job_title)
        employee.save!
      end

      ServiceResult.success(assignment)
    rescue ActiveRecord::StaleObjectError
      employee.reload # drop the values assigned above; match the database
      ServiceResult.failure(STALE_MESSAGE)
    rescue ActiveRecord::RecordInvalid => e
      employee.reload
      ServiceResult.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :employee, :reason, :lock_version, :country, :department, :job_title,
                :effective_date, :new_revision

    def build_new_revision(new_salary)
      return if new_salary.blank?

      Salaries::NewRevision.new(
        employee: employee,
        amount: new_salary,
        currency: country.currency_code,
        effective_date: effective_date,
        reason: reason,
        label: "New salary"
      )
    end

    def rule_violations
      errors = []
      errors << "Assignment can't be changed for an inactive employee" if employee.inactive?
      errors << "Nothing to change: country, department and job title are already the current ones" unless changes_assignment?
      errors << currency_change_error if currency_changes? && new_revision.nil?
      errors.concat(effective_date.errors)
      errors << latest_assignment_error
      errors.concat(new_revision.errors) if new_revision
      errors.compact
    end

    def changes_assignment?
      country_changes? || department != employee.department || job_title != employee.job_title
    end

    def country_changes?
      country != employee.country
    end

    def currency_changes?
      country.currency_code != employee.salary_currency
    end

    def currency_change_error
      "New salary is required when the salary currency changes " \
        "(#{employee.salary_currency} to #{country.currency_code})"
    end

    def latest_assignment_error
      latest = employee.employee_assignments.maximum(:effective_date)
      effective_date.earlier_than_latest_error(latest, "assignment")
    end

    def create_assignment!
      employee.employee_assignments.create!(
        country: country,
        department: department,
        job_title: job_title,
        effective_date: effective_date.value,
        reason: reason
      )
    end
  end
end
