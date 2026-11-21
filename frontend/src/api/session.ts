import { ApiError, apiRequest } from './client'
import type { Session, SessionResponse } from './types'

export interface Credentials {
  email_address: string
  password: string
}

/** The logged-in user and the server's today, or null when there is no session (401). */
export async function fetchSession(): Promise<Session | null> {
  try {
    return await apiRequest<SessionResponse>('/session', { redirectOnUnauthorized: false })
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) return null
    throw error
  }
}

/** A wrong password is a 401 that the login form shows, not a redirect. */
export async function logIn(credentials: Credentials): Promise<Session> {
  return apiRequest<SessionResponse>('/session', {
    method: 'POST',
    body: credentials,
    redirectOnUnauthorized: false,
  })
}

export async function logOut(): Promise<void> {
  await apiRequest<void>('/session', { method: 'DELETE', redirectOnUnauthorized: false })
}
