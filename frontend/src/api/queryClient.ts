import { QueryClient } from '@tanstack/react-query'
import { ApiError, setUnauthorizedHandler } from './client'

export const SESSION_QUERY_KEY = ['session'] as const

/** 4xx responses won't change on retry; network errors and 5xx get two more tries. */
export function shouldRetry(failureCount: number, error: unknown): boolean {
  if (error instanceof ApiError && error.status >= 400 && error.status < 500) return false
  return failureCount < 2
}

/** Drop every cached response except the session itself. */
export function clearCachedData(client: QueryClient): void {
  client.removeQueries({ predicate: (query) => query.queryKey[0] !== SESSION_QUERY_KEY[0] })
}

/** Forget the user and every cached response; RequireAuth then sends them to /login. */
export function endSession(client: QueryClient): void {
  clearCachedData(client)
  client.setQueryData(SESSION_QUERY_KEY, null)
}

export function createQueryClient(): QueryClient {
  const client = new QueryClient({
    defaultOptions: {
      // Only the session query refetches on window focus (see useSession).
      queries: { retry: shouldRetry, refetchOnWindowFocus: false, staleTime: 30_000 },
      mutations: { retry: false },
    },
  })
  setUnauthorizedHandler(() => endSession(client))
  return client
}
