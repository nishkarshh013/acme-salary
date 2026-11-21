module Salaries
  # A salary amount as it arrives from params, with the rules every service
  # applies to it. label starts each message ("Amount", "New salary", "Salary").
  class Amount
    # Largest value a decimal(15,2) column can hold.
    MAX = BigDecimal("9999999999999.99")

    attr_reader :value

    def initialize(raw, label: "Amount")
      @raw = raw
      @label = label
      @value = to_decimal(raw)
    end

    def errors
      return [ "#{label} can't be blank" ] if raw.blank?
      return [ "#{label} is not a number" ] if value.nil? || !value.finite?
      # Reject rather than let the decimal(15,2) column round it silently.
      return [ "#{label} can have at most 2 decimal places" ] if value.round(2) != value
      return [ "#{label} must be greater than 0" ] unless value.positive?
      return [ "#{label} is too large" ] if value > MAX

      []
    end

    private

    attr_reader :raw, :label

    # Amounts arrive as strings from params; going through to_s keeps them
    # exact. Unparseable input ("abc") becomes nil rather than raising.
    def to_decimal(raw)
      return nil if raw.blank?

      BigDecimal(raw.to_s, exception: false)
    end
  end
end
