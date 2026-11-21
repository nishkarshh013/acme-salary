# Returned by every service. Business-rule violations are failures with
# messages, not exceptions, so callers can render them directly.
# On success, record is the record the service created.
ServiceResult = Data.define(:success, :record, :errors) do
  def self.success(record)
    new(success: true, record: record, errors: [].freeze)
  end

  def self.failure(errors, record: nil)
    new(success: false, record: record, errors: Array(errors).freeze)
  end

  def success? = success
  def failure? = !success
end
