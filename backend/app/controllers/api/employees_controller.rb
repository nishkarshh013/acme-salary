module Api
  class EmployeesController < ApplicationController
    # GET /api/employees
    def index
      result = Employees::Search.call(search_params)
      return render_errors(result.errors, status: :unprocessable_content) if result.failure?

      page = result.record
      render json: {
        employees: page.employees.map { |employee| EmployeeSerializer.call(employee) },
        meta: { page: page.page, per_page: page.per_page, total_count: page.total_count, total_pages: page.total_pages }
      }
    end

    # GET /api/employees/:id
    def show
      employee = Employee.includes(:country, :department, :job_title, :salary_revisions,
                                   employee_assignments: %i[ country department job_title ])
                         .find(params[:id])
      render json: { employee: EmployeeDetailSerializer.call(employee) }
    end

    private

    def search_params
      params.permit(:q, :country_id, :department_id, :job_title_id, :status, :sort, :direction, :page, :per_page)
    end
  end
end
