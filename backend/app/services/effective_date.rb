# Parses an effective date as it arrives from params and applies the rules
# every history entry shares: present, a real date, and not in the future.
class EffectiveDate
  attr_reader :value

  def initialize(raw)
    @raw = raw
    # Invalid dates such as "2026-13-45" cast to nil rather than raising.
    @value = ActiveModel::Type::Date.new.cast(raw)
  end

  def errors
    return [ "Effective date can't be blank" ] if @raw.blank?
    return [ "Effective date is not a valid date" ] if value.nil?
    return [ "Effective date can't be in the future" ] if value > Date.current

    []
  end

  # Message for a date earlier than the latest entry of a history, or nil.
  def earlier_than_latest_error(latest, history_name)
    return if value.nil? || latest.nil? || value >= latest

    "Effective date can't be earlier than the latest #{history_name} (#{latest.iso8601})"
  end
end
