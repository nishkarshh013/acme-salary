require "rails_helper"

RSpec.describe Employees::Update do
  let!(:employee) do
    create(:employee, first_name: "Asha", last_name: "Rao", email: "asha.rao@acme.test", status: "active",
                      current_salary: BigDecimal("1000000"))
  end

  def update(lock_version: employee.lock_version, **attributes)
    described_class.call(employee: employee, attributes: attributes, lock_version: lock_version)
  end

  def tracked = employee.reload.attributes.except("updated_at")

  it "changes name, email and status and bumps lock_version" do
    result = update(first_name: "Asha M", last_name: "Rao-Iyer", email: "ASHA@acme.test", status: "inactive")

    expect(result).to be_success
    expect(employee.reload).to have_attributes(first_name: "Asha M", last_name: "Rao-Iyer",
                                               email: "asha@acme.test", status: "inactive", lock_version: 1)
  end

  it "accepts string keys, as from params" do
    expect(update("first_name" => "Asha M")).to be_success
  end

  describe "a rejected update" do
    shared_examples "changes nothing" do |expected_error|
      it "fails with a clear error and leaves the employee unchanged" do
        before_values = tracked
        result = update_call

        expect(result).to be_failure
        expect(result.errors).to include(expected_error)
        expect(tracked).to eq(before_values)
      end
    end

    {
      current_salary: "Salary can't be changed here; record a salary revision instead",
      salary: "Salary can't be changed here; record a salary revision instead",
      salary_currency: "Salary currency can't be changed here; it follows the employee's country",
      country_id: "Country can't be changed here; record an assignment change instead",
      department_id: "Department can't be changed here; record an assignment change instead",
      job_title_id: "Job title can't be changed here; record an assignment change instead",
      hire_date: "Hire date can't be changed",
      employee_code: "Employee code can't be changed"
    }.each do |field, message|
      context "when #{field} is given" do
        let(:update_call) { update(first_name: "Changed", field => "x") }

        include_examples "changes nothing", message
      end
    end

    it "lists each locked-field message once" do
      expect(update(salary: 1, current_salary: 2, country_id: 3).errors).to eq([
        "Salary can't be changed here; record a salary revision instead",
        "Country can't be changed here; record an assignment change instead"
      ])
    end

    context "when the email is invalid" do
      let(:update_call) { update(email: "not-an-email") }

      include_examples "changes nothing", "Email is invalid"
    end

    context "when the status is unknown" do
      let(:update_call) { update(status: "retired") }

      include_examples "changes nothing", "Status is not included in the list"
    end

    context "when the email belongs to someone else" do
      before { create(:employee, email: "taken@acme.test") }

      let(:update_call) { update(email: "taken@acme.test") }

      include_examples "changes nothing", "Email has already been taken"
    end

    context "when the caller's lock_version is out of date" do
      let(:update_call) { update(first_name: "Changed", lock_version: employee.lock_version - 1) }

      include_examples "changes nothing", OptimisticLocking::STALE_MESSAGE
    end

    it "marks a stale lock_version as stale" do
      expect(update(first_name: "Changed", lock_version: nil)).to be_stale
    end

    it "is stale, and reloads the employee, when someone else saved in between" do
      Employee.find(employee.id).update!(last_name: "Elsewhere")

      result = update(first_name: "Changed")

      expect(result).to be_stale
      expect(employee).not_to be_changed
      expect(employee).to have_attributes(first_name: "Asha", last_name: "Elsewhere")
    end

    it "reloads the employee after a validation failure" do
      update(email: "not-an-email")

      expect(employee).not_to be_changed
      expect(employee.email).to eq("asha.rao@acme.test")
    end
  end
end
