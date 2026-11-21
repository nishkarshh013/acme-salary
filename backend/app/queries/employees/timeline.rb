module Employees
  # An employee's salary revisions and assignments merged into one history,
  # newest first. Each assignment carries the one before it, so the UI can
  # show what changed; revisions already store their previous amount.
  # Works on preloaded associations; the histories are small per employee.
  class Timeline
    Entry = Data.define(:kind, :record, :previous)

    # On the same date and timestamp, the assignment is listed as the older
    # entry (ChangeAssignment saves it before the revision).
    KIND_ORDER = { assignment: 0, salary_revision: 1 }.freeze

    def self.call(employee) = new(employee).call

    def initialize(employee)
      @employee = employee
    end

    def call
      (assignment_entries + revision_entries)
        .sort_by { |entry| [ entry.record.effective_date, entry.record.created_at, KIND_ORDER[entry.kind], entry.record.id ] }
        .reverse
    end

    private

    attr_reader :employee

    def assignment_entries
      assignments = employee.employee_assignments.sort_by { |a| [ a.effective_date, a.created_at, a.id ] }
      assignments.each_with_index.map do |assignment, index|
        Entry.new(kind: :assignment, record: assignment, previous: index.zero? ? nil : assignments[index - 1])
      end
    end

    def revision_entries
      employee.salary_revisions.map { |revision| Entry.new(kind: :salary_revision, record: revision, previous: nil) }
    end
  end
end
