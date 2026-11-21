# Every employee endpoint answers with the full employee, so the client gets
# the new lock_version and timeline after a write.
module EmployeeRendering
  extend ActiveSupport::Concern

  private

  def render_employee(id, status: :ok)
    render json: { employee: EmployeeDetailSerializer.call(Employees::Detail.find(id)) }, status: status
  end
end
