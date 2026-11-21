import { apiRequest } from './client'
import type { EmployeesPage } from './types'

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
