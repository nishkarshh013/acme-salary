import { Empty, Timeline, Typography } from 'antd'
import type { AssignmentEntry, AssignmentSnapshot, SalaryRevisionEntry, TimelineEntry } from '../../api/types'
import { formatDate } from '../../format/formatDate'
import { formatMoney } from '../../money/formatMoney'

/** Salary revisions and assignment changes, newest first, as the API orders them. */
export function EmployeeTimeline({ entries }: { entries: TimelineEntry[] }) {
  if (entries.length === 0) return <Empty description="No history recorded" />

  return (
    <Timeline
      items={entries.map((entry) => ({
        key: `${entry.type}-${entry.id}`,
        color: entry.type === 'salary_revision' ? 'green' : 'blue',
        title: formatDate(entry.effective_date),
        content: (
          <div data-testid="timeline-entry">
            {entry.type === 'salary_revision' ? <SalaryChange entry={entry} /> : <AssignmentChange entry={entry} />}
            <Typography.Text type="secondary">{entry.reason}</Typography.Text>
          </div>
        ),
      }))}
    />
  )
}

function SalaryChange({ entry }: { entry: SalaryRevisionEntry }) {
  if (!entry.previous_amount) {
    return <div>Starting salary: {formatMoney(entry.amount)}</div>
  }
  const currencyChanged = entry.previous_amount.currency !== entry.amount.currency
  return (
    <div>
      Salary: {formatMoney(entry.previous_amount)} → {formatMoney(entry.amount)}
      {currencyChanged && ` (${entry.previous_amount.currency} → ${entry.amount.currency})`}
    </div>
  )
}

const FIELDS: { label: string; name: (snapshot: AssignmentSnapshot) => string }[] = [
  { label: 'Country', name: (snapshot) => snapshot.country.name },
  { label: 'Department', name: (snapshot) => snapshot.department.name },
  { label: 'Job title', name: (snapshot) => snapshot.job_title.name },
]

function AssignmentChange({ entry }: { entry: AssignmentEntry }) {
  const { previous } = entry
  if (!previous) {
    return (
      <div>
        Hired as {entry.job_title.name}, {entry.department.name}, {entry.country.name}
      </div>
    )
  }
  const changes = FIELDS.filter(({ name }) => name(previous) !== name(entry))
  if (changes.length === 0) return <div>Assignment recorded (no change)</div>
  return (
    <>
      {changes.map(({ label, name }) => (
        <div key={label}>
          {label}: {name(previous)} → {name(entry)}
        </div>
      ))}
    </>
  )
}
