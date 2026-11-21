import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { fetchSession, logIn, logOut } from '../api/session'
import { clearCachedData, endSession, SESSION_QUERY_KEY } from '../api/queryClient'

/**
 * The session: the logged-in user and the server's today (null when logged out). Kept while navigating
 * (staleTime: Infinity), but checked again every time the user returns to
 * the tab, so a session that expired meanwhile sends them to the login page
 * at once. Other queries don't refetch on focus.
 */
export function useSession() {
  const client = useQueryClient()
  return useQuery({
    queryKey: SESSION_QUERY_KEY,
    queryFn: async () => {
      const user = await fetchSession()
      if (user === null) clearCachedData(client) // no responses from the old session survive
      return user
    },
    staleTime: Infinity,
    // 'always', not true: true only refetches stale data, and this query is never stale.
    refetchOnWindowFocus: 'always',
  })
}

export function useLogin() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: logIn,
    onSuccess: (session) => client.setQueryData(SESSION_QUERY_KEY, session),
  })
}

/** Ends the session on the server; local state is cleared even if that request fails. */
export function useLogout() {
  const client = useQueryClient()
  return useMutation({
    mutationFn: logOut,
    onSettled: () => endSession(client),
  })
}

/**
 * Today's date as the server sees it (its APP_TIME_ZONE), as YYYY-MM-DD.
 * Forms use it for default and latest dates, so the browser's clock and time
 * zone can't disagree with what the server accepts. It is refreshed with the
 * session, including each time the user returns to the tab.
 * Only for pages behind RequireAuth, where the session is loaded.
 */
export function useToday(): string {
  const { data } = useSession()
  if (!data) throw new Error('useToday is only available on pages that require a session')
  return data.today
}
