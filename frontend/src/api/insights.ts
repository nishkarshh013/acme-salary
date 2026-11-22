import { apiRequest } from './client'
import type { CountryBreakdownResponse, CountryInsight, CountryInsightsResponse, InsightsSummary } from './types'

export type GroupBy = CountryBreakdownResponse['group_by']

/** Org-wide active headcount and USD payroll, overall, by country and by department. */
export function fetchInsightsSummary(signal?: AbortSignal): Promise<InsightsSummary> {
  return apiRequest<InsightsSummary>('/insights/summary', { signal })
}

/** Statistics for every country in its local currency, plus its payroll in USD. */
export async function fetchCountryInsights(signal?: AbortSignal): Promise<CountryInsight[]> {
  return (await apiRequest<CountryInsightsResponse>('/insights/countries', { signal })).countries
}

/** One country's statistics per department or job title, in its local currency. */
export function fetchCountryBreakdown(
  id: number,
  groupBy: GroupBy,
  signal?: AbortSignal,
): Promise<CountryBreakdownResponse> {
  return apiRequest<CountryBreakdownResponse>(`/insights/countries/${id}`, { params: { group_by: groupBy }, signal })
}
