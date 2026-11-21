import { act, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { Employee, EmployeesPage } from '../api/types'
import { mockFetch, type MockResponse } from '../test/mockFetch'
import { renderApp } from '../test/renderApp'
import { SEARCH_DEBOUNCE_MS } from './EmployeeSearchBox'
import { SALARY_SORT_HINT } from './EmployeesTable'

const india = { id: 1, code: 'IN', name: 'India', currency_code: 'INR' }
const germany = { id: 2, code: 'DE', name: 'Germany', currency_code: 'EUR' }

function employee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 1,
    employee_code: 'EMP00001',
    first_name: 'Asha',
    last_name: 'Rao',
    email: 'asha.rao@acme.test',
    hire_date: '2020-01-15',
    status: 'active',
    country: india,
    department: { id: 1, name: 'Engineering' },
    job_title: { id: 1, name: 'Engineer' },
    current_salary: { amount: '2000000.50', currency: 'INR' },
    ...overrides,
  }
}

function page(employees: Employee[], total = employees.length): EmployeesPage {
  return { employees, meta: { page: 1, per_page: 25, total_count: total, total_pages: Math.ceil(total / 25) } }
}

function setup(path: string, employeesResponse: MockResponse | MockResponse[] = { status: 200, body: page([employee()]) }) {
  const fetchMock = mockFetch({
    'GET /api/session': { status: 200, body: { user: { id: 1, email_address: 'hr@acme.test' } } },
    'GET /api/countries': { status: 200, body: { countries: [germany, india] } },
    'GET /api/departments': { status: 200, body: { departments: [{ id: 1, name: 'Engineering' }] } },
    'GET /api/job_titles': { status: 200, body: { job_titles: [{ id: 1, name: 'Engineer' }] } },
    'GET /api/employees': employeesResponse,
  })
  renderApp(path)

  /** The query parameters of every /api/employees request so far. */
  const employeeRequests = () =>
    fetchMock.mock.calls
      .map(([url]) => String(url))
      .filter((url) => url.startsWith('/api/employees?'))
      .map((url) => Object.fromEntries(new URL(url, 'http://localhost').searchParams))

  return { employeeRequests }
}

// The table also renders a hidden measuring header; the column header role finds the real one.
function salaryHeader() {
  return screen.getByRole('columnheader', { name: 'Current salary' })
}

