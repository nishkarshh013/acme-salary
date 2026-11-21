import { vi } from 'vitest'

export interface MockResponse {
  status: number
  body?: unknown
}

/**
 * Replaces fetch with canned responses keyed by "METHOD /path?query".
 * A list of responses is used in order, the last one repeating.
 * An unmocked request gets a 500 that names it, so the test fails visibly.
 */
export function mockFetch(routes: Record<string, MockResponse | MockResponse[]>) {
  const fetchMock = vi.fn(async (input: RequestInfo | URL, init: RequestInit = {}) => {
    const key = `${init.method ?? 'GET'} ${String(input)}`
    const route = routes[key]
    const response = Array.isArray(route) ? (route.length > 1 ? route.shift() : route[0]) : route
    if (!response) return jsonResponse(500, { errors: [`Unmocked request: ${key}`] })
    return jsonResponse(response.status, response.body)
  })
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(body === undefined ? null : JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
