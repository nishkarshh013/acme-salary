module EmployeeSnapshot
  # The employee row and history counts, for asserting that a failed
  # request changed nothing.
  def employee_snapshot(employee)
    {
      attributes: Employee.find(employee.id).attributes,
      salary_revisions: SalaryRevision.where(employee_id: employee.id).count,
      assignments: EmployeeAssignment.where(employee_id: employee.id).count
    }
  end
end

RSpec.configure { |config| config.include EmployeeSnapshot, type: :request }
