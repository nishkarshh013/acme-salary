import { useQuery } from '@tanstack/react-query'
import { fetchCountryBreakdown, fetchCountryInsights, fetchInsightsSummary, type GroupBy } from '../api/insights'

/** Query keys for insights. Employee writes mark everything under ['insights'] stale. */
export const insightKeys = {
  summary: ['insights', 'summary'] as const,
  countries: ['insights', 'countries'] as const,
  breakdown: (id: number, groupBy: GroupBy) => ['insights', 'countries', id, groupBy] as const,
}

export function useInsightsSummary() {
  return useQuery({ queryKey: insightKeys.summary, queryFn: ({ signal }) => fetchInsightsSummary(signal) })
}

export function useCountryInsights() {
  return useQuery({ queryKey: insightKeys.countries, queryFn: ({ signal }) => fetchCountryInsights(signal) })
}

/** Disabled for an id that isn't a positive integer. */
export function useCountryBreakdown(id: number, groupBy: GroupBy) {
  return useQuery({
    queryKey: insightKeys.breakdown(id, groupBy),
    queryFn: ({ signal }) => fetchCountryBreakdown(id, groupBy, signal),
    enabled: Number.isInteger(id) && id > 0,
  })
}
