import { describe, expect, it } from 'vitest'
import { ApiError } from './client'
import { createQueryClient, endSession, SESSION_QUERY_KEY, shouldRetry } from './queryClient'

describe('shouldRetry', () => {
  it.each([400, 401, 404, 409, 422, 429])('does not retry a %i', (status) => {
    expect(shouldRetry(0, new ApiError(status, ['x']))).toBe(false)
  })

  it('retries server errors and network failures twice', () => {
    expect(shouldRetry(0, new ApiError(500, ['x']))).toBe(true)
    expect(shouldRetry(1, new ApiError(0, ['x']))).toBe(true)
    expect(shouldRetry(2, new ApiError(503, ['x']))).toBe(false)
  })
})

describe('endSession', () => {
  it('clears the user and every other cached response', () => {
    const client = createQueryClient()
    client.setQueryData(SESSION_QUERY_KEY, { id: 1, email_address: 'hr@acme.test' })
    client.setQueryData(['employees', { page: 1 }], { employees: [] })

    endSession(client)

    expect(client.getQueryData(SESSION_QUERY_KEY)).toBeNull()
    expect(client.getQueryData(['employees', { page: 1 }])).toBeUndefined()
  })
})
