module Salaries
  # The salary part of a change, shared by Salaries::Revise and
  # Employees::ChangeAssignment: validates the new amount and, once the
  # caller's checks pass, records the revision and sets the employee's
  # current salary. The caller saves the employee in the same transaction.
  class NewRevision
    def initialize(employee:, amount:, currency:, effective_date:, reason:, label: "Amount")
      @employee = employee
      @amount = Amount.new(amount, label: label)
      @currency = currency
      @effective_date = effective_date
      @reason = reason
    end

    # effective_date is an EffectiveDate; its own errors are the caller's to report.
    def errors
      [ *amount.errors, effective_date.earlier_than_latest_error(latest_revision_date, "salary revision") ].compact
    end

    # Reads the previous salary and currency from the employee before
    # replacing them, so call it before the employee is changed.
    def record!
      revision = employee.salary_revisions.create!(
        amount: amount.value,
        currency: currency,
        previous_amount: employee.current_salary,
        previous_currency: employee.salary_currency,
        effective_date: effective_date.value,
        reason: reason
      )
      employee.assign_attributes(current_salary: amount.value, salary_currency: currency)
      revision
    end

    private

    attr_reader :employee, :amount, :currency, :effective_date, :reason

    def latest_revision_date
      employee.salary_revisions.maximum(:effective_date)
    end
  end
end
