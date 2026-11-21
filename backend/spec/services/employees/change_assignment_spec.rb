require "rails_helper"

RSpec.describe Employees::ChangeAssignment do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:germany) { create(:country, code: "DE", currency_code: "EUR") }
  let(:engineering) { create(:department, name: "Engineering") }
  let(:sales) { create(:department, name: "Sales") }
  let(:engineer) { create(:job_title, name: "Engineer") }
  let(:senior_engineer) { create(:job_title, name: "Senior Engineer") }

  let(:latest_assignment_date) { Date.new(2026, 1, 1) }
  let(:latest_revision_date) { Date.new(2026, 1, 1) }

  let!(:employee) do
    create(:employee, country: india, department: engineering, job_title: engineer,
                      current_salary: BigDecimal("1000000.00"), salary_currency: "INR", status: "active")
  end

  before do
    create(:employee_assignment, employee: employee, country: india, department: engineering,
                                 job_title: engineer, effective_date: latest_assignment_date)
    create(:salary_revision, employee: employee, amount: BigDecimal("1000000.00"), currency: "INR",
                             effective_date: latest_revision_date)
  end

  def change_assignment(effective_date: Date.new(2026, 6, 1), reason: "Reorganisation",
             lock_version: employee.lock_version, **changes)
    described_class.call(employee: employee, effective_date: effective_date, reason: reason,
                         lock_version: lock_version, **changes)
  end

  describe "a department-only change" do
    it "records the assignment and moves the employee, keeping everything else" do
      result = nil

      expect { result = change_assignment(department: sales) }
        .to change(EmployeeAssignment, :count).by(1)
        .and not_change(SalaryRevision, :count)

      expect(result).to be_success
      expect(result.record).to have_attributes(
        country: india, department: sales, job_title: engineer,
        effective_date: Date.new(2026, 6, 1), reason: "Reorganisation"
      )
      expect(employee.reload).to have_attributes(
        country: india, department: sales, job_title: engineer,
        current_salary: BigDecimal("1000000.00"), salary_currency: "INR"
      )
    end

    it "bumps lock_version once" do
      expect { change_assignment(department: sales) }.to change { employee.reload.lock_version }.by(1)
    end

    it "allows the same date as the latest assignment" do
      expect(change_assignment(department: sales, effective_date: latest_assignment_date)).to be_success
    end

    context "when the latest salary revision is newer than the effective date" do
      let(:latest_revision_date) { Date.new(2026, 6, 10) }

      it "is allowed, because no revision is created" do
        expect(change_assignment(department: sales, effective_date: Date.new(2026, 6, 1))).to be_success
      end
    end
  end

  describe "a promotion with a raise" do
    it "records the assignment and a revision with the same date and reason" do
      result = change_assignment(job_title: senior_engineer, new_salary: "1200000.00", reason: "Promotion")

      expect(result).to be_success
      expect(result.record).to have_attributes(job_title: senior_engineer, reason: "Promotion")
      expect(employee.salary_revisions.order(:id).last).to have_attributes(
        amount: BigDecimal("1200000.00"), currency: "INR",
        previous_amount: BigDecimal("1000000.00"), previous_currency: "INR",
        effective_date: Date.new(2026, 6, 1), reason: "Promotion"
      )
      expect(employee.reload).to have_attributes(
        job_title: senior_engineer, current_salary: BigDecimal("1200000.00"), salary_currency: "INR"
      )
    end
  end

  describe "a country move" do
    it "records the revision with the old amount and currency and the new ones" do
      result = change_assignment(country: germany, new_salary: "65000.00", reason: "Relocation to Berlin")

      expect(result).to be_success
      expect(result.record).to have_attributes(country: germany, department: engineering, job_title: engineer)
      expect(employee.salary_revisions.order(:id).last).to have_attributes(
        previous_amount: BigDecimal("1000000.00"), previous_currency: "INR",
        amount: BigDecimal("65000.00"), currency: "EUR",
        effective_date: Date.new(2026, 6, 1), reason: "Relocation to Berlin"
      )
      expect(employee.reload).to have_attributes(
        country: germany, current_salary: BigDecimal("65000.00"), salary_currency: "EUR"
      )
    end
  end

  describe "a same-currency move" do
    let(:france) { create(:country, code: "FR", currency_code: "EUR") }
    let(:berlin_engineer) do
      create(:employee, country: germany, department: engineering, job_title: engineer,
                        current_salary: BigDecimal("70000.00"), salary_currency: "EUR")
    end

    it "moves Germany to France without a new salary, keeping the current one" do
      result = nil

      expect do
        result = described_class.call(employee: berlin_engineer, country: france,
                                      effective_date: Date.new(2026, 6, 1), reason: "Relocation to Paris",
                                      lock_version: berlin_engineer.lock_version)
      end.to not_change(SalaryRevision, :count)

      expect(result).to be_success
      expect(berlin_engineer.reload).to have_attributes(
        country: france, current_salary: BigDecimal("70000.00"), salary_currency: "EUR"
      )
    end
  end

  describe "a rejected change" do
    shared_examples "saves nothing" do |expected_error|
      it "fails with a clear error and leaves history and the employee unchanged" do
        tracked = %w[country_id department_id job_title_id current_salary salary_currency lock_version]
        before_values = employee.reload.attributes.slice(*tracked)
        result = nil

        expect { result = change_call }
          .to not_change(EmployeeAssignment, :count)
          .and not_change(SalaryRevision, :count)

        expect(result).to be_failure
        expect(result.errors).to include(expected_error)
        expect(employee.reload.attributes.slice(*tracked)).to eq(before_values)
      end
    end

    context "when nothing changes" do
      let(:change_call) { change_assignment(country: india, department: engineering, job_title: engineer) }

      include_examples "saves nothing",
                       "Nothing to change: country, department and job title are already the current ones"
    end

    context "when only a new salary is given" do
      let(:change_call) { change_assignment(new_salary: "1200000.00") }

      include_examples "saves nothing",
                       "Nothing to change: country, department and job title are already the current ones"
    end

    context "when the currency changes (INR to EUR) without a new salary" do
      let(:change_call) { change_assignment(country: germany) }

      include_examples "saves nothing", "New salary is required when the salary currency changes (INR to EUR)"
    end

    context "when the new salary is zero" do
      let(:change_call) { change_assignment(job_title: senior_engineer, new_salary: "0") }

      include_examples "saves nothing", "New salary must be greater than 0"
    end

    context "when the new salary is negative" do
      let(:change_call) { change_assignment(country: germany, new_salary: "-1.00") }

      include_examples "saves nothing", "New salary must be greater than 0"
    end

    context "when the effective date is in the future" do
      let(:change_call) { change_assignment(department: sales, effective_date: Date.new(2026, 6, 16)) }

      include_examples "saves nothing", "Effective date can't be in the future"
    end

    context "when the effective date is earlier than the latest assignment" do
      let(:latest_assignment_date) { Date.new(2026, 3, 1) }
      let(:change_call) { change_assignment(department: sales, effective_date: Date.new(2026, 2, 28)) }

      include_examples "saves nothing", "Effective date can't be earlier than the latest assignment (2026-03-01)"
    end

    context "when a revision is created and the date is earlier than the latest revision" do
      let(:latest_revision_date) { Date.new(2026, 5, 1) }
      let(:change_call) do
        change_assignment(job_title: senior_engineer, new_salary: "1200000.00", effective_date: Date.new(2026, 4, 30))
      end

      include_examples "saves nothing",
                       "Effective date can't be earlier than the latest salary revision (2026-05-01)"
    end

    context "when the employee is inactive" do
      before { employee.inactive! }

      let(:change_call) { change_assignment(department: sales) }

      include_examples "saves nothing", "Assignment can't be changed for an inactive employee"
    end

    context "when the caller's lock_version is out of date" do
      let(:change_call) { change_assignment(department: sales, lock_version: employee.lock_version - 1) }

      include_examples "saves nothing", described_class::STALE_MESSAGE
    end

    context "when no lock_version is given" do
      let(:change_call) { change_assignment(department: sales, lock_version: nil) }

      include_examples "saves nothing", described_class::STALE_MESSAGE
    end
  end

  # Passes every check, inserts the assignment and the revision, then fails
  # on the employee update because someone else saved the employee after it
  # was loaded. The transaction must roll back both history rows.
  describe "a failure partway through" do
    it "rolls back the assignment and the revision" do
      result = nil

      expect do
        Employee.find(employee.id).update!(first_name: "Changed elsewhere")
        result = change_assignment(country: germany, new_salary: "65000.00")
      end.to not_change(EmployeeAssignment, :count)
        .and not_change(SalaryRevision, :count)

      expect(result.errors).to eq([ described_class::STALE_MESSAGE ])
      expect(employee.reload).to have_attributes(
        country: india, current_salary: BigDecimal("1000000.00"), salary_currency: "INR"
      )
    end

    it "reloads the in-memory employee so it matches the database" do
      Employee.find(employee.id).update!(first_name: "Changed elsewhere")

      change_assignment(country: germany, new_salary: "65000.00", lock_version: employee.lock_version)

      expect(employee).not_to be_changed
      expect(employee).to have_attributes(
        first_name: "Changed elsewhere", country: india,
        current_salary: BigDecimal("1000000.00"), salary_currency: "INR"
      )
      expect(employee.attributes).to eq(Employee.find(employee.id).attributes)
    end
  end
end
