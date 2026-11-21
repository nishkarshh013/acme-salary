module Employees
  # One employee with everything the detail view and its timeline need,
  # preloaded. Raises ActiveRecord::RecordNotFound for an unknown id.
  class Detail
    def self.find(id)
      Employee.includes(:country, :department, :job_title, :salary_revisions,
                        employee_assignments: %i[ country department job_title ])
              .find(id)
    end
  end
end
