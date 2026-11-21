# Statistics for one group, all in a single local currency. The extremes,
# average and median are nil for a group with no active employees.
class SalaryStatisticsSerializer
  def self.call(row, currency)
    {
      headcount: row[:headcount],
      min_salary: MoneySerializer.call(row[:min], currency),
      max_salary: MoneySerializer.call(row[:max], currency),
      average_salary: MoneySerializer.call(row[:average], currency),
      median_salary: MoneySerializer.call(row[:median], currency),
      total_payroll: MoneySerializer.call(row[:total], currency)
    }
  end
end
