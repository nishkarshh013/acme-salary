# One employee with lock_version (sent back with every edit) and their
# history timeline, newest first.
class EmployeeDetailSerializer
  def self.call(employee)
    EmployeeSerializer.call(employee).merge(
      lock_version: employee.lock_version,
      timeline: Employees::Timeline.call(employee).map { |entry| entry_json(entry) }
    )
  end

  def self.entry_json(entry)
    record = entry.record
    common = { type: entry.kind.to_s, id: record.id, effective_date: record.effective_date.iso8601,
               reason: record.reason, recorded_at: record.created_at.iso8601 }

    case entry.kind
    when :salary_revision
      common.merge(
        amount: MoneySerializer.call(record.amount, record.currency),
        previous_amount: MoneySerializer.call(record.previous_amount, record.previous_currency)
      )
    when :assignment
      common.merge(assignment_json(record).merge(previous: entry.previous && assignment_json(entry.previous)))
    end
  end

  def self.assignment_json(assignment)
    {
      country: CountrySerializer.call(assignment.country),
      department: LookupSerializer.call(assignment.department),
      job_title: LookupSerializer.call(assignment.job_title)
    }
  end
  private_class_method :entry_json, :assignment_json
end
