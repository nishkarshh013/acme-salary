import { screen, waitFor, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import type { ConvertedMoney, CountryBreakdownResponse, CountryInsight, GroupInsight, InsightsSummary } from '../api/types'
import { commonRoutes, engineer, engineering, france, germany, india, sales, seniorEngineer } from '../test/employeeFixtures'
import { mockFetch, type MockResponse } from '../test/mockFetch'
import { renderApp } from '../test/renderApp'
import { setupUser } from '../test/user'
import { ACTIVE_ONLY_NOTE, ROUNDING_NOTE } from './InsightsNotes'

const LABEL = 'USD, converted at fixed rates as of 2026-10-01'
const MISSING_RATE = 'USD conversion unavailable: an exchange rate is missing'

const usd = (amount: string | null): ConvertedMoney => ({
  amount,
  currency: 'USD',
  converted: true,
  rates_as_of: amount === null ? null : '2026-10-01',
  label: amount === null ? MISSING_RATE : LABEL,
})
const eur = (amount: string) => ({ amount, currency: 'EUR' })

const germanyRow: CountryInsight = {
  country: germany,
  headcount: 3,
  min_salary: eur('60000.00'),
  median_salary: eur('70000.00'),
  average_salary: eur('73333.33'),
  max_salary: eur('90000.00'),
  total_payroll: eur('220000.00'),
  total_payroll_usd: usd('237600.00'),
}
// No active employees: no statistics, a zero total.
const franceRow: CountryInsight = {
  country: france,
  headcount: 0,
  min_salary: null,
  median_salary: null,
  average_salary: null,
  max_salary: null,
  total_payroll: eur('0.00'),
  total_payroll_usd: usd('0.00'),
}

const summary: InsightsSummary = {
  headcount: 10000,
  total_payroll_usd: usd('1234567890.12'),
  by_country: [],
  by_department: [
    { department: engineering, headcount: 2, total_payroll_usd: usd('200000.00') },
    { department: sales, headcount: 1, total_payroll_usd: usd('50000.00') },
  ],
}

function group(id: number, name: string, overrides: Partial<GroupInsight> = {}): GroupInsight {
  return {
    group: { id, name },
    headcount: 1,
    min_salary: eur('70000.00'),
    median_salary: eur('70000.00'),
    average_salary: eur('70000.00'),
    max_salary: eur('70000.00'),
    total_payroll: eur('70000.00'),
    ...overrides,
  }
}

const byDepartment: CountryBreakdownResponse = {
  country: germany,
  group_by: 'department',
  groups: [
    // 9,000 sorts below 10,000 as a number, though not as text.
    group(engineering.id, engineering.name, { headcount: 2, max_salary: eur('10000.00') }),
    group(sales.id, sales.name, { max_salary: eur('9000.00') }),
  ],
}
const byJobTitle: CountryBreakdownResponse = {
  country: germany,
  group_by: 'job_title',
  groups: [group(engineer.id, engineer.name), group(seniorEngineer.id, seniorEngineer.name)],
}

function setup(path: string, routes: Record<string, MockResponse> = {}) {
  const fetchMock = mockFetch({
    ...commonRoutes,
    'GET /api/insights/summary': { status: 200, body: summary },
    'GET /api/insights/countries': { status: 200, body: { countries: [franceRow, germanyRow] } },
    'GET /api/insights/countries/2?group_by=department': { status: 200, body: byDepartment },
    'GET /api/insights/countries/2?group_by=job_title': { status: 200, body: byJobTitle },
    'GET /api/insights/countries/3?group_by=department': {
      status: 200,
      body: { country: france, group_by: 'department', groups: [] },
    },
    'GET /api/employees': {
      status: 200,
      body: { employees: [], meta: { page: 1, per_page: 25, total_count: 0, total_pages: 0 } },
    },
    ...routes,
  })
  const { location } = renderApp(path)
  const requests = () => fetchMock.mock.calls.map(([url]) => String(url))
  return { location, requests }
}

const countryRow = (name: string) => screen.getByRole('row', { name: new RegExp(`^${name}`) })
const columnHeader = (name: string) => screen.getByRole('columnheader', { name })
const usdHeader = () => screen.getByRole('columnheader', { name: /^Total payroll \(USD\)/ })
/** The text of one column, top to bottom (data rows only, not the table's hidden measuring row). */
function columnTexts(index: number) {
  return Array.from(document.querySelectorAll('tbody tr[data-row-key]')).map(
    (row) => within(row as HTMLElement).getAllByRole('cell')[index]?.textContent,
  )
}
/** The department chart's card heading, which also carries the shared label. */
function chartHeading() {
  const head = Array.from(document.querySelectorAll<HTMLElement>('.ant-card-head-title')).find((el) =>
    el.textContent?.startsWith('Payroll by department (USD)'),
  )
  if (!head) throw new Error('No department chart')
  return head
}
/** The Ant Design card with this title. */
function card(title: string) {
  const head = Array.from(document.querySelectorAll('.ant-card-head-title')).find((el) => el.textContent === title)
  if (!head) throw new Error(`No card titled ${title}`)
  return head.closest('.ant-card') as HTMLElement
}

describe('Insights overview', () => {
  it('shows the headcount and USD payroll cards, the country table and the department bars', async () => {
    setup('/insights')

    expect(await screen.findByText('10,000')).toBeInTheDocument()
    expect(screen.getByText('$1,234,567,890.12')).toBeInTheDocument()
    expect(within(card('Total payroll')).getByText(LABEL)).toBeInTheDocument() // beside the standalone total
    expect(screen.getByText(ACTIVE_ONLY_NOTE)).toBeInTheDocument()
    expect(screen.getByText(ROUNDING_NOTE)).toBeInTheDocument()

    const germanyCells = within(await screen.findByRole('row', { name: /^Germany/ })).getAllByRole('cell')
    expect(germanyCells.map((cell) => cell.textContent)).toEqual([
      'Germany', 'EUR', '3', '€60,000.00', '€70,000.00', '€73,333.33', '€90,000.00', '€220,000.00',
      '$237,600.00',
    ])
    // The shared label is shown once, in the column header, not under every amount.
    expect(within(usdHeader()).getByText(LABEL)).toBeInTheDocument()
    for (const row of document.querySelectorAll('tbody tr[data-row-key]')) expect(row).not.toHaveTextContent(LABEL)
    // France has no active employees: dashes, not zeros, for the statistics.
    expect(within(countryRow('France')).getAllByText('—')).toHaveLength(4)

    const bars = screen.getByRole('list', { name: 'Payroll by department' })
    expect(within(bars).getByText('Engineering')).toBeInTheDocument()
    expect(within(bars).getByText('$200,000.00')).toBeInTheDocument()
    expect(within(bars).getByText('$50,000.00')).toBeInTheDocument()
    expect(screen.getByTestId(`bar-${engineering.id}`)).toHaveStyle({ width: '100%' })
    expect(screen.getByTestId(`bar-${sales.id}`)).toHaveStyle({ width: '25%' })
    // The shared label is shown once, in the chart heading, not beside every bar.
    expect(within(chartHeading()).getByText(LABEL)).toBeInTheDocument()
    expect(within(bars).queryByText(LABEL)).not.toBeInTheDocument()
  })

  it('labels every converted amount, and shows the label alone when a rate is missing', async () => {
    const indiaRow: CountryInsight = {
      ...germanyRow,
      country: india,
      total_payroll: { amount: '5000000.00', currency: 'INR' },
      total_payroll_usd: usd(null),
    }
    setup('/insights', {
      'GET /api/insights/countries': { status: 200, body: { countries: [franceRow, germanyRow, indiaRow] } },
      'GET /api/insights/summary': {
        status: 200,
        body: {
          ...summary,
          total_payroll_usd: usd(null),
          by_department: [
            { department: engineering, headcount: 2, total_payroll_usd: usd('200000.00') },
            { department: sales, headcount: 1, total_payroll_usd: usd(null) },
            { department: { id: 3, name: 'Support' }, headcount: 1, total_payroll_usd: usd('40000.00') },
          ],
        },
      },
    })

    await screen.findByText('10,000')
    const payrollCard = card('Total payroll')
    expect(within(payrollCard).getByText(MISSING_RATE)).toBeInTheDocument()
    expect(within(payrollCard).queryByText(/\$/)).not.toBeInTheDocument()

    // In the chart, the label most bars share goes in the heading; the bar
    // whose rate is missing keeps its own label, with no amount and no bar.
    const bars = screen.getByRole('list', { name: 'Payroll by department' })
    expect(within(chartHeading()).getByText(LABEL)).toBeInTheDocument()
    expect(within(bars).queryByText(LABEL)).not.toBeInTheDocument()
    const salesBar = within(bars).getByText('Sales').closest('li') as HTMLElement
    expect(salesBar).toHaveTextContent(MISSING_RATE)
    expect(salesBar).not.toHaveTextContent('$')
    expect(screen.getByTestId(`bar-${sales.id}`)).toHaveStyle({ width: '0%' })

    // In the table, the label most rows share goes in the header; a row whose
    // rate is missing keeps its own label in its cell, with no amount.
    await screen.findByRole('row', { name: /^Germany/ })
    expect(within(usdHeader()).getByText(LABEL)).toBeInTheDocument()
    expect(within(countryRow('Germany')).queryByText(LABEL)).not.toBeInTheDocument()
    const indiaUsd = within(countryRow('India')).getAllByRole('cell').at(-1) as HTMLElement
    expect(indiaUsd).toHaveTextContent(MISSING_RATE)
    expect(indiaUsd).not.toHaveTextContent('$')
  })

  it('opens a country’s page when its row is clicked', async () => {
    const { location, requests } = setup('/insights')
    const user = setupUser()

    await user.click(within(await screen.findByRole('row', { name: /^Germany/ })).getByText('€220,000.00'))

    expect(await screen.findByRole('heading', { name: 'Germany' })).toBeInTheDocument()
    expect(location()).toBe('/insights/countries/2')
    expect(requests()).toContain('/api/insights/countries/2?group_by=department')
  })

  it('shows the API’s message when the summary fails, and loads it again on Retry', async () => {
    setup('/insights', { 'GET /api/insights/summary': { status: 500, body: { errors: ['Statistics are unavailable'] } } })

    expect(await screen.findByText('Statistics are unavailable')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })
})

describe('Country drill-down', () => {
  it('shows the country, its currency and overall statistics, then a row per department', async () => {
    setup('/insights/countries/2')

    expect(await screen.findByRole('heading', { name: 'Germany' })).toBeInTheDocument()
    expect(screen.getByText('Currency: EUR')).toBeInTheDocument()
    const overall = card('Overall')
    expect(await within(overall).findByText('€73,333.33')).toBeInTheDocument()
    expect(within(overall).getByText(LABEL)).toBeInTheDocument()

    expect(await screen.findByRole('link', { name: 'Engineering' })).toBeInTheDocument()
    expect(columnHeader('Department')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Sales' })).toBeInTheDocument()
  })

  it('switches to job titles, keeping the choice in the URL and asking the API for it', async () => {
    const { location, requests } = setup('/insights/countries/2')
    const user = setupUser()
    await screen.findByRole('link', { name: 'Engineering' })

    await user.click(within(screen.getByRole('radiogroup', { name: 'Group by' })).getByText('Job title'))

    expect(await screen.findByRole('link', { name: 'Senior Engineer' })).toBeInTheDocument()
    expect(columnHeader('Job title')).toBeInTheDocument()
    expect(location()).toBe('/insights/countries/2?group_by=job_title')
    expect(requests()).toContain('/api/insights/countries/2?group_by=job_title')
  })

  it('reads the grouping from the URL', async () => {
    setup('/insights/countries/2?group_by=job_title')

    expect(await screen.findByRole('link', { name: 'Senior Engineer' })).toBeInTheDocument()
  })

  it('sorts on the client by any column, comparing amounts as numbers', async () => {
    const { requests } = setup('/insights/countries/2')
    const user = setupUser()
    await screen.findByRole('link', { name: 'Engineering' })
    const requestCount = requests().length

    await user.click(within(columnHeader('Max')).getByText('Max'))
    expect(columnTexts(0)).toEqual(['Sales', 'Engineering']) // €9,000 before €10,000

    await user.click(within(columnHeader('Max')).getByText('Max'))
    expect(columnTexts(0)).toEqual(['Engineering', 'Sales'])

    await user.click(within(columnHeader('Headcount')).getByText('Headcount'))
    expect(columnTexts(0)).toEqual(['Sales', 'Engineering'])
    expect(requests()).toHaveLength(requestCount) // no request: sorted in the browser
  })

  it('links each row to the employee list filtered to that country and group', async () => {
    const { location, requests } = setup('/insights/countries/2?group_by=job_title')
    const user = setupUser()

    const link = await screen.findByRole('link', { name: 'Senior Engineer' })
    expect(link).toHaveAttribute('href', `/employees?country_id=2&job_title_id=${seniorEngineer.id}`)

    await user.click(link)

    expect(await screen.findByRole('heading', { name: 'Employees' })).toBeInTheDocument()
    expect(location()).toBe(`/employees?country_id=2&job_title_id=${seniorEngineer.id}`)
    await waitFor(() =>
      expect(requests()).toContainEqual(expect.stringMatching(/^\/api\/employees\?country_id=2&job_title_id=2&/)),
    )
  })

  it('links department rows with department_id', async () => {
    setup('/insights/countries/2')

    expect(await screen.findByRole('link', { name: 'Sales' })).toHaveAttribute(
      'href',
      `/employees?country_id=2&department_id=${sales.id}`,
    )
  })

  it('shows an empty state for a country with no active employees', async () => {
    setup('/insights/countries/3')

    expect(await screen.findByText('No active employees in France')).toBeInTheDocument()
    const overall = card('Overall')
    expect(await within(overall).findByText('€0.00')).toBeInTheDocument()
    expect(screen.queryByRole('columnheader', { name: 'Department' })).not.toBeInTheDocument()
  })

  it('says so when the country doesn’t exist', async () => {
    setup('/insights/countries/99', {
      'GET /api/insights/countries/99?group_by=department': { status: 404, body: { errors: ['Not found'] } },
    })

    expect(await screen.findByText('Country not found')).toBeInTheDocument()
  })
})
