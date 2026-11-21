import type { EmployeeListParams } from '../api/employees'

// The employee list's state lives in the URL query string, so a view can be
// bookmarked and the back button works. These functions are the only place
// that reads or writes it.

export type SortField = NonNullable<EmployeeListParams['sort']>
export type Direction = 'asc' | 'desc'
export type StatusFilter = EmployeeListParams['status']

export const SORTABLE_FIELDS: readonly SortField[] = ['employee_code', 'last_name', 'hire_date', 'current_salary']
export const PAGE_SIZES = [25, 50, 100] as const
const STATUSES: readonly StatusFilter[] = ['active', 'inactive', 'all']

export interface EmployeeListState {
  q: string
  countryId?: number
  departmentId?: number
  jobTitleId?: number
  status: StatusFilter
  /** Undefined means the API default: last name, ascending. */
  sort?: SortField
  direction: Direction
  page: number
  perPage: number
}

export const DEFAULT_LIST_STATE: EmployeeListState = { q: '', status: 'active', direction: 'asc', page: 1, perPage: 25 }

/** Reads the state from the URL. Anything invalid falls back to its default instead of causing an API error. */
export function parseListState(params: URLSearchParams): EmployeeListState {
  const sort = SORTABLE_FIELDS.find((field) => field === params.get('sort'))
  const countryId = positiveInt(params.get('country_id'))
  const perPage = positiveInt(params.get('per_page'))

  return {
    q: params.get('q')?.trim() ?? '',
    countryId,
    departmentId: positiveInt(params.get('department_id')),
    jobTitleId: positiveInt(params.get('job_title_id')),
    status: STATUSES.find((status) => status === params.get('status')) ?? DEFAULT_LIST_STATE.status,
    // Salaries in different currencies can't be sorted together.
    sort: sort === 'current_salary' && countryId === undefined ? undefined : sort,
    direction: params.get('direction') === 'desc' ? 'desc' : 'asc',
    page: positiveInt(params.get('page')) ?? DEFAULT_LIST_STATE.page,
    perPage: PAGE_SIZES.find((size) => size === perPage) ?? DEFAULT_LIST_STATE.perPage,
  }
}

/** Writes the state to the URL, leaving out defaults so URLs stay short. */
export function serializeListState(state: EmployeeListState): URLSearchParams {
  const params = new URLSearchParams()
  if (state.q) params.set('q', state.q)
  if (state.countryId !== undefined) params.set('country_id', String(state.countryId))
  if (state.departmentId !== undefined) params.set('department_id', String(state.departmentId))
  if (state.jobTitleId !== undefined) params.set('job_title_id', String(state.jobTitleId))
  if (state.status !== DEFAULT_LIST_STATE.status) params.set('status', state.status)
  if (state.sort) {
    params.set('sort', state.sort)
    params.set('direction', state.direction)
  }
  if (state.page !== DEFAULT_LIST_STATE.page) params.set('page', String(state.page))
  if (state.perPage !== DEFAULT_LIST_STATE.perPage) params.set('per_page', String(state.perPage))
  return params
}

/**
 * Applies a change. A new search, filter, sort or page size starts again at
 * page 1; removing the country filter drops a salary sort.
 */
export function applyChange(state: EmployeeListState, change: Partial<EmployeeListState>): EmployeeListState {
  const next = { ...state, ...change }
  const resetsPage = (Object.keys(change) as (keyof EmployeeListState)[]).some((key) => key !== 'page')
  if (resetsPage && change.page === undefined) next.page = 1
  if (next.sort === undefined) next.direction = 'asc'
  if (next.sort === 'current_salary' && next.countryId === undefined) {
    next.sort = undefined
    next.direction = 'asc'
  }
  return next
}

export function toApiParams(state: EmployeeListState): EmployeeListParams {
  return {
    q: state.q || undefined,
    country_id: state.countryId,
    department_id: state.departmentId,
    job_title_id: state.jobTitleId,
    status: state.status,
    sort: state.sort,
    direction: state.sort ? state.direction : undefined,
    page: state.page,
    per_page: state.perPage,
  }
}

function positiveInt(value: string | null): number | undefined {
  if (value === null || !/^\d+$/.test(value)) return undefined
  const number = Number(value)
  return number > 0 ? number : undefined
}
