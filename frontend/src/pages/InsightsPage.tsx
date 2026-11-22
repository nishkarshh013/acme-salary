import { Card, Col, Row, Skeleton, Typography } from 'antd'
import type { ReactNode } from 'react'
import type { InsightsSummary } from '../api/types'
import { CountryInsightsTable } from '../insights/CountryInsightsTable'
import { DepartmentPayrollBars } from '../insights/DepartmentPayrollBars'
import { InsightsNotes } from '../insights/InsightsNotes'
import { QueryErrorAlert } from '../insights/QueryErrorAlert'
import { useCountryInsights, useInsightsSummary } from '../insights/useInsights'
import { formatConvertedMoney } from '../money/formatMoney'
import { ConvertedTitle } from '../money/MoneyText'
import { sharedLabel } from '../money/sharedLabel'

export function InsightsPage() {
  const summary = useInsightsSummary()
  const countries = useCountryInsights()
  // Shown once in the chart heading; a bar with a different label keeps it beside its amount.
  const barsLabel = summary.data ? sharedLabel(summary.data.by_department.map((row) => row.total_payroll_usd)) : null

  return (
    <>
      <Typography.Title level={2}>Insights</Typography.Title>
      <InsightsNotes />

      {summary.isError && (
        <QueryErrorAlert title="Couldn’t load the summary" error={summary.error} onRetry={() => summary.refetch()} />
      )}
      {!summary.isError && <SummaryCards summary={summary.data} />}

      <Card title="Countries" style={{ marginBottom: 16 }}>
        {countries.isError && (
          <QueryErrorAlert title="Couldn’t load countries" error={countries.error} onRetry={() => countries.refetch()} />
        )}
        <CountryInsightsTable countries={countries.data} loading={countries.isFetching && !countries.data} />
      </Card>

      {!summary.isError && (
        <Card title={<ConvertedTitle title="Payroll by department (USD)" label={barsLabel} />}>
          {summary.data ? (
            <DepartmentPayrollBars departments={summary.data.by_department} sharedLabel={barsLabel} />
          ) : (
            <Skeleton active paragraph={{ rows: 6 }} title={false} />
          )}
        </Card>
      )}
    </>
  )
}

function SummaryCards({ summary }: { summary: InsightsSummary | undefined }) {
  const payroll = summary && formatConvertedMoney(summary.total_payroll_usd)

  return (
    <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
      <Col xs={24} md={8}>
        <FigureCard title="Active headcount" loading={!summary}>
          {summary && <div className="insight-figure">{summary.headcount.toLocaleString()}</div>}
        </FigureCard>
      </Col>
      <Col xs={24} md={16}>
        <FigureCard title="Total payroll" loading={!payroll}>
          {payroll && (
            <>
              <div className="insight-figure">{payroll.text ?? '—'}</div>
              <Typography.Text type="secondary">{payroll.label}</Typography.Text>
            </>
          )}
        </FigureCard>
      </Col>
    </Row>
  )
}

function FigureCard({ title, loading, children }: { title: string; loading: boolean; children: ReactNode }) {
  return (
    <Card title={title} style={{ height: '100%' }}>
      {loading ? <Skeleton active paragraph={{ rows: 1 }} title={false} /> : children}
    </Card>
  )
}
