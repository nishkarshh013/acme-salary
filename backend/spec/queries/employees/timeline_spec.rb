require "rails_helper"

RSpec.describe Employees::Timeline do
  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:germany) { create(:country, code: "DE", currency_code: "EUR") }
  let(:employee) { create(:employee, country: germany, salary_currency: "EUR") }

  let!(:hired) do
    create(:employee_assignment, employee: employee, country: india, effective_date: Date.new(2022, 1, 1), reason: "Hired")
  end
  let!(:first_salary) do
    create(:salary_revision, employee: employee, currency: "INR", amount: BigDecimal("1000000"),
                             effective_date: Date.new(2022, 1, 1), reason: "Hired")
  end
  let!(:raise_entry) do
    create(:salary_revision, employee: employee, currency: "INR", amount: BigDecimal("1100000"),
                             previous_amount: BigDecimal("1000000"), previous_currency: "INR",
                             effective_date: Date.new(2023, 1, 1), reason: "Annual review")
  end
  let!(:move) do
    create(:employee_assignment, employee: employee, country: germany, effective_date: Date.new(2024, 6, 1),
                                 reason: "Relocation")
  end
  let!(:move_salary) do
    create(:salary_revision, employee: employee, currency: "EUR", amount: BigDecimal("70000"),
                             previous_amount: BigDecimal("1100000"), previous_currency: "INR",
                             effective_date: Date.new(2024, 6, 1), reason: "Relocation")
  end

  let(:timeline) { described_class.call(employee.reload) }

  it "merges both histories, newest first" do
    expect(timeline.map(&:record)).to eq([ move_salary, move, raise_entry, first_salary, hired ])
  end

  it "labels each entry with its kind" do
    expect(timeline.map(&:kind)).to eq(%i[ salary_revision assignment salary_revision salary_revision assignment ])
  end

  it "pairs each assignment with the one before it" do
    assignments = timeline.select { |entry| entry.kind == :assignment }

    expect(assignments.map(&:previous)).to eq([ hired, nil ])
  end

  it "is empty for an employee with no history" do
    expect(described_class.call(create(:employee))).to eq([])
  end
end
