module Api
  class EmployeesController < ApplicationController
    include EmployeeRendering

    # GET /api/employees
    def index
      result = Employees::Search.call(search_params)
      return render_failure(result) if result.failure?

      page = result.record
      render json: {
        employees: page.employees.map { |employee| EmployeeSerializer.call(employee) },
        meta: { page: page.page, per_page: page.per_page, total_count: page.total_count, total_pages: page.total_pages }
      }
    end

    # GET /api/employees/:id
    def show
      render_employee(params[:id])
    end

    # POST /api/employees
    def create
      result = Employees::Hire.call(attributes: hire_params.except(:salary, :reason),
                                    salary: hire_params[:salary],
                                    reason: hire_params[:reason].presence || "Hired")
      return render_failure(result) if result.failure?

      render_employee(result.record.id, status: :created)
    end

    # PATCH /api/employees/:id
    def update
      employee = Employee.find(params[:id])
      result = Employees::Update.call(employee: employee, attributes: update_params.except(:lock_version),
                                      lock_version: update_params[:lock_version])
      return render_failure(result) if result.failure?

      render_employee(employee.id)
    end

    private

    def search_params
      params.permit(:q, :country_id, :department_id, :job_title_id, :status, :sort, :direction, :page, :per_page)
    end

    # employee_code is permitted only so Employees::Hire can ignore it: codes
    # are always generated, and sending one isn't an error.
    def hire_params
      params.permit(:first_name, :last_name, :email, :hire_date, :country_id, :department_id, :job_title_id,
                    :salary, :reason, :employee_code)
    end

    # Locked fields are permitted too, so Employees::Update can reject them
    # with a message instead of strong parameters dropping them silently.
    def update_params
      params.except(:id).permit(:lock_version, *Employees::Update::EDITABLE, *Employees::Update::LOCKED.keys)
    end
  end
end
