import { ApiError, apiRequest } from './client'
import type { SessionResponse, User } from './types'

export interface Credentials {
  email_address: string
  password: string
}

/** The logged-in user, or null when there is no session (401). */
export async function fetchSession(): Promise<User | null> {
  try {
    const { user } = await apiRequest<SessionResponse>('/session', { redirectOnUnauthorized: false })
    return user
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) return null
    throw error
  }
}

/** A wrong password is a 401 that the login form shows, not a redirect. */
export async function logIn(credentials: Credentials): Promise<User> {
  const { user } = await apiRequest<SessionResponse>('/session', {
    method: 'POST',
    body: credentials,
    redirectOnUnauthorized: false,
  })
  return user
}

export async function logOut(): Promise<void> {
  await apiRequest<void>('/session', { method: 'DELETE', redirectOnUnauthorized: false })
}
