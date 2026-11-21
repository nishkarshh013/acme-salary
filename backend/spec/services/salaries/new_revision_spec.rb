require "rails_helper"

RSpec.describe Salaries::NewRevision do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:employee) do
    create(:employee, country: india, salary_currency: "INR", current_salary: BigDecimal("1000000.00"))
  end

  def new_revision(amount: "65000.00", currency: "EUR", effective_date: Date.new(2026, 6, 1), label: "New salary")
    described_class.new(employee: employee, amount: amount, currency: currency,
                        effective_date: EffectiveDate.new(effective_date), reason: "Relocation", label: label)
  end

  describe "#errors" do
    it "is empty for a valid amount" do
      expect(new_revision.errors).to be_empty
    end

    it "uses the given label in amount errors" do
      expect(new_revision(amount: "abc", label: "New salary").errors).to eq([ "New salary is not a number" ])
      expect(new_revision(amount: "abc", label: "Amount").errors).to eq([ "Amount is not a number" ])
    end

    it "rejects a date earlier than the employee's latest revision" do
      create(:salary_revision, employee: employee, currency: "INR", effective_date: Date.new(2026, 6, 2))

      expect(new_revision.errors)
        .to eq([ "Effective date can't be earlier than the latest salary revision (2026-06-02)" ])
    end
  end

  describe "#record!" do
    it "records the old and new salary and sets, but does not save, the employee's salary" do
      revision = new_revision.record!

      expect(revision).to be_persisted
      expect(revision).to have_attributes(
        previous_amount: BigDecimal("1000000.00"), previous_currency: "INR",
        amount: BigDecimal("65000.00"), currency: "EUR"
      )
      expect(employee).to have_attributes(current_salary: BigDecimal("65000.00"), salary_currency: "EUR")
      expect(employee.reload.current_salary).to eq(BigDecimal("1000000.00"))
    end
  end
end
