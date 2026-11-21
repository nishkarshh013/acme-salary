# Returned by every service. Business-rule violations are failures with
# messages, not exceptions, so callers can render them directly.
# On success, record is the record the service created (or updated).
#
# error_type says why a failure happened, so controllers can choose the
# status without matching on message text:
#   :invalid - a business rule or validation failed (422)
#   :stale   - the employee changed since the caller loaded it (409)
ServiceResult = Data.define(:success, :record, :errors, :error_type) do
  def self.success(record)
    new(success: true, record: record, errors: [].freeze, error_type: nil)
  end

  def self.failure(errors, record: nil, error_type: :invalid)
    new(success: false, record: record, errors: Array(errors).freeze, error_type: error_type)
  end

  def success? = success
  def failure? = !success
  def stale? = error_type == :stale
end
