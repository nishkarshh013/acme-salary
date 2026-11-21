FactoryBot.define do
  factory :salary_revision do
    employee
    amount { BigDecimal("55000.00") }
    currency { employee.salary_currency }
    previous_amount { nil }
    effective_date { Date.new(2024, 1, 1) }
    reason { "Annual review" }
  end
end
