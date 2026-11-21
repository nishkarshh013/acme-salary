import type { ErrorResponse } from './types'

/** Every failed request: the HTTP status (0 when the server was unreachable) and the API's messages. */
export class ApiError extends Error {
  readonly status: number
  readonly messages: string[]

  constructor(status: number, messages: string[]) {
    super(messages.join(' '))
    this.name = 'ApiError'
    this.status = status
    this.messages = messages
  }
}

type Method = 'GET' | 'POST' | 'PATCH' | 'DELETE'
type Params = Record<string, string | number | null | undefined>

export interface RequestOptions {
  method?: Method
  body?: unknown
  params?: Params
  signal?: AbortSignal
  /** Default true: a 401 ends the session and sends the user to the login page. */
  redirectOnUnauthorized?: boolean
}

const NETWORK_ERROR = "Couldn't reach the server. Check your connection and try again."

let unauthorizedHandler: (() => void) | null = null

/** Called on any 401 (unless the request opts out). Registered by createQueryClient. */
export function setUnauthorizedHandler(handler: (() => void) | null): void {
  unauthorizedHandler = handler
}

/**
 * The one way the app talks to the API: same-origin cookies, JSON in and
 * out, and every non-2xx response thrown as an ApiError.
 */
export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, params, signal, redirectOnUnauthorized = true } = options

  let response: Response
  try {
    response = await fetch(buildUrl(path, params), {
      method,
      credentials: 'same-origin',
      signal,
      headers: {
        Accept: 'application/json',
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    })
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') throw error
    throw new ApiError(0, [NETWORK_ERROR])
  }

  const data = await readJson(response)
  if (!response.ok) {
    if (response.status === 401 && redirectOnUnauthorized) unauthorizedHandler?.()
    throw new ApiError(response.status, errorMessages(data, response.status))
  }
  return data as T
}

function buildUrl(path: string, params?: Params): string {
  const query = new URLSearchParams()
  for (const [key, value] of Object.entries(params ?? {})) {
    if (value !== undefined && value !== null && value !== '') query.set(key, String(value))
  }
  const search = query.toString()
  return `/api${path}${search ? `?${search}` : ''}`
}

async function readJson(response: Response): Promise<unknown> {
  const text = await response.text()
  if (!text) return null
  try {
    return JSON.parse(text)
  } catch {
    return null // e.g. an HTML error page from a proxy
  }
}

function errorMessages(data: unknown, status: number): string[] {
  const errors = (data as Partial<ErrorResponse> | null)?.errors
  if (Array.isArray(errors) && errors.length > 0 && errors.every((e) => typeof e === 'string')) return errors
  return [`Something went wrong (HTTP ${status}). Please try again.`]
}
