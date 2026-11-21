# An active employee in India with a hire assignment and hire revision on
# 2026-01-01, with the clock frozen at 2026-06-15 noon.
RSpec.shared_context "employee with history" do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  let(:india) { create(:country, code: "IN", name: "India", currency_code: "INR") }
  let(:germany) { create(:country, code: "DE", name: "Germany", currency_code: "EUR") }
  let(:engineering) { create(:department, name: "Engineering") }
  let(:sales) { create(:department, name: "Sales") }
  let(:engineer) { create(:job_title, name: "Engineer") }
  let(:senior_engineer) { create(:job_title, name: "Senior Engineer") }

  let!(:employee) do
    create(:employee, first_name: "Asha", last_name: "Rao", email: "asha.rao@acme.test", status: "active",
                      country: india, department: engineering, job_title: engineer,
                      current_salary: BigDecimal("1000000.00"), salary_currency: "INR").tap do |employee|
      create(:employee_assignment, employee: employee, country: india, department: engineering, job_title: engineer,
                                   effective_date: Date.new(2026, 1, 1), reason: "Hired")
      create(:salary_revision, employee: employee, amount: BigDecimal("1000000.00"), currency: "INR",
                               effective_date: Date.new(2026, 1, 1), reason: "Hired")
    end
  end
end
