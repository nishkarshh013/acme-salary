# An employee in the list. Expects country, department and job title preloaded.
class EmployeeSerializer
  def self.call(employee)
    {
      id: employee.id,
      employee_code: employee.employee_code,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      hire_date: employee.hire_date.iso8601,
      status: employee.status,
      country: CountrySerializer.call(employee.country),
      department: LookupSerializer.call(employee.department),
      job_title: LookupSerializer.call(employee.job_title),
      current_salary: MoneySerializer.call(employee.current_salary, employee.salary_currency)
    }
  end
end
