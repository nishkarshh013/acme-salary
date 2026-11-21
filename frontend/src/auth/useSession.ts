import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { fetchSession, logIn, logOut } from '../api/session'
import { clearCachedData, endSession, SESSION_QUERY_KEY } from '../api/queryClient'

/**
 * The logged-in user (null when logged out). Kept while navigating
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
    onSuccess: (user) => client.setQueryData(SESSION_QUERY_KEY, user),
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
