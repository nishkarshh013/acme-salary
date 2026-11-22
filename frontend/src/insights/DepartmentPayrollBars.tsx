import { Empty } from 'antd'
import type { InsightsSummary } from '../api/types'
import { approximateAmount, barPercent } from '../money/approximateAmount'
import { MoneyText } from '../money/MoneyText'
import './DepartmentPayrollBars.css'

interface Props {
  departments: InsightsSummary['by_department']
  /** The label shown once in the chart heading; only a bar whose label differs shows its own. */
  sharedLabel: string | null
}

/**
 * Payroll per department in USD as horizontal bars, scaled to the largest.
 * The bar is only a picture; the exact amount is the text beside it, with
 * its label when that differs from the chart heading's. A department whose
 * total couldn't be converted gets no bar.
 */
export function DepartmentPayrollBars({ departments, sharedLabel }: Props) {
  if (departments.length === 0) return <Empty description="No departments" />

  const largest = Math.max(0, ...departments.map((row) => approximateAmount(row.total_payroll_usd) ?? 0))

  return (
    <ul className="payroll-bars" aria-label="Payroll by department">
      {departments.map((row) => (
        <li key={row.department.id} className="payroll-bars__row">
          <span className="payroll-bars__name">{row.department.name}</span>
          <div className="payroll-bars__track" aria-hidden="true">
            <div
              className="payroll-bars__bar"
              data-testid={`bar-${row.department.id}`}
              style={{ width: `${barPercent(row.total_payroll_usd, largest)}%` }}
            />
          </div>
          <span className="payroll-bars__amount">
            <MoneyText value={row.total_payroll_usd} sharedLabel={sharedLabel} stacked />
          </span>
        </li>
      ))}
    </ul>
  )
}
