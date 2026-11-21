import { screen, waitFor, within } from '@testing-library/react'
import { setupUser } from '../../test/user'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { chooseOption } from '../../test/antd'
import {
  commonRoutes, employeeDetail, engineering, engineer, germany, india, seniorEngineer, SERVER_TODAY,
} from '../../test/employeeFixtures'
import { mockFetch, type MockResponse } from '../../test/mockFetch'
import { renderApp } from '../../test/renderApp'
import { INACTIVE_HINT } from '../../pages/EmployeeDetailPage'
import type { EmployeeDetail } from '../../api/types'

const STALE = 'This employee was changed by someone else. Reload and try again.'

function setup(employee: EmployeeDetail, routes: Record<string, MockResponse | MockResponse[]> = {}) {
  const fetchMock = mockFetch({
    ...commonRoutes,
    [`GET /api/employees/${employee.id}`]: { status: 200, body: { employee } },
    ...routes,
  })
  const { queryClient } = renderApp(`/employees/${employee.id}`)
  const calls = (method: string, url: string) =>
    fetchMock.mock.calls.filter(([u, init]) => String(u) === url && (init?.method ?? 'GET') === method)
  const lastBody = (method: string, url: string) => JSON.parse(String(calls(method, url).at(-1)?.[1]?.body))
  return { queryClient, calls, lastBody }
}

const dialog = () => screen.getByRole('dialog')

