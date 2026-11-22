import type { ColumnsType } from 'antd/es/table/interface'
import type { Money, SalaryStatistics } from '../api/types'
import { compareAmounts } from '../money/approximateAmount'
import { MoneyText } from '../money/MoneyText'

type MoneyKey = 'min_salary' | 'median_salary' | 'average_salary' | 'max_salary' | 'total_payroll'

const MONEY_COLUMNS: { key: MoneyKey; title: string }[] = [
  { key: 'min_salary', title: 'Min' },
  { key: 'median_salary', title: 'Median' },
  { key: 'average_salary', title: 'Average' },
  { key: 'max_salary', title: 'Max' },
  { key: 'total_payroll', title: 'Total payroll' },
]

/**
 * Headcount, min, median, average, max and total payroll, in local
 * currency. With `sortable`, each column sorts on the client (amounts are
 * compared with approximateAmount, which is only for ordering).
 */
export function statisticColumns<T extends SalaryStatistics>(sortable: boolean): ColumnsType<T> {
  return [
    {
      key: 'headcount',
      title: 'Headcount',
      align: 'right',
      sorter: sortable ? (a, b) => a.headcount - b.headcount : undefined,
      render: (_, row) => row.headcount,
    },
    ...MONEY_COLUMNS.map(({ key, title }) => ({
      key,
      title,
      align: 'right' as const,
      sorter: sortable ? (a: T, b: T) => compareAmounts(a[key] as Money | null, b[key] as Money | null) : undefined,
      render: (_: unknown, row: T) => <MoneyText value={row[key]} />,
    })),
  ]
}
