# A small data set with hand-computed answers.
#
# India (INR, 0.012 USD, rates as of 2026-10-01)
#   Engineering: 1,000,000 / 2,000,000 / 4,000,000   (odd count: median 2,000,000)
#   Sales:       3,000,000, plus an inactive 9,000,000 that must be ignored
#   Country:     4 active, median 2,500,000 (even count), total 10,000,000 = 120,000.00 USD
# Germany (EUR, 1.08 USD, rates as of 2026-09-15)
#   Engineering: 60,000.00 / 70,000.50 (even count: median 65,000.25)
#   Total 130,000.50 = 140,400.54 USD
# France (EUR): one inactive employee only, so no active employees
# Japan (JPY): no employees at all
RSpec.shared_context "salary statistics data" do
  let!(:inr_rate) { create(:exchange_rate, currency_code: "INR", rate_to_usd: BigDecimal("0.012"), as_of: Date.new(2026, 10, 1)) }
  let!(:eur_rate) { create(:exchange_rate, currency_code: "EUR", rate_to_usd: BigDecimal("1.08"), as_of: Date.new(2026, 9, 15)) }
  let!(:jpy_rate) { create(:exchange_rate, currency_code: "JPY", rate_to_usd: BigDecimal("0.0067"), as_of: Date.new(2026, 10, 1)) }

  let!(:india) { create(:country, code: "IN", name: "India", currency_code: "INR") }
  let!(:germany) { create(:country, code: "DE", name: "Germany", currency_code: "EUR") }
  let!(:france) { create(:country, code: "FR", name: "France", currency_code: "EUR") }
  let!(:japan) { create(:country, code: "JP", name: "Japan", currency_code: "JPY") }

  let!(:engineering) { create(:department, name: "Engineering") }
  let!(:sales) { create(:department, name: "Sales") }
  let!(:support) { create(:department, name: "Support") }
  let!(:engineer) { create(:job_title, name: "Engineer") }
  let!(:manager) { create(:job_title, name: "Manager") }

  def staff(country, department, job_title, salary, status: "active")
    create(:employee, country: country, salary_currency: country.currency_code, department: department,
                      job_title: job_title, current_salary: BigDecimal(salary), status: status)
  end

  before do
    staff(india, engineering, engineer, "1000000")
    staff(india, engineering, engineer, "2000000")
    staff(india, engineering, manager, "4000000")
    staff(india, sales, manager, "3000000")
    staff(india, sales, manager, "9000000", status: "inactive")
    staff(germany, engineering, engineer, "60000.00")
    staff(germany, engineering, engineer, "70000.50")
    staff(france, sales, engineer, "50000", status: "inactive")
  end
end
