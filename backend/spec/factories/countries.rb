FactoryBot.define do
  factory :country do
    sequence(:code, "AA")
    sequence(:name) { |n| "Country #{n}" }
    currency_code { "USD" }
  end
end
