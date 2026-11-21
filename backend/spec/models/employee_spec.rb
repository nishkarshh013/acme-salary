require "rails_helper"

RSpec.describe Employee, type: :model do
  subject { build(:employee) }

  describe "associations" do
    it { is_expected.to belong_to(:country) }
    it { is_expected.to belong_to(:department) }
    it { is_expected.to belong_to(:job_title) }
    it { is_expected.to have_many(:salary_revisions).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:employee_assignments).dependent(:restrict_with_error) }
  end

  describe "deletion" do
    it "is blocked once the employee has a salary revision" do
      employee = create(:employee)
      create(:salary_revision, employee: employee)

      expect(employee.destroy).to be(false)
      expect(employee.errors[:base]).to be_present
      expect(Employee.exists?(employee.id)).to be(true)
    end

    it "is blocked once the employee has an assignment" do
      employee = create(:employee)
      create(:employee_assignment, employee: employee)

      expect(employee.destroy).to be(false)
      expect(Employee.exists?(employee.id)).to be(true)
    end

    it "keeps history when the employee is made inactive" do
      employee = create(:employee)
      revision = create(:salary_revision, employee: employee)

      employee.inactive!

      expect(employee.reload.salary_revisions).to contain_exactly(revision)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:employee_code) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:hire_date) }
    it { is_expected.to validate_presence_of(:current_salary) }
    it { is_expected.to validate_presence_of(:salary_currency) }

    it { is_expected.to validate_uniqueness_of(:employee_code) }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }

    it { is_expected.to validate_numericality_of(:current_salary).is_greater_than(0) }

    it { is_expected.to allow_value("jane.doe@acme.com").for(:email) }
    it { is_expected.not_to allow_value("jane.doe", "jane@", "@acme.com").for(:email) }

    it do
      is_expected.to define_enum_for(:status)
        .with_values(active: "active", inactive: "inactive")
        .backed_by_column_of_type(:string)
        .with_default(:active)
        .validating
    end
  end

  describe "salary currency" do
    let(:india) { create(:country, code: "IN", currency_code: "INR") }

    it "is valid when it matches the country's currency" do
      employee = build(:employee, country: india, salary_currency: "INR")

      expect(employee).to be_valid
    end

    it "is invalid when it differs from the country's currency" do
      employee = build(:employee, country: india, salary_currency: "USD")

      expect(employee).not_to be_valid
      expect(employee.errors[:salary_currency]).to include("must match the country's currency (INR)")
    end

    it "keeps two decimal places without float rounding" do
      employee = create(:employee, country: india, salary_currency: "INR",
                                   current_salary: BigDecimal("1234567.89"))

      expect(employee.reload.current_salary).to eq(BigDecimal("1234567.89"))
    end
  end

  describe "normalization" do
    it "downcases and strips email" do
      expect(build(:employee, email: "  Jane.Doe@ACME.com ").email).to eq("jane.doe@acme.com")
    end

    it "upcases salary_currency" do
      expect(build(:employee, salary_currency: "usd").salary_currency).to eq("USD")
    end
  end

  describe "database" do
    it "rejects a status outside active and inactive" do
      employee = create(:employee)

      expect { employee.update_column(:status, "retired") }
        .to raise_error(ActiveRecord::StatementInvalid, /employees_status_check/)
    end

    it "rejects a non-positive salary" do
      employee = create(:employee)

      expect { employee.update_column(:current_salary, 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /employees_current_salary_positive/)
    end
  end

  describe "employee codes" do
    it "formats a number as an employee code" do
      expect(described_class.code_for(42)).to eq("EMP00042")
      expect(described_class.code_for(123_456)).to eq("EMP123456")
    end

    it "finds the highest code number numerically, ignoring other formats" do
      create(:employee, employee_code: "EMP99999")
      create(:employee, employee_code: "EMP100000")
      create(:employee, employee_code: "LEGACY-7")

      expect(described_class.highest_code_number).to eq(100_000)
    end

    it "is 0 with no employees" do
      expect(described_class.highest_code_number).to eq(0)
    end
  end

  describe "optimistic locking" do
    it "rejects an update made on stale data" do
      employee = create(:employee, first_name: "Jane")
      stale_copy = Employee.find(employee.id)

      employee.update!(first_name: "Janet")

      expect { stale_copy.update!(first_name: "Joan") }.to raise_error(ActiveRecord::StaleObjectError)
    end
  end
end
