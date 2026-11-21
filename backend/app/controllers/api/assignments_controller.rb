module Api
  # POST /api/employees/:employee_id/assignments
  class AssignmentsController < ApplicationController
    include EmployeeRendering

    LOOKUPS = { country_id: Country, department_id: Department, job_title_id: JobTitle }.freeze

    def create
      employee = Employee.find(params[:employee_id])
      lookups, errors = find_lookups
      return render_errors(errors, status: :unprocessable_content) if errors.any?

      result = Employees::ChangeAssignment.call(
        employee: employee, effective_date: params[:effective_date], reason: params[:reason],
        lock_version: params[:lock_version], new_salary: params[:new_salary], **lookups
      )
      return render_failure(result) if result.failure?

      render_employee(employee.id, status: :created)
    end

    private

    # Omitted ids keep the employee's current value. An id that is given but
    # unknown is an error: passing nil on would silently mean "no change".
    def find_lookups
      lookups = {}
      errors = []
      LOOKUPS.each do |param, model|
        next if params[param].blank?

        record = model.find_by(id: params[param])
        if record
          lookups[model.model_name.singular.to_sym] = record
        else
          errors << "#{model.model_name.human} not found"
        end
      end
      [ lookups, errors ]
    end
  end
end
