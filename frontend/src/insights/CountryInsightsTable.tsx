import { Table } from 'antd'
import type { ColumnsType } from 'antd/es/table/interface'
import { Link, useNavigate } from 'react-router-dom'
import type { CountryInsight } from '../api/types'
import { ConvertedTitle, MoneyText } from '../money/MoneyText'
import { sharedLabel } from '../money/sharedLabel'
import { statisticColumns } from './statisticColumns'
import { countryInsightsPath } from './urls'

interface Props {
  countries: CountryInsight[] | undefined
  loading: boolean
}

/** One row per country, in local currency plus total payroll in USD. A row opens the country's page. */
export function CountryInsightsTable({ countries, loading }: Props) {
  const navigate = useNavigate()
  // Shown once in the header; a row with a different label keeps it in its cell.
  const usdLabel = sharedLabel((countries ?? []).map((row) => row.total_payroll_usd))

  const columns: ColumnsType<CountryInsight> = [
    {
      key: 'country',
      title: 'Country',
      render: (_, row) => <Link to={countryInsightsPath(row.country.id)}>{row.country.name}</Link>,
    },
    { key: 'currency', title: 'Currency', render: (_, row) => row.country.currency_code },
    ...statisticColumns<CountryInsight>(false),
    {
      key: 'total_payroll_usd',
      title: <ConvertedTitle title="Total payroll (USD)" label={usdLabel} />,
      align: 'right',
      render: (_, row) => <MoneyText value={row.total_payroll_usd} sharedLabel={usdLabel} stacked />,
    },
  ]

  return (
    <Table<CountryInsight>
      rowKey={(row) => row.country.id}
      columns={columns}
      dataSource={countries}
      loading={loading}
      pagination={false}
      scroll={{ x: 'max-content' }}
      locale={{ emptyText: loading ? 'Loading countries…' : 'No countries' }}
      onRow={(row) => ({
        // The country link handles its own clicks (so Ctrl/Cmd-click opens a new tab).
        onClick: (event) => {
          if (!(event.target as HTMLElement).closest('a')) navigate(countryInsightsPath(row.country.id))
        },
        style: { cursor: 'pointer' },
      })}
    />
  )
}
