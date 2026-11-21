FactoryBot.define do
  factory :employee do
    sequence(:employee_code) { |n| format("EMP%05d", n) }
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    hire_date { Date.new(2020, 1, 15) }
    status { "active" }
    country
    department
    job_title
    current_salary { BigDecimal("50000.00") }
    salary_currency { country.currency_code }
  end
end
