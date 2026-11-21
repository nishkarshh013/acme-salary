import { focusManager, QueryObserver } from '@tanstack/react-query'
import { act, screen, waitFor } from '@testing-library/react'
import { setupUser } from '../test/user'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { createQueryClient } from '../api/queryClient'
import { mockFetch } from '../test/mockFetch'
import { renderApp } from '../test/renderApp'

const user = { id: 1, email_address: 'hr@acme.test' }

/** What the browser does when the user leaves the tab and comes back. */
function returnToTab() {
  act(() => {
    focusManager.setFocused(false)
    focusManager.setFocused(true)
  })
}

function sessionChecks(fetchMock: ReturnType<typeof mockFetch>) {
  return fetchMock.mock.calls.filter(([url, init]) => url === '/api/session' && (init?.method ?? 'GET') === 'GET')
}

describe('session check on window focus', () => {
  afterEach(() => focusManager.setFocused(undefined))

  it('sends the user to the login page when the session expired while they were away', async () => {
    mockFetch({
      'GET /api/session': [
        { status: 200, body: { user, today: '2026-06-15' } },
        { status: 401, body: { errors: ['Not logged in'] } },
      ],
    })
    const { queryClient } = renderApp('/employees')
    await screen.findByRole('heading', { name: 'Employees' })
    queryClient.setQueryData(['employees', { page: 1 }], { employees: [] })

    returnToTab()

    expect(await screen.findByRole('button', { name: 'Log in' })).toBeInTheDocument()
    expect(queryClient.getQueryData(['employees', { page: 1 }])).toBeUndefined()
  })

  it('keeps the user on the page when the session is still valid', async () => {
    const fetchMock = mockFetch({ 'GET /api/session': { status: 200, body: { user, today: '2026-06-15' } } })
    renderApp('/employees')
    await screen.findByRole('heading', { name: 'Employees' })
    expect(sessionChecks(fetchMock)).toHaveLength(1)

    returnToTab()

    await waitFor(() => expect(sessionChecks(fetchMock)).toHaveLength(2))
    expect(screen.getByRole('heading', { name: 'Employees' })).toBeInTheDocument()
  })

  it('does not check the session again when moving between pages', async () => {
    const fetchMock = mockFetch({ 'GET /api/session': { status: 200, body: { user, today: '2026-06-15' } } })
    renderApp('/employees')
    await screen.findByRole('heading', { name: 'Employees' })

    await setupUser().click(screen.getByRole('link', { name: 'Insights' }))

    expect(await screen.findByRole('heading', { name: 'Insights' })).toBeInTheDocument()
    expect(sessionChecks(fetchMock)).toHaveLength(1)
  })

  it('does not refetch other queries on focus, even when stale', async () => {
    const client = createQueryClient()
    client.mount()
    const queryFn = vi.fn(async () => ({ employees: [] }))
    const observer = new QueryObserver(client, { queryKey: ['employees'], queryFn, staleTime: 0 })
    const unsubscribe = observer.subscribe(() => {})
    await waitFor(() => expect(queryFn).toHaveBeenCalledTimes(1))

    returnToTab()
    await new Promise((resolve) => setTimeout(resolve, 20))

    expect(queryFn).toHaveBeenCalledTimes(1)
    unsubscribe()
    client.unmount()
  })
})