describe('Employees page', () => {
  it('renders rows from the API response, with the total count', async () => {
    setup('/employees', {
      status: 200,
      body: page(
        [
          employee(),
          employee({
            id: 2, employee_code: 'EMP00002', first_name: 'Ben', last_name: 'Iyer', status: 'inactive', country: germany,
            current_salary: { amount: '65000.25', currency: 'EUR' },
          }),
        ],
        2,
      ),
    })

    const row = (await screen.findByText('EMP00002')).closest('tr') as HTMLElement
    expect(within(row).getByText('Ben Iyer')).toBeInTheDocument()
    expect(within(row).getByText('Germany')).toBeInTheDocument()
    expect(within(row).getByText(/65,000\.25/)).toBeInTheDocument()
    expect(within(row).getByText('Inactive')).toBeInTheDocument()
    expect(screen.getByText('Asha Rao')).toBeInTheDocument()
    expect(screen.getByText('1–2 of 2 employees')).toBeInTheDocument()
  })

  it('asks for active employees, sorted by the API default, on the first page by default', async () => {
    const { employeeRequests } = setup('/employees')

    await screen.findByText('EMP00001')
    expect(employeeRequests()).toEqual([{ status: 'active', page: '1', per_page: '25' }])
  })

  it('takes its initial state from the URL', async () => {
    const { employeeRequests } = setup(
      '/employees?q=rao&country_id=1&status=all&sort=current_salary&direction=desc&page=2&per_page=50',
    )

    await screen.findByText('EMP00001')
    expect(employeeRequests()[0]).toEqual({
      q: 'rao', country_id: '1', status: 'all', sort: 'current_salary', direction: 'desc', page: '2', per_page: '50',
    })
    expect(screen.getByRole('searchbox', { name: 'Search employees' })).toHaveValue('rao')
    expect(screen.getByRole('radio', { name: 'All' })).toBeChecked()
    expect(salaryHeader()).toHaveAttribute('aria-sort', 'descending')
  })

  describe('search', () => {
    afterEach(() => vi.useRealTimers())

    it('sends one request after the user stops typing, not one per keystroke', async () => {
      const { employeeRequests } = setup('/employees')
      await screen.findByText('EMP00001')
      const searches = () => employeeRequests().filter((params) => params.q !== undefined)

      // Fake only timeouts (the debounce), after the page has loaded on the real clock.
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] })
      const user = userEvent.setup({ delay: 50, advanceTimers: vi.advanceTimersByTime })

      // Typed faster than the debounce: 50 ms between keystrokes, so no
      // request may go out while typing.
      await user.type(screen.getByRole('searchbox', { name: 'Search employees' }), 'rao')
      expect(searches()).toEqual([])

      // Once the user pauses for the debounce delay, exactly one request goes out.
      await act(async () => vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS))
      expect(searches()).toEqual([{ q: 'rao', status: 'active', page: '1', per_page: '25' }])

      await act(async () => vi.runOnlyPendingTimersAsync())
      expect(searches()).toHaveLength(1)
    })
  })

  it('goes back to page 1 when a filter changes', async () => {
    const { employeeRequests } = setup('/employees?page=3')
    await screen.findByText('EMP00001')
    expect(employeeRequests()[0]).toMatchObject({ page: '3' })

    await userEvent.setup().click(screen.getByText('Inactive'))

    await waitFor(() => expect(employeeRequests().at(-1)).toEqual({ status: 'inactive', page: '1', per_page: '25' }))
  })

  it('disables salary sorting without a country filter, and explains why', async () => {
    setup('/employees')
    await screen.findByText('EMP00001')
    const user = userEvent.setup()

    expect(salaryHeader()).not.toHaveClass('ant-table-column-has-sorters')
    await user.hover(within(salaryHeader()).getByText('Current salary'))
    expect(await screen.findByRole('tooltip')).toHaveTextContent(SALARY_SORT_HINT)
  })

  it('sorts by salary once a country filter is set', async () => {
    const { employeeRequests } = setup('/employees?country_id=1')
    await screen.findByText('EMP00001')

    expect(salaryHeader()).toHaveClass('ant-table-column-has-sorters')
    await userEvent.setup().click(within(salaryHeader()).getByText('Current salary'))

    await waitFor(() =>
      expect(employeeRequests().at(-1)).toMatchObject({ country_id: '1', sort: 'current_salary', direction: 'asc' }),
    )
  })

  it('shows the empty state when nothing matches', async () => {
    setup('/employees?q=nobody', { status: 200, body: page([]) })

    expect(await screen.findByText('No employees match these filters')).toBeInTheDocument()
  })

  it('offers a way back to page 1, keeping the filters, when the URL points past the last page', async () => {
    const { employeeRequests } = setup('/employees?q=rao&country_id=1&status=all&per_page=50&page=9', [
      { status: 200, body: page([], 30) },
      { status: 200, body: page([employee()], 30) },
    ])

    expect(await screen.findByText('No employees on this page.')).toBeInTheDocument()
    await userEvent.setup().click(screen.getByRole('button', { name: 'Go to first page' }))

    expect(await screen.findByText('EMP00001')).toBeInTheDocument()
    expect(employeeRequests().at(-1)).toEqual({ q: 'rao', country_id: '1', status: 'all', page: '1', per_page: '50' })
  })

  it('shows the API error with a retry button', async () => {
    setup('/employees', { status: 500, body: { errors: ['Database unavailable'] } })

    expect(await screen.findByText('Couldn’t load employees', { selector: '.ant-alert-title' })).toBeInTheDocument()
    expect(screen.getByText('Database unavailable')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })

  it('keeps the current rows on screen, with a spinner, while the next page loads', async () => {
    let sendSecondPage = () => {}
    const secondPageArrives = new Promise<void>((resolve) => (sendSecondPage = resolve))
    const { employeeRequests } = setup('/employees', [
      { status: 200, body: page([employee()], 60) },
      { status: 200, body: page([employee({ id: 30, employee_code: 'EMP00030' })], 60), waitFor: secondPageArrives },
    ])
    await screen.findByText('EMP00001')

    await userEvent.setup().click(screen.getByRole('button', { name: 'Page 2' }))

    await waitFor(() => expect(employeeRequests().at(-1)).toMatchObject({ page: '2' }))
    expect(screen.getByText('EMP00001')).toBeInTheDocument() // the old page, not a blank table
    expect(document.querySelector('.ant-spin-spinning')).not.toBeNull()

    sendSecondPage()

    expect(await screen.findByText('EMP00030')).toBeInTheDocument()
    expect(screen.queryByText('EMP00001')).not.toBeInTheDocument()
  })

  it('leaves a Ctrl-click on the employee code to the browser (new tab), without also navigating this tab', async () => {
    setup('/employees')
    const link = await screen.findByRole('link', { name: 'EMP00001' })
    const user = userEvent.setup()

    await user.keyboard('{Control>}')
    await user.click(link)
    await user.keyboard('{/Control}')

    expect(link).toHaveAttribute('href', '/employees/1')
    expect(screen.getByRole('heading', { name: 'Employees' })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Employee 1' })).not.toBeInTheDocument()
  })

  it('opens the employee page when a row is clicked', async () => {
    setup('/employees')

    await userEvent.setup().click(await screen.findByText('Asha Rao'))

    expect(await screen.findByRole('heading', { name: 'Employee 1' })).toBeInTheDocument()
  })
})
