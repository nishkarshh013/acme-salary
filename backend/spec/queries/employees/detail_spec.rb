require "rails_helper"

RSpec.describe Employees::Detail do
  it "loads the employee with references and both histories preloaded" do
    employee = create(:employee)
    create(:salary_revision, employee: employee, currency: employee.salary_currency)
    create(:employee_assignment, employee: employee)

    found = described_class.find(employee.id)

    expect(found).to eq(employee)
    expect(%i[ country department job_title salary_revisions employee_assignments ]
             .map { |name| found.association(name).loaded? }).to all(be(true))
    expect(found.employee_assignments.first.association(:country)).to be_loaded
  end

  it "raises RecordNotFound for an unknown id" do
    expect { described_class.find(0) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
