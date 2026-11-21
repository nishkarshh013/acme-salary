module Salaries
  # Records a new salary revision and updates the employee's current salary
  # in one transaction. lock_version is the version the caller last saw; if
  # the employee has changed since, the revision is rejected.
  class Revise
    STALE_MESSAGE = "This employee was changed by someone else. Reload and try again.".freeze
    # Largest value a decimal(15,2) column can hold.
    MAX_AMOUNT = BigDecimal("9999999999999.99")

    def self.call(...) = new(...).call

    def initialize(employee:, amount:, effective_date:, reason:, lock_version:)
      @employee = employee
      @raw_amount = amount
      @amount = to_decimal(amount)
      @raw_effective_date = effective_date
      # Invalid dates such as "2026-13-45" cast to nil rather than raising.
      @effective_date = ActiveModel::Type::Date.new.cast(effective_date)
      @reason = reason
      @lock_version = Integer(lock_version, exception: false)
    end

    def call
      return ServiceResult.failure(STALE_MESSAGE) unless lock_version == employee.lock_version

      errors = rule_violations
      return ServiceResult.failure(errors) if errors.any?

      revision = nil
      ApplicationRecord.transaction do
        revision = create_revision!
        # Optimistic locking: the UPDATE only matches if lock_version is unchanged.
        employee.update!(current_salary: amount)
      end

      ServiceResult.success(revision)
    rescue ActiveRecord::StaleObjectError
      ServiceResult.failure(STALE_MESSAGE)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :employee, :raw_amount, :amount, :raw_effective_date, :effective_date,
                :reason, :lock_version

    def rule_violations
      errors = []
      errors << "Salary can't be revised for an inactive employee" if employee.inactive?
      errors.concat(amount_violations)
      errors.concat(effective_date_violations)
      errors
    end

    def amount_violations
      return [ "Amount can't be blank" ] if raw_amount.blank?
      return [ "Amount is not a number" ] if amount.nil? || !amount.finite?
      # Reject rather than let the decimal(15,2) column round it silently.
      return [ "Amount can have at most 2 decimal places" ] if amount.round(2) != amount
      return [ "Amount must be greater than 0" ] unless amount.positive?
      return [ "Amount is too large" ] if amount > MAX_AMOUNT

      []
    end

    def effective_date_violations
      return [ "Effective date can't be blank" ] if raw_effective_date.blank?
      return [ "Effective date is not a valid date" ] if effective_date.nil?
      return [ "Effective date can't be in the future" ] if effective_date.future?

      latest = employee.salary_revisions.maximum(:effective_date)
      return [] if latest.nil? || effective_date >= latest

      [ "Effective date can't be earlier than the latest salary revision (#{latest.iso8601})" ]
    end

    def create_revision!
      employee.salary_revisions.create!(
        amount: amount,
        currency: employee.country.currency_code,
        previous_amount: employee.current_salary,
        effective_date: effective_date,
        reason: reason
      )
    end

    # Amounts arrive as strings from params; going through to_s keeps them
    # exact. Unparseable input ("abc") becomes nil rather than raising.
    def to_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s, exception: false)
    end
  end
end
