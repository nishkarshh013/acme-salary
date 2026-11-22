import { Card, Descriptions, Empty, Flex, Result, Segmented, Skeleton, Tag, Typography } from 'antd'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import type { GroupBy } from '../api/insights'
import type { Country, CountryInsight } from '../api/types'
import { GroupInsightsTable } from '../insights/GroupInsightsTable'
import { InsightsNotes } from '../insights/InsightsNotes'
import { QueryErrorAlert } from '../insights/QueryErrorAlert'
import { GROUP_BY_OPTIONS, parseGroupBy } from '../insights/urls'
import { useCountryBreakdown, useCountryInsights } from '../insights/useInsights'
import { MoneyText } from '../money/MoneyText'

export function CountryInsightsPage() {
  const id = Number(useParams().id)
  const [searchParams, setSearchParams] = useSearchParams()
  const groupBy = parseGroupBy(searchParams.get('group_by'))
  const breakdown = useCountryBreakdown(id, groupBy)
  // The country's overall statistics are its row in the all-countries query.
  const countries = useCountryInsights()
  const overall = countries.data?.find((row) => row.country.id === id)

  const notFound =
    !Number.isInteger(id) || id <= 0 || (breakdown.error instanceof ApiError && breakdown.error.status === 404)
  if (notFound) {
    return <Result status="404" title="Country not found" extra={<Link to="/insights">Back to insights</Link>} />
  }

  const country: Country | undefined = breakdown.data?.country ?? overall?.country
  const changeGroupBy = (value: GroupBy) =>
    setSearchParams((current) => {
      const next = new URLSearchParams(current)
      next.set('group_by', value)
      return next
    })

  return (
    <>
      <Link to="/insights">← Insights</Link>
      {country ? (
        <Flex align="center" gap={12} wrap style={{ margin: '8px 0 16px' }}>
          <Typography.Title level={2} style={{ margin: 0 }}>
            {country.name}
          </Typography.Title>
          <Tag>Currency: {country.currency_code}</Tag>
        </Flex>
      ) : (
        <Skeleton active paragraph={false} style={{ margin: '8px 0 16px' }} />
      )}
      <InsightsNotes />

      <Card title="Overall" style={{ marginBottom: 16 }}>
        {countries.isError ? (
          <QueryErrorAlert
            title="Couldn’t load this country’s statistics"
            error={countries.error}
            onRetry={() => countries.refetch()}
          />
        ) : overall ? (
          <OverallStatistics overall={overall} />
        ) : (
          <Skeleton active paragraph={{ rows: 2 }} title={false} />
        )}
      </Card>

      <Card
        title="Breakdown"
        extra={
          <Segmented<GroupBy>
            aria-label="Group by"
            options={GROUP_BY_OPTIONS}
            value={groupBy}
            onChange={changeGroupBy}
          />
        }
      >
        {breakdown.isError ? (
          <QueryErrorAlert
            title="Couldn’t load the breakdown"
            error={breakdown.error}
            onRetry={() => breakdown.refetch()}
          />
        ) : breakdown.data?.groups.length === 0 ? (
          <Empty description={`No active employees in ${breakdown.data.country.name}`} />
        ) : (
          <GroupInsightsTable
            countryId={id}
            groupBy={groupBy}
            groups={breakdown.data?.groups}
            loading={breakdown.isFetching && !breakdown.data}
          />
        )}
      </Card>
    </>
  )
}

function OverallStatistics({ overall }: { overall: CountryInsight }) {
  return (
    <Descriptions
      column={{ xs: 1, sm: 2, lg: 4 }}
      items={[
        { key: 'headcount', label: 'Active headcount', children: overall.headcount },
        { key: 'median', label: 'Median salary', children: <MoneyText value={overall.median_salary} /> },
        { key: 'average', label: 'Average salary', children: <MoneyText value={overall.average_salary} /> },
        { key: 'min', label: 'Min salary', children: <MoneyText value={overall.min_salary} /> },
        { key: 'max', label: 'Max salary', children: <MoneyText value={overall.max_salary} /> },
        { key: 'total', label: 'Total payroll', children: <MoneyText value={overall.total_payroll} /> },
        {
          key: 'total_usd',
          label: 'Total payroll (USD)',
          children: <MoneyText value={overall.total_payroll_usd} stacked />,
        },
      ]}
    />
  )
}