describe('Employee detail page', () => {
  afterEach(() => vi.useRealTimers())

  it('shows the employee’s details', async () => {
    setup(employeeDetail())

    expect(await screen.findByRole('heading', { name: 'Asha Rao' })).toBeInTheDocument()
    expect(screen.getByText('EMP00001')).toBeInTheDocument()
    expect(screen.getByText('Active')).toBeInTheDocument()
    expect(screen.getByText('asha.rao@acme.test')).toBeInTheDocument()
    expect(screen.getByText(/1,000,000\.00|10,00,000\.00/)).toBeInTheDocument()
  })

  it('renders each kind of timeline entry, newest first', async () => {
    setup(
      employeeDetail({
        country: germany,
        current_salary: { amount: '65000.00', currency: 'EUR' },
        timeline: [
          { type: 'salary_revision', id: 3, effective_date: '2024-06-01', reason: 'Relocation to Berlin', recorded_at: '',
            amount: { amount: '65000.00', currency: 'EUR' }, previous_amount: { amount: '1100000.00', currency: 'INR' } },
          { type: 'assignment', id: 2, effective_date: '2024-06-01', reason: 'Relocation to Berlin', recorded_at: '',
            country: germany, department: engineering, job_title: seniorEngineer,
            previous: { country: india, department: engineering, job_title: engineer } },
          { type: 'salary_revision', id: 2, effective_date: '2023-01-01', reason: 'Annual review', recorded_at: '',
            amount: { amount: '1100000.00', currency: 'INR' }, previous_amount: { amount: '1000000.00', currency: 'INR' } },
          { type: 'salary_revision', id: 1, effective_date: '2022-01-10', reason: 'Hired', recorded_at: '',
            amount: { amount: '1000000.00', currency: 'INR' }, previous_amount: null },
          { type: 'assignment', id: 1, effective_date: '2022-01-10', reason: 'Hired', recorded_at: '',
            country: india, department: engineering, job_title: engineer, previous: null },
        ],
      }),
    )

    const entries = await screen.findAllByTestId('timeline-entry')
    expect(entries.map((entry) => entry.textContent)).toEqual([
      expect.stringMatching(/Salary: .*1[1,]+00,000\.00 → €65,000\.00 \(INR → EUR\)Relocation to Berlin/),
      'Country: India → GermanyJob title: Engineer → Senior EngineerRelocation to Berlin',
      expect.stringMatching(/Salary: .*1[0,]+00,000\.00 → .*1[1,]+00,000\.00Annual review/),
      expect.stringMatching(/Starting salary: .*1[0,]+00,000\.00Hired/),
      'Hired as Engineer, Engineering, IndiaHired',
    ])
    expect(screen.getAllByText('Jun 1, 2024')).toHaveLength(2)
  })

  // At 00:30 in India the server (APP_TIME_ZONE=Asia/Kolkata) says it's the
  // 15th while a browser in UTC still says the 14th: the forms follow the server.
  it('takes default and latest dates from the server’s today, not the browser clock', async () => {
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-06-14T19:00:00Z'))
    const berliner = employeeDetail({ country: germany, current_salary: { amount: '70000.00', currency: 'EUR' } })
    setup(berliner)
    const user = setupUser()

    for (const action of ['Revise salary', 'Change assignment']) {
      await user.click(await screen.findByRole('button', { name: action }))
      const date = within(dialog()).getByLabelText('Effective date')
      expect(date).toHaveValue(SERVER_TODAY)
      expect(date).toHaveAttribute('max', SERVER_TODAY)
      await user.click(within(dialog()).getByRole('button', { name: 'Cancel' }))
      await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument())
    }
  })

  describe('revise salary', () => {
    async function openRevise() {
      const user = setupUser()
      await user.click(await screen.findByRole('button', { name: 'Revise salary' }))
      return user
    }

    it('sends the amount as a string with today’s date and lock_version, then updates the page from the response', async () => {
      const revised = employeeDetail({
        lock_version: 4,
        current_salary: { amount: '1100000.50', currency: 'INR' },
        timeline: [{ type: 'salary_revision', id: 2, effective_date: '2026-06-15', reason: 'Annual review', recorded_at: '',
          amount: { amount: '1100000.50', currency: 'INR' }, previous_amount: { amount: '1000000.00', currency: 'INR' } }],
      })
      const { calls, lastBody, queryClient } = setup(employeeDetail(), {
        'POST /api/employees/1/salary_revisions': { status: 201, body: { employee: revised } },
      })
      queryClient.setQueryData(['employees', 'list', { page: 1 }], { employees: [], meta: {} })
      const user = await openRevise()

      expect(within(dialog()).getByText('INR')).toBeInTheDocument() // currency shown, fixed by the country
      expect(within(dialog()).getByLabelText('Effective date')).toHaveValue('2026-06-15')
      await user.type(within(dialog()).getByLabelText('New annual salary'), '1100000.50')
      await user.type(within(dialog()).getByLabelText('Reason'), 'Annual review')
      await user.click(within(dialog()).getByRole('button', { name: 'Save revision' }))

      await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument())
      expect(lastBody('POST', '/api/employees/1/salary_revisions')).toEqual({
        lock_version: 3, amount: '1100000.50', effective_date: '2026-06-15', reason: 'Annual review',
      })
      expect(screen.getAllByText(/1,100,000\.50|11,00,000\.50/).length).toBeGreaterThan(0)
      expect(calls('GET', '/api/employees/1')).toHaveLength(1) // updated from the response, no refetch
      expect(queryClient.getQueryState(['employees', 'list', { page: 1 }])?.isInvalidated).toBe(true)
    })

    it('checks the amount in the form before sending', async () => {
      const { calls } = setup(employeeDetail())
      const user = await openRevise()

      await user.type(within(dialog()).getByLabelText('New annual salary'), '100.555')
      await user.type(within(dialog()).getByLabelText('Reason'), 'Typo')
      await user.click(within(dialog()).getByRole('button', { name: 'Save revision' }))

      expect(await within(dialog()).findByText('Amount can have at most 2 decimal places')).toBeInTheDocument()
      expect(calls('POST', '/api/employees/1/salary_revisions')).toHaveLength(0)
    })

    it('shows a 422 from the API in the form', async () => {
      setup(employeeDetail(), {
        'POST /api/employees/1/salary_revisions': {
          status: 422,
          body: { errors: ['Effective date can’t be earlier than the latest salary revision (2026-06-20)'] },
        },
      })
      const user = await openRevise()

      await user.type(within(dialog()).getByLabelText('New annual salary'), '1100000')
      await user.type(within(dialog()).getByLabelText('Reason'), 'Annual review')
      await user.click(within(dialog()).getByRole('button', { name: 'Save revision' }))

      expect(await within(dialog()).findByRole('alert')).toHaveTextContent(
        'Effective date can’t be earlier than the latest salary revision (2026-06-20)',
      )
      expect(dialog()).toBeInTheDocument()
    })

    it('offers Reload on a 409, then saves with the fresh lock_version', async () => {
      const { calls, lastBody } = setup(employeeDetail(), {
        'GET /api/employees/1': [
          { status: 200, body: { employee: employeeDetail() } },
          { status: 200, body: { employee: employeeDetail({ lock_version: 4, email: 'asha@acme.test' }) } },
        ],
        'POST /api/employees/1/salary_revisions': [
          { status: 409, body: { errors: [STALE] } },
          { status: 201, body: { employee: employeeDetail({ lock_version: 5 }) } },
        ],
      })
      const user = await openRevise()
      await user.type(within(dialog()).getByLabelText('New annual salary'), '1100000')
      await user.type(within(dialog()).getByLabelText('Reason'), 'Annual review')
      await user.click(within(dialog()).getByRole('button', { name: 'Save revision' }))

      const alert = await within(dialog()).findByRole('alert')
      expect(alert).toHaveTextContent('This employee was changed by someone else')
      await user.click(within(alert).getByRole('button', { name: 'Reload' }))

      await waitFor(() => expect(within(dialog()).queryByRole('alert')).not.toBeInTheDocument())
      expect(calls('GET', '/api/employees/1')).toHaveLength(2)
      expect(within(dialog()).getByLabelText('New annual salary')).toHaveValue('1100000') // input kept
      await user.click(within(dialog()).getByRole('button', { name: 'Save revision' }))
      await waitFor(() => expect(lastBody('POST', '/api/employees/1/salary_revisions')).toMatchObject({ lock_version: 4 }))
    })
  })

  describe('change assignment', () => {
    // A Berlin employee: France shares EUR, India does not.
    const berliner = employeeDetail({ country: germany, current_salary: { amount: '70000.00', currency: 'EUR' } })

    it('asks for a new salary only when the currency changes', async () => {
      const { lastBody } = setup(berliner, {
        'POST /api/employees/1/assignments': { status: 201, body: { employee: { ...berliner, country: india } } },
      })
      const user = setupUser()
      await user.click(await screen.findByRole('button', { name: 'Change assignment' }))
      await waitFor(() => expect(within(dialog()).getByRole('combobox', { name: 'Country' })).toBeInTheDocument())

      expect(within(dialog()).queryByLabelText(/New salary/)).not.toBeInTheDocument()

      await chooseOption(user, dialog(), 'Country', 'France (EUR)')
      expect(within(dialog()).queryByLabelText(/New salary/)).not.toBeInTheDocument()

      await chooseOption(user, dialog(), 'Country', 'India (INR)')
      const salaryInput = await within(dialog()).findByLabelText('New salary in INR')

      await user.type(within(dialog()).getByLabelText('Reason'), 'Relocation')
      await user.click(within(dialog()).getByRole('button', { name: 'Save change' }))
      expect(await within(dialog()).findByText('Enter the new salary')).toBeInTheDocument()

      await user.type(salaryInput, '5800000')
      await user.click(within(dialog()).getByRole('button', { name: 'Save change' }))
      await waitFor(() =>
        expect(lastBody('POST', '/api/employees/1/assignments')).toEqual({
          lock_version: 3, country_id: india.id, department_id: engineering.id, job_title_id: engineer.id,
          new_salary: '5800000', effective_date: '2026-06-15', reason: 'Relocation',
        }),
      )
    })

    it('lets a same-currency change include an optional salary', async () => {
      const { lastBody } = setup(berliner, {
        'POST /api/employees/1/assignments': { status: 201, body: { employee: berliner } },
      })
      const user = setupUser()
      await user.click(await screen.findByRole('button', { name: 'Change assignment' }))
      await waitFor(() => expect(within(dialog()).getByRole('combobox', { name: 'Job title' })).toBeInTheDocument())

      await chooseOption(user, dialog(), 'Job title', 'Senior Engineer')
      await user.click(within(dialog()).getByRole('button', { name: 'Also change the salary' }))
      await user.type(within(dialog()).getByLabelText('New salary (optional)'), '80000')
      await user.type(within(dialog()).getByLabelText('Reason'), 'Promotion')
      await user.click(within(dialog()).getByRole('button', { name: 'Save change' }))

      await waitFor(() =>
        expect(lastBody('POST', '/api/employees/1/assignments')).toMatchObject({
          job_title_id: seniorEngineer.id, new_salary: '80000', reason: 'Promotion',
        }),
      )
    })
  })

  describe('edit details', () => {
    it('asks for confirmation before making an employee inactive', async () => {
      const { calls, lastBody } = setup(employeeDetail(), {
        'PATCH /api/employees/1': { status: 200, body: { employee: employeeDetail({ status: 'inactive', lock_version: 4 }) } },
      })
      const user = setupUser()
      await user.click(await screen.findByRole('button', { name: 'Edit details' }))

      await user.click(within(dialog()).getByText('Inactive'))
      await user.click(within(dialog()).getByRole('button', { name: 'Save' }))

      expect((await screen.findAllByText('Make Asha Rao inactive?')).length).toBeGreaterThan(0)
      expect(calls('PATCH', '/api/employees/1')).toHaveLength(0)
      await user.click(screen.getByRole('button', { name: 'Make inactive' }))

      await waitFor(() =>
        expect(lastBody('PATCH', '/api/employees/1')).toEqual({
          lock_version: 3, first_name: 'Asha', last_name: 'Rao', email: 'asha.rao@acme.test', status: 'inactive',
        }),
      )
      expect(await screen.findByRole('button', { name: 'Revise salary' })).toBeDisabled()
    })
  })

  describe('an inactive employee', () => {
    it('disables revise and change assignment, and says why', async () => {
      setup(employeeDetail({ status: 'inactive' }))
      const user = setupUser()

      const revise = await screen.findByRole('button', { name: 'Revise salary' })
      expect(revise).toBeDisabled()
      expect(screen.getByRole('button', { name: 'Change assignment' })).toBeDisabled()
      expect(screen.getByRole('button', { name: 'Edit details' })).toBeEnabled()

      await user.hover(revise.parentElement as HTMLElement)
      expect(await screen.findByRole('tooltip')).toHaveTextContent(INACTIVE_HINT)
    })
  })

  it('shows “Employee not found” for an unknown id', async () => {
    mockFetch({ ...commonRoutes, 'GET /api/employees/999': { status: 404, body: { errors: ['Not found'] } } })
    renderApp('/employees/999')

    expect(await screen.findByText('Employee not found')).toBeInTheDocument()
  })
})
