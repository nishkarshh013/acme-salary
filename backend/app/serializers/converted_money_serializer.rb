# A USD figure converted from local currencies with the fixed rate table.
# Always labelled, so it can't be mistaken for an amount in local currency:
#   { amount: "140400.54", currency: "USD", converted: true,
#     rates_as_of: "2026-10-01", label: "USD, converted at fixed rates as of 2026-10-01" }
# amount is nil when an exchange rate is missing.
class ConvertedMoneySerializer
  CURRENCY = "USD".freeze

  def self.call(amount, rates_as_of)
    {
      amount: amount && MoneySerializer.format_amount(amount),
      currency: CURRENCY,
      converted: true,
      rates_as_of: rates_as_of&.iso8601,
      label: label(amount, rates_as_of)
    }
  end

  def self.label(amount, rates_as_of)
    return "USD conversion unavailable: an exchange rate is missing" if amount.nil?
    return "USD, converted at fixed rates" if rates_as_of.nil? # nothing to convert

    "USD, converted at fixed rates as of #{rates_as_of.iso8601}"
  end
  private_class_method :label
end
