import { afterEach, describe, expect, it, vi } from 'vitest'
import { mockFetch } from '../test/mockFetch'
import { ApiError, apiRequest, setUnauthorizedHandler } from './client'

describe('apiRequest', () => {
  afterEach(() => setUnauthorizedHandler(null))

  it('sends same-origin credentials and JSON, and returns the parsed body', async () => {
    const fetchMock = mockFetch({ 'POST /api/employees': { status: 201, body: { employee: { id: 1 } } } })

    const result = await apiRequest('/employees', { method: 'POST', body: { first_name: 'Asha' } })

    expect(result).toEqual({ employee: { id: 1 } })
    const [, init] = fetchMock.mock.calls[0]
    expect(init).toMatchObject({ method: 'POST', credentials: 'same-origin', body: '{"first_name":"Asha"}' })
    expect(init?.headers).toMatchObject({ Accept: 'application/json', 'Content-Type': 'application/json' })
  })

  it('adds query parameters, skipping empty ones', async () => {
    const fetchMock = mockFetch({ 'GET /api/employees?q=rao&page=2': { status: 200, body: {} } })

    await apiRequest('/employees', { params: { q: 'rao', country_id: undefined, status: '', page: 2 } })

    expect(fetchMock).toHaveBeenCalledWith('/api/employees?q=rao&page=2', expect.anything())
  })

  it('returns null for 204 No Content', async () => {
    mockFetch({ 'DELETE /api/session': { status: 204 } })

    await expect(apiRequest('/session', { method: 'DELETE' })).resolves.toBeNull()
  })

  it('turns an error response into an ApiError with the status and messages', async () => {
    mockFetch({
      'GET /api/employees': { status: 422, body: { errors: ['sort must be one of: …', 'page must be a positive integer'] } },
    })

    const error = await apiRequest('/employees').catch((e: unknown) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({
      status: 422,
      messages: ['sort must be one of: …', 'page must be a positive integer'],
    })
  })

  it('keeps the 409 stale-data message', async () => {
    mockFetch({
      'PATCH /api/employees/1': {
        status: 409,
        body: { errors: ['This employee was changed by someone else. Reload and try again.'] },
      },
    })

    await expect(apiRequest('/employees/1', { method: 'PATCH', body: {} })).rejects.toMatchObject({
      status: 409,
      messages: ['This employee was changed by someone else. Reload and try again.'],
    })
  })

  it('gives a generic message when the error body is not the API shape', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('<html>Bad Gateway</html>', { status: 502 })))

    await expect(apiRequest('/employees')).rejects.toMatchObject({
      status: 502,
      messages: ['Something went wrong (HTTP 502). Please try again.'],
    })
  })

  it('reports an unreachable server as status 0', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => Promise.reject(new TypeError('Failed to fetch'))))

    await expect(apiRequest('/employees')).rejects.toMatchObject({
      status: 0,
      messages: ["Couldn't reach the server. Check your connection and try again."],
    })
  })

  it('calls the unauthorized handler on a 401', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    mockFetch({ 'GET /api/employees': { status: 401, body: { errors: ['Not logged in'] } } })

    await expect(apiRequest('/employees')).rejects.toMatchObject({ status: 401, messages: ['Not logged in'] })
    expect(handler).toHaveBeenCalledOnce()
  })

  it('leaves a 401 to the caller when the request opts out', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    mockFetch({ 'POST /api/session': { status: 401, body: { errors: ['Invalid email address or password'] } } })

    await expect(apiRequest('/session', { method: 'POST', body: {}, redirectOnUnauthorized: false })).rejects.toThrow(
      ApiError,
    )
    expect(handler).not.toHaveBeenCalled()
  })

  it('does not call the handler for other errors', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    mockFetch({ 'GET /api/employees/0': { status: 404, body: { errors: ['Not found'] } } })

    await expect(apiRequest('/employees/0')).rejects.toMatchObject({ status: 404 })
    expect(handler).not.toHaveBeenCalled()
  })
})
