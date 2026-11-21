module Salaries
  # Records a new salary revision and updates the employee's current salary
  # in one transaction. lock_version is the version the caller last saw; if
  # the employee has changed since, the revision is rejected.
  class Revise
    include OptimisticLocking

    def self.call(...) = new(...).call

    def initialize(employee:, amount:, effective_date:, reason:, lock_version:)
      @employee = employee
      @lock_version = lock_version
      @effective_date = EffectiveDate.new(effective_date)
      @new_revision = NewRevision.new(
        employee: employee,
        amount: amount,
        currency: employee.country.currency_code,
        effective_date: @effective_date,
        reason: reason
      )
    end

    def call
      return stale_failure if stale?(employee, lock_version)

      errors = rule_violations
      return ServiceResult.failure(errors) if errors.any?

      revision = nil
      ApplicationRecord.transaction do
        revision = new_revision.record!
        employee.save!
      end

      ServiceResult.success(revision)
    rescue ActiveRecord::StaleObjectError
      employee.reload # drop the salary assigned above; match the database
      stale_failure
    rescue ActiveRecord::RecordInvalid => e
      employee.reload
      ServiceResult.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :employee, :lock_version, :effective_date, :new_revision

    def rule_violations
      errors = []
      errors << "Salary can't be revised for an inactive employee" if employee.inactive?
      errors.concat(effective_date.errors)
      errors.concat(new_revision.errors)
      errors
    end
  end
end
