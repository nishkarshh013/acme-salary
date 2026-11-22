import type { GroupBy } from '../api/insights'
import { DEFAULT_LIST_STATE, serializeListState } from '../employees/listState'

export const GROUP_BY_OPTIONS: { value: GroupBy; label: string }[] = [
  { value: 'department', label: 'Department' },
  { value: 'job_title', label: 'Job title' },
]

/** The group_by URL parameter; anything else means the default, department. */
export function parseGroupBy(value: string | null): GroupBy {
  return value === 'job_title' ? 'job_title' : 'department'
}

export function groupByLabel(groupBy: GroupBy): string {
  return groupBy === 'job_title' ? 'Job title' : 'Department'
}

/**
 * The employee list filtered to one country and one department or job
 * title. The list shows active employees by default, the same people the
 * statistics count.
 */
export function employeeListPath(countryId: number, groupBy: GroupBy, groupId: number): string {
  const state = {
    ...DEFAULT_LIST_STATE,
    countryId,
    ...(groupBy === 'job_title' ? { jobTitleId: groupId } : { departmentId: groupId }),
  }
  return `/employees?${serializeListState(state)}`
}

/** A country's drill-down page. */
export function countryInsightsPath(id: number): string {
  return `/insights/countries/${id}`
}
