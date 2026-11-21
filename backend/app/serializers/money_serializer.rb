# Money goes out as a decimal string with its currency, never as a JSON
# number, because JavaScript numbers are floats: { amount: "100000.00", currency: "USD" }.
class MoneySerializer
  def self.call(amount, currency)
    return nil if amount.nil?

    { amount: format_amount(amount), currency: currency }
  end

  # Exact: BigDecimal throughout, no float formatting.
  def self.format_amount(amount)
    integer, fraction = BigDecimal(amount.to_s).round(2).to_s("F").split(".")
    "#{integer}.#{fraction.to_s.ljust(2, '0')}"
  end
end
