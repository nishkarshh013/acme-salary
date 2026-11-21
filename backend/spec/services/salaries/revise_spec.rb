require "rails_helper"

RSpec.describe Salaries::Revise do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:employee) do
    create(:employee, country: india, salary_currency: "INR",
                      current_salary: BigDecimal("1000000.00"), status: "active")
  end

  before do
    create(:salary_revision, employee: employee, amount: BigDecimal("1000000.00"),
                             currency: "INR", effective_date: Date.new(2026, 1, 1))
  end

  def revise(amount: BigDecimal("1100000.00"), effective_date: Date.new(2026, 6, 1),
             reason: "Annual review", lock_version: employee.lock_version)
    described_class.call(employee: employee, amount: amount, effective_date: effective_date,
                         reason: reason, lock_version: lock_version)
  end

  describe "a successful revision" do
    it "records the revision with the previous salary and the country's currency" do
      result = revise

      expect(result).to be_success
      expect(result.record).to be_persisted
      expect(result.record).to have_attributes(
        employee: employee,
        amount: BigDecimal("1100000.00"),
        previous_amount: BigDecimal("1000000.00"),
        previous_currency: "INR",
        currency: "INR",
        effective_date: Date.new(2026, 6, 1),
        reason: "Annual review"
      )
    end

    it "updates the employee's current salary and bumps lock_version" do
      expect { revise }.to change { employee.reload.lock_version }.by(1)

      expect(employee.current_salary).to eq(BigDecimal("1100000.00"))
    end

    it "allows the same effective date as the latest revision" do
      expect(revise(effective_date: Date.new(2026, 1, 1))).to be_success
    end

    it "allows an effective date of today" do
      expect(revise(effective_date: Date.new(2026, 6, 15))).to be_success
    end

    it "accepts amount, date and lock_version as strings, as they arrive from params" do
      result = revise(amount: "1100000.50", effective_date: "2026-06-01",
                      lock_version: employee.lock_version.to_s)

      expect(result).to be_success
      expect(employee.reload.current_salary).to eq(BigDecimal("1100000.50"))
    end

    it "works for an employee with no earlier revision" do
      other = create(:employee, country: india, salary_currency: "INR")

      result = described_class.call(employee: other, amount: BigDecimal("900000.00"),
                                    effective_date: Date.new(2026, 6, 1), reason: "Correction",
                                    lock_version: other.lock_version)

      expect(result).to be_success
    end
  end

  describe "a rejected revision" do
    shared_examples "saves nothing" do |expected_error|
      it "fails with a clear error and leaves history and current values unchanged" do
        employee # create the employee and its first revision before counting
        before_values = employee.reload.attributes.slice("current_salary", "salary_currency", "lock_version")
        result = nil

        expect { result = revise_call }
          .to not_change(SalaryRevision, :count)
          .and not_change(EmployeeAssignment, :count)

        expect(result).to be_failure
        expect(result.errors).to include(expected_error)
        expect(employee.reload.attributes.slice("current_salary", "salary_currency", "lock_version"))
          .to eq(before_values)
      end
    end

    context "when the amount is zero" do
      let(:revise_call) { revise(amount: BigDecimal("0")) }

      include_examples "saves nothing", "Amount must be greater than 0"
    end

    context "when the amount is negative" do
      let(:revise_call) { revise(amount: BigDecimal("-5.00")) }

      include_examples "saves nothing", "Amount must be greater than 0"
    end

    context "when the amount can't be parsed" do
      let(:revise_call) { revise(amount: "abc") }

      include_examples "saves nothing", "Amount is not a number"
    end

    context "when the amount has more than two decimal places" do
      let(:revise_call) { revise(amount: "100.555") }

      include_examples "saves nothing", "Amount can have at most 2 decimal places"
    end

    context "when the amount is blank" do
      let(:revise_call) { revise(amount: "") }

      include_examples "saves nothing", "Amount can't be blank"
    end

    context "when the amount is too large for the column" do
      let(:revise_call) { revise(amount: "10000000000000.00") }

      include_examples "saves nothing", "Amount is too large"
    end

    context "when the effective date is in the future" do
      let(:revise_call) { revise(effective_date: Date.new(2026, 6, 16)) }

      include_examples "saves nothing", "Effective date can't be in the future"
    end

    context "when the effective date can't be parsed" do
      let(:revise_call) { revise(effective_date: "2026-13-45") }

      include_examples "saves nothing", "Effective date is not a valid date"
    end

    context "when the effective date is missing" do
      let(:revise_call) { revise(effective_date: nil) }

      include_examples "saves nothing", "Effective date can't be blank"
    end

    context "when the effective date is earlier than the latest revision" do
      let(:revise_call) { revise(effective_date: Date.new(2025, 12, 31)) }

      include_examples "saves nothing",
                       "Effective date can't be earlier than the latest salary revision (2026-01-01)"
    end

    context "when the employee is inactive" do
      before { employee.inactive! }

      let(:revise_call) { revise }

      include_examples "saves nothing", "Salary can't be revised for an inactive employee"
    end

    context "when the reason is blank" do
      let(:revise_call) { revise(reason: "") }

      include_examples "saves nothing", "Reason can't be blank"
    end

    context "when the caller's lock_version is out of date" do
      let(:revise_call) { revise(lock_version: employee.lock_version - 1) }

      include_examples "saves nothing", described_class::STALE_MESSAGE
    end

    context "when no lock_version is given" do
      let(:revise_call) { revise(lock_version: nil) }

      include_examples "saves nothing", described_class::STALE_MESSAGE
    end

    # The caller's copy matches what they saw, but someone else saved the
    # employee in between. The revision row is inserted before the employee
    # update fails, so this also proves the transaction rolls it back.
    context "when someone else changes the employee after it was loaded" do
      let(:revise_call) do
        Employee.find(employee.id).update!(first_name: "Changed")
        revise(lock_version: employee.lock_version)
      end

      it "fails with the stale message and leaves history unchanged" do
        employee
        result = nil

        expect { result = revise_call }.not_to change(SalaryRevision, :count)

        expect(result.errors).to eq([ described_class::STALE_MESSAGE ])
        expect(employee.reload.current_salary).to eq(BigDecimal("1000000.00"))
      end

      it "reloads the in-memory employee so it matches the database" do
        employee
        revise_call

        expect(employee).not_to be_changed
        expect(employee).to have_attributes(first_name: "Changed", current_salary: BigDecimal("1000000.00"))
        expect(employee.attributes).to eq(Employee.find(employee.id).attributes)
      end
    end
  end
end
