FactoryBot.define do
  factory :employee_assignment do
    employee
    country { employee.country }
    department { employee.department }
    job_title { employee.job_title }
    effective_date { Date.new(2024, 1, 1) }
    reason { "Promotion" }
  end
end
