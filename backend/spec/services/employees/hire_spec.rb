require "rails_helper"

RSpec.describe Employees::Hire do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:department) { create(:department, name: "Engineering") }
  let(:job_title) { create(:job_title, name: "Software Engineer") }
  let(:attributes) do
    {
      first_name: "Asha",
      last_name: "Rao",
      email: "asha.rao@acme.test",
      hire_date: Date.new(2026, 6, 1),
      country: india,
      department: department,
      job_title: job_title
    }
  end

  def hire(attributes: self.attributes, salary: BigDecimal("1200000.00"), **options)
    described_class.call(attributes: attributes, salary: salary, **options)
  end

  describe "a successful hire" do
    it "creates the employee with the salary in the country's currency" do
      result = hire

      expect(result).to be_success
      employee = result.record.reload
      expect(employee).to have_attributes(
        employee_code: "EMP00001",
        current_salary: BigDecimal("1200000.00"),
        salary_currency: "INR",
        status: "active"
      )
    end

    it "uses the salary argument and the country's currency, whatever the attributes say" do
      result = hire(attributes: attributes.merge(current_salary: 1, salary_currency: "USD"))

      expect(result.record.reload).to have_attributes(current_salary: BigDecimal("1200000.00"),
                                                      salary_currency: "INR")
    end

    it "records the first assignment on the hire date" do
      employee = hire.record

      expect(employee.employee_assignments.sole).to have_attributes(
        country: india,
        department: department,
        job_title: job_title,
        effective_date: Date.new(2026, 6, 1),
        reason: "Hired"
      )
    end

    it "records the first salary revision with no previous amount" do
      employee = hire.record

      expect(employee.salary_revisions.sole).to have_attributes(
        amount: BigDecimal("1200000.00"),
        currency: "INR",
        previous_amount: nil,
        previous_currency: nil,
        effective_date: Date.new(2026, 6, 1),
        reason: "Hired"
      )
    end

    it "uses the given reason for both history rows" do
      employee = hire(reason: "Acquisition of Beta Ltd").record

      expect(employee.employee_assignments.sole.reason).to eq("Acquisition of Beta Ltd")
      expect(employee.salary_revisions.sole.reason).to eq("Acquisition of Beta Ltd")
    end

    it "allows a hire dated today" do
      expect(hire(attributes: attributes.merge(hire_date: Date.new(2026, 6, 15)))).to be_success
    end
  end

  describe "employee codes" do
    def hire_as(email) = hire(attributes: attributes.merge(email: email))

    it "starts at EMP00001" do
      expect(hire.record.employee_code).to eq("EMP00001")
    end

    it "gives sequential hires consecutive codes after the highest in use" do
      create(:employee, employee_code: "EMP10000")

      expect(hire_as("first@acme.test").record.employee_code).to eq("EMP10001")
      expect(hire_as("second@acme.test").record.employee_code).to eq("EMP10002")
    end

    it "continues in numeric order past five digits" do
      create(:employee, employee_code: "EMP99999")
      create(:employee, employee_code: "EMP100000")

      expect(hire.record.employee_code).to eq("EMP100001")
    end

    it "ignores a client-supplied employee code" do
      result = hire(attributes: attributes.merge(employee_code: "CUSTOM-1", "employee_code" => "CUSTOM-2"))

      expect(result.record.reload.employee_code).to eq("EMP00001")
    end

    # A stale highest-code read stands in for a concurrent hire that took
    # the code between choosing it and saving.
    context "when another hire takes the chosen code first" do
      before do
        create(:employee, employee_code: "EMP00001")
        allow(Employee).to receive(:highest_code_number).and_return(0)
      end

      it "retries with the next number and succeeds (caught by the validation)" do
        result = hire

        expect(result).to be_success
        expect(result.record.reload.employee_code).to eq("EMP00002")
        expect(result.record.salary_revisions.count).to eq(1)
      end

      it "retries with the next number and succeeds (caught by the unique index)" do
        allow_any_instance_of(ActiveRecord::Validations::UniquenessValidator).to receive(:validate_each)

        expect(hire.record.reload.employee_code).to eq("EMP00002")
      end
    end

    context "when every attempt collides" do
      before do
        %w[ EMP00001 EMP00002 EMP00003 ].each { |code| create(:employee, employee_code: code) }
        allow(Employee).to receive(:highest_code_number).and_return(0)
      end

      it "gives up after 3 attempts and saves nothing" do
        result = nil

        expect { result = hire }
          .to not_change(Employee, :count)
          .and not_change(EmployeeAssignment, :count)
          .and not_change(SalaryRevision, :count)

        expect(result.errors).to eq([ described_class::CODE_EXHAUSTED_MESSAGE ])
      end
    end
  end

  describe "a rejected hire" do
    shared_examples "saves nothing" do |expected_error|
      it "fails with a clear error and saves nothing" do
        result = nil

        expect { result = hire_call }
          .to not_change(Employee, :count)
          .and not_change(EmployeeAssignment, :count)
          .and not_change(SalaryRevision, :count)

        expect(result).to be_failure
        expect(result.errors).to include(expected_error)
      end
    end

    context "when the hire date is in the future" do
      let(:hire_call) { hire(attributes: attributes.merge(hire_date: Date.new(2026, 6, 16))) }

      include_examples "saves nothing", "Hire date can't be in the future"
    end

    context "when the salary is zero" do
      let(:hire_call) { hire(salary: BigDecimal("0")) }

      include_examples "saves nothing", "Salary must be greater than 0"
    end

    context "when the salary can't be parsed" do
      let(:hire_call) { hire(salary: "abc") }

      include_examples "saves nothing", "Salary is not a number"
    end

    context "when the salary has more than two decimal places" do
      let(:hire_call) { hire(salary: "100.555") }

      include_examples "saves nothing", "Salary can have at most 2 decimal places"
    end

    context "when an employee attribute is invalid" do
      let(:hire_call) { hire(attributes: attributes.merge(email: "not-an-email")) }

      include_examples "saves nothing", "Email is invalid"
    end

    context "when the email is already taken" do
      before { create(:employee, email: "asha.rao@acme.test") }

      let(:hire_call) { hire }

      include_examples "saves nothing", "Email has already been taken"
    end

    # Simulates two hires racing: both pass the uniqueness validation before
    # either has inserted, so only the database's unique index catches it.
    context "when a concurrent hire inserts the same email first" do
      before do
        create(:employee, email: "asha.rao@acme.test")
        allow_any_instance_of(ActiveRecord::Validations::UniquenessValidator)
          .to receive(:validate_each)
      end

      let(:hire_call) { hire }

      include_examples "saves nothing", described_class::DUPLICATE_EMAIL_MESSAGE
    end

    # The employee row is valid and gets inserted, then the first history
    # row fails: the transaction must roll the employee back too.
    context "when the history rows can't be saved" do
      let(:hire_call) { hire(reason: "") }

      include_examples "saves nothing", "Reason can't be blank"
    end
  end
end
