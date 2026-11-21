import type { Country, EmployeeDetail } from '../api/types'

export const india: Country = { id: 1, code: 'IN', name: 'India', currency_code: 'INR' }
export const germany: Country = { id: 2, code: 'DE', name: 'Germany', currency_code: 'EUR' }
export const france: Country = { id: 3, code: 'FR', name: 'France', currency_code: 'EUR' }
export const engineering = { id: 1, name: 'Engineering' }
export const sales = { id: 2, name: 'Sales' }
export const engineer = { id: 1, name: 'Engineer' }
export const seniorEngineer = { id: 2, name: 'Senior Engineer' }

export function employeeDetail(overrides: Partial<EmployeeDetail> = {}): EmployeeDetail {
  return {
    id: 1,
    employee_code: 'EMP00001',
    first_name: 'Asha',
    last_name: 'Rao',
    email: 'asha.rao@acme.test',
    hire_date: '2022-01-10',
    status: 'active',
    country: india,
    department: engineering,
    job_title: engineer,
    current_salary: { amount: '1000000.00', currency: 'INR' },
    lock_version: 3,
    timeline: [],
    ...overrides,
  }
}

/** The server's today in tests (from GET /api/session). */
export const SERVER_TODAY = '2026-06-15'

/** Session and lookup responses every logged-in page needs. */
export const commonRoutes = {
  'GET /api/session': { status: 200, body: { user: { id: 1, email_address: 'hr@acme.test' }, today: SERVER_TODAY } },
  'GET /api/countries': { status: 200, body: { countries: [france, germany, india] } },
  'GET /api/departments': { status: 200, body: { departments: [engineering, sales] } },
  'GET /api/job_titles': { status: 200, body: { job_titles: [engineer, seniorEngineer] } },
}
