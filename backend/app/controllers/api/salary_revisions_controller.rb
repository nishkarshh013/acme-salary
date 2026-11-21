module Api
  # POST /api/employees/:employee_id/salary_revisions
  class SalaryRevisionsController < ApplicationController
    include EmployeeRendering

    def create
      employee = Employee.find(params[:employee_id])
      result = Salaries::Revise.call(employee: employee, amount: params[:amount], effective_date: params[:effective_date],
                                     reason: params[:reason], lock_version: params[:lock_version])
      return render_failure(result) if result.failure?

      render_employee(employee.id, status: :created)
    end
  end
end
