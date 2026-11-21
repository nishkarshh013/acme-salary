FactoryBot.define do
  factory :exchange_rate do
    sequence(:currency_code, "AAA")
    rate_to_usd { BigDecimal("1.0") }
    as_of { Date.new(2026, 1, 1) }
  end
end
