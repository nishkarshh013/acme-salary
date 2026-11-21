require "rails_helper"

# "Today" is Date.current in the app time zone, not the server clock's UTC
# date. At 00:30 in India it is already 15 June there, but still 14 June in
# UTC: a date of 15 June must be accepted.
RSpec.describe "Today in the app time zone" do
  include_context "Asia/Kolkata at 00:30 IST"

  it "is the date in the configured zone" do
    expect(Date.current).to eq(ist_today)
    expect(Time.now.utc.to_date).to eq(Date.new(2026, 6, 14))
  end

  it "accepts today as an effective date" do
    expect(EffectiveDate.new(ist_today.iso8601).errors).to be_empty
    expect(EffectiveDate.new((ist_today + 1).iso8601).errors).to eq([ "Effective date can't be in the future" ])
  end

  it "accepts today in the history models" do
    employee = create(:employee)

    expect(build(:salary_revision, employee: employee, effective_date: ist_today)).to be_valid
    expect(build(:employee_assignment, employee: employee, effective_date: ist_today)).to be_valid
  end

  it "accepts a salary revision dated today" do
    india = create(:country, code: "IN", currency_code: "INR")
    employee = create(:employee, country: india, salary_currency: "INR", current_salary: BigDecimal("1000000"))

    result = Salaries::Revise.call(employee: employee, amount: "1100000", effective_date: ist_today.iso8601,
                                   reason: "Annual review", lock_version: employee.lock_version)

    expect(result).to be_success
  end

  it "accepts a hire dated today" do
    result = Employees::Hire.call(
      attributes: { first_name: "Asha", last_name: "Rao", email: "asha@acme.test", hire_date: ist_today,
                    country: create(:country), department: create(:department), job_title: create(:job_title) },
      salary: "100000"
    )

    expect(result).to be_success
  end

  it "would reject the same date if the app ran in UTC" do
    Time.use_zone("UTC") do
      expect(EffectiveDate.new(ist_today.iso8601).errors).to eq([ "Effective date can't be in the future" ])
    end
  end
end
