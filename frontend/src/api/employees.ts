import { apiRequest } from './client'
import type { EmployeeDetail, EmployeeResponse, EmployeesPage } from './types'

export interface EmployeeListParams {
  q?: string
  country_id?: number
  department_id?: number
  job_title_id?: number
  status: 'active' | 'inactive' | 'all'
  sort?: 'employee_code' | 'last_name' | 'hire_date' | 'current_salary'
  direction?: 'asc' | 'desc'
  page: number
  per_page: number
}

export function fetchEmployees(params: EmployeeListParams, signal?: AbortSignal): Promise<EmployeesPage> {
  return apiRequest<EmployeesPage>('/employees', { params: { ...params }, signal })
}

// Writes. Each returns the full employee (with its new lock_version and timeline).
// Money is sent as the string the user typed; dates as YYYY-MM-DD.

export interface HireBody {
  first_name: string
  last_name: string
  email: string
  hire_date: string
  country_id: number
  department_id: number
  job_title_id: number
  salary: string
}

export interface UpdateEmployeeBody {
  lock_version: number
  first_name: string
  last_name: string
  email: string
  status: 'active' | 'inactive'
}

export interface ReviseSalaryBody {
  lock_version: number
  amount: string
  effective_date: string
  reason: string
}

export interface ChangeAssignmentBody {
  lock_version: number
  country_id: number
  department_id: number
  job_title_id: number
  new_salary?: string
  effective_date: string
  reason: string
}

export async function fetchEmployee(id: number, signal?: AbortSignal): Promise<EmployeeDetail> {
  return (await apiRequest<EmployeeResponse>(`/employees/${id}`, { signal })).employee
}

export async function hireEmployee(body: HireBody): Promise<EmployeeDetail> {
  return (await apiRequest<EmployeeResponse>('/employees', { method: 'POST', body })).employee
}

export async function updateEmployee(id: number, body: UpdateEmployeeBody): Promise<EmployeeDetail> {
  return (await apiRequest<EmployeeResponse>(`/employees/${id}`, { method: 'PATCH', body })).employee
}

export async function reviseSalary(id: number, body: ReviseSalaryBody): Promise<EmployeeDetail> {
  return (await apiRequest<EmployeeResponse>(`/employees/${id}/salary_revisions`, { method: 'POST', body })).employee
}

export async function changeAssignment(id: number, body: ChangeAssignmentBody): Promise<EmployeeDetail> {
  return (await apiRequest<EmployeeResponse>(`/employees/${id}/assignments`, { method: 'POST', body })).employee
}
