// Response types for the Rails API (backend/app/serializers).
// Money is always a decimal string with its currency, never a JSON number.

export interface Money {
  amount: string
  currency: string
}

/** A USD figure converted with the fixed rate table. amount is null when a rate is missing. */
export interface ConvertedMoney {
  amount: string | null
  currency: 'USD'
  converted: true
  rates_as_of: string | null
  label: string
}

/** Every error response: { "errors": ["..."] }. */
export interface ErrorResponse {
  errors: string[]
}

export interface User {
  id: number
  email_address: string
}

export interface SessionResponse {
  user: User
}

export interface Country {
  id: number
  code: string
  name: string
  currency_code: string
}

/** Departments and job titles. */
export interface Lookup {
  id: number
  name: string
}

export type EmployeeStatus = 'active' | 'inactive'

export interface Employee {
  id: number
  employee_code: string
  first_name: string
  last_name: string
  email: string
  hire_date: string
  status: EmployeeStatus
  country: Country
  department: Lookup
  job_title: Lookup
  current_salary: Money
}

export interface AssignmentSnapshot {
  country: Country
  department: Lookup
  job_title: Lookup
}

interface TimelineEntryBase {
  id: number
  effective_date: string
  reason: string
  recorded_at: string
}

export interface SalaryRevisionEntry extends TimelineEntryBase {
  type: 'salary_revision'
  amount: Money
  previous_amount: Money | null
}

export interface AssignmentEntry extends TimelineEntryBase, AssignmentSnapshot {
  type: 'assignment'
  previous: AssignmentSnapshot | null
}

export type TimelineEntry = SalaryRevisionEntry | AssignmentEntry

export interface EmployeeDetail extends Employee {
  lock_version: number
  timeline: TimelineEntry[]
}

export interface EmployeeResponse {
  employee: EmployeeDetail
}

export interface EmployeesPage {
  employees: Employee[]
  meta: { page: number; per_page: number; total_count: number; total_pages: number }
}

export interface CountriesResponse {
  countries: Country[]
}

export interface DepartmentsResponse {
  departments: Lookup[]
}

export interface JobTitlesResponse {
  job_titles: Lookup[]
}

/** One group's statistics, all in a single local currency. Null when headcount is 0. */
export interface SalaryStatistics {
  headcount: number
  min_salary: Money | null
  max_salary: Money | null
  average_salary: Money | null
  median_salary: Money | null
  total_payroll: Money
}

export interface CountryInsight extends SalaryStatistics {
  country: Country
  total_payroll_usd: ConvertedMoney
}

export interface CountryInsightsResponse {
  countries: CountryInsight[]
}

export interface GroupInsight extends SalaryStatistics {
  group: Lookup
}

export interface CountryBreakdownResponse {
  country: Country
  group_by: 'department' | 'job_title'
  groups: GroupInsight[]
}

export interface InsightsSummary {
  headcount: number
  total_payroll_usd: ConvertedMoney
  by_country: { country: Pick<Country, 'id' | 'code' | 'name'>; headcount: number; total_payroll_usd: ConvertedMoney }[]
  by_department: { department: Lookup; headcount: number; total_payroll_usd: ConvertedMoney }[]
}
