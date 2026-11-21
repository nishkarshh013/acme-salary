# Salary statistics for the insights endpoints. Every aggregate runs in SQL;
# only active employees count.
#
# Local-currency statistics are only computed within one currency (per
# country, or per group inside one country). Cross-currency figures are
# totals converted to USD with the fixed exchange-rate table: an org-wide
# average or median would mix salary markets, so there are none.
#
# Median: percentile_cont works in double precision, so the median is cast
# back to numeric and rounded to 2 decimals; that is exact to the cent for
# amounts far beyond any salary. Everything else is numeric throughout.
class SalaryStatistics
  GROUPS = { "department" => "departments", "job_title" => "job_titles" }.freeze

  # Rows are plain hashes; money values are BigDecimal in the row's currency.
  STATISTICS = {
    headcount: "COUNT(e.id)",
    min: "MIN(e.current_salary)",
    max: "MAX(e.current_salary)",
    average: "ROUND(AVG(e.current_salary), 2)",
    median: "ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY e.current_salary))::numeric, 2)",
    total: "COALESCE(SUM(e.current_salary), 0)"
  }.freeze

  # Converted to USD per employee and summed exactly, rounded once. Null if
  # any employee's currency has no rate, rather than silently undercounting.
  # rates_as_of is the oldest rate used, so the label never overstates freshness.
  CONVERTED_TOTAL = {
    total_usd: "CASE WHEN COUNT(e.id) FILTER (WHERE r.id IS NULL) > 0 THEN NULL " \
               "ELSE ROUND(COALESCE(SUM(e.current_salary * r.rate_to_usd), 0), 2) END",
    rates_as_of: "MIN(r.as_of)"
  }.freeze

  ACTIVE_EMPLOYEES = "employees e ON e.%<key>s = %<table>s.id AND e.status = 'active'".freeze
  RATES = "LEFT JOIN exchange_rates r ON r.currency_code = e.salary_currency".freeze

  # One row per country (countries with no active employees included, with
  # headcount 0), in local currency, plus the total converted to USD.
  def self.by_country
    relation = Country.joins("LEFT JOIN #{format(ACTIVE_EMPLOYEES, key: 'country_id', table: 'countries')}")
                      .joins(RATES)
                      .group("countries.id")
                      .order("countries.name")
    pluck_rows(relation, id: "countries.id", code: "countries.code", name: "countries.name",
                         currency: "countries.currency_code", **STATISTICS, **CONVERTED_TOTAL)
  end

  # Statistics per department or job title inside one country, in that
  # country's currency. Only groups with active employees are listed.
  # Returns a ServiceResult; an unknown group_by is a failure.
  def self.within_country(country, group_by:)
    table = GROUPS[group_by]
    return ServiceResult.failure("group_by must be one of: #{GROUPS.keys.join(', ')}") if table.nil?

    relation = Employee.from("employees e")
                       .joins("JOIN #{table} g ON g.id = e.#{group_by}_id")
                       .where("e.country_id = ? AND e.status = 'active'", country.id)
                       .group("g.id")
                       .order("g.name")
    ServiceResult.success(pluck_rows(relation, id: "g.id", name: "g.name", **STATISTICS))
  end

  # Org-wide headcount and USD totals, overall, by country and by department.
  def self.summary
    {
      **pluck_rows(Employee.from("employees e").joins(RATES).where("e.status = 'active'"),
                   headcount: "COUNT(e.id)", **CONVERTED_TOTAL).first,
      by_country: by_country.map { |row| row.slice(:id, :code, :name, :headcount, :total_usd, :rates_as_of) },
      by_department: by_department
    }
  end

  # Departments span countries, so only converted totals are meaningful.
  def self.by_department
    relation = Department.joins("LEFT JOIN #{format(ACTIVE_EMPLOYEES, key: 'department_id', table: 'departments')}")
                         .joins(RATES)
                         .group("departments.id")
                         .order("departments.name")
    pluck_rows(relation, id: "departments.id", name: "departments.name", headcount: "COUNT(e.id)", **CONVERTED_TOTAL)
  end

  # pluck casts each column to its database type (integer, numeric, date).
  def self.pluck_rows(relation, columns)
    relation.pluck(*columns.values.map { |sql| Arel.sql(sql) }).map { |values| columns.keys.zip(values).to_h }
  end
  private_class_method :by_department, :pluck_rows
end
