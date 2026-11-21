import { screen, within } from '@testing-library/react'
import { setupUser } from '../test/user'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { chooseOption } from '../test/antd'
import { commonRoutes, employeeDetail, engineering, germany, seniorEngineer, SERVER_TODAY } from '../test/employeeFixtures'
import { mockFetch } from '../test/mockFetch'
import { renderApp } from '../test/renderApp'

describe('Hire employee', () => {
  afterEach(() => vi.useRealTimers())

  it('hires with the salary as a string and opens the new employee’s page', async () => {
    const hired = employeeDetail({
      id: 42, employee_code: 'EMP10001', first_name: 'Ben', last_name: 'Iyer', country: germany,
      department: engineering, job_title: seniorEngineer, hire_date: '2026-06-15',
      current_salary: { amount: '72000.50', currency: 'EUR' }, lock_version: 0,
    })
    const fetchMock = mockFetch({
      ...commonRoutes,
      'GET /api/employees': { status: 200, body: { employees: [], meta: { page: 1, per_page: 25, total_count: 0, total_pages: 0 } } },
      'POST /api/employees': { status: 201, body: { employee: hired } },
    })
    renderApp('/employees')
    const user = setupUser()

    await user.click(await screen.findByRole('button', { name: 'Hire employee' }))
    const dialog = screen.getByRole('dialog')
    await user.type(within(dialog).getByLabelText('First name'), 'Ben')
    await user.type(within(dialog).getByLabelText('Last name'), 'Iyer')
    await user.type(within(dialog).getByLabelText('Email'), 'ben.iyer@acme.test')
    await chooseOption(user, dialog, 'Country', 'Germany (EUR)')
    await chooseOption(user, dialog, 'Department', 'Engineering')
    await chooseOption(user, dialog, 'Job title', 'Senior Engineer')
    expect(within(dialog).getByText('EUR')).toBeInTheDocument() // the salary's currency, from the country
    await user.type(within(dialog).getByLabelText('Annual salary'), '72000.50')
    await user.click(within(dialog).getByRole('button', { name: 'Hire' }))

    expect(await screen.findByRole('heading', { name: 'Ben Iyer' })).toBeInTheDocument()
    expect(screen.getByText('EMP10001')).toBeInTheDocument()
    const post = fetchMock.mock.calls.find(([url, init]) => url === '/api/employees' && init?.method === 'POST')
    expect(JSON.parse(String(post?.[1]?.body))).toEqual({
      first_name: 'Ben', last_name: 'Iyer', email: 'ben.iyer@acme.test', hire_date: '2026-06-15',
      country_id: germany.id, department_id: engineering.id, job_title_id: seniorEngineer.id, salary: '72000.50',
    })
    // The new employee came from the POST response; their page didn't fetch them again.
    expect(fetchMock.mock.calls.some(([url]) => url === '/api/employees/42')).toBe(false)
  })

  it('does not allow a hire date after the server’s today, whatever the browser clock says', async () => {
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-06-14T19:00:00Z')) // still the 14th in UTC
    mockFetch({
      ...commonRoutes,
      'GET /api/employees': { status: 200, body: { employees: [], meta: { page: 1, per_page: 25, total_count: 0, total_pages: 0 } } },
    })
    renderApp('/employees')
    const user = setupUser()
    await user.click(await screen.findByRole('button', { name: 'Hire employee' }))

    const hireDate = within(screen.getByRole('dialog')).getByLabelText('Hire date')
    expect(hireDate).toHaveValue(SERVER_TODAY)
    expect(hireDate).toHaveAttribute('max', SERVER_TODAY)
    await user.clear(hireDate)
    await user.type(hireDate, '2026-06-16')
    await user.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'Hire' }))

    expect(hireDate).toHaveValue('2026-06-16')
    expect(await screen.findByText("Hire date can't be in the future")).toBeInTheDocument()
  })
})
