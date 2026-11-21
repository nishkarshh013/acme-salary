module QueryCounter
  # Number of SQL queries the block runs, ignoring schema lookups,
  # transactions and query-cache hits.
  def count_queries(&block)
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless payload[:cached] || %w[ SCHEMA TRANSACTION ].include?(payload[:name])
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure { |config| config.include QueryCounter }
