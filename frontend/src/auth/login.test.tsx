import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { apiRequest } from '../api/client'
import { mockFetch } from '../test/mockFetch'
import { renderApp } from '../test/renderApp'

const hrUser = { id: 1, email_address: 'hr@acme.test' }
const notLoggedIn = { status: 401, body: { errors: ['Not logged in'] } }

async function submitLogin(email: string, password: string) {
  const user = userEvent.setup()
  await user.type(screen.getByLabelText('Email'), email)
  await user.type(screen.getByLabelText('Password'), password)
  await user.click(screen.getByRole('button', { name: 'Log in' }))
}

describe('login flow', () => {
  it('sends a logged-out user to the login page', async () => {
    mockFetch({ 'GET /api/session': notLoggedIn })

    renderApp('/employees')

    expect(await screen.findByRole('button', { name: 'Log in' })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Employees' })).not.toBeInTheDocument()
  })

  it('logs in and returns to the page the user asked for', async () => {
    const fetchMock = mockFetch({
      'GET /api/session': notLoggedIn,
      'POST /api/session': { status: 201, body: { user: hrUser } },
    })
    renderApp('/insights')

    await screen.findByRole('button', { name: 'Log in' })
    await submitLogin('hr@acme.test', 'correct-horse-battery')

    expect(await screen.findByRole('heading', { name: 'Insights' })).toBeInTheDocument()
    expect(screen.getByText('hr@acme.test')).toBeInTheDocument()
    const loginCall = fetchMock.mock.calls.find(([, init]) => init?.method === 'POST')
    expect(JSON.parse(String(loginCall?.[1]?.body))).toEqual({
      email_address: 'hr@acme.test',
      password: 'correct-horse-battery',
    })
  })

  it('shows the API message for a wrong password and stays on the login page', async () => {
    mockFetch({
      'GET /api/session': notLoggedIn,
      'POST /api/session': { status: 401, body: { errors: ['Invalid email address or password'] } },
    })
    renderApp('/employees')

    await screen.findByRole('button', { name: 'Log in' })
    await submitLogin('hr@acme.test', 'wrong-password')

    expect(await screen.findByRole('alert')).toHaveTextContent('Invalid email address or password')
    expect(screen.getByRole('button', { name: 'Log in' })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Employees' })).not.toBeInTheDocument()
  })

  it('checks the form before calling the API', async () => {
    const fetchMock = mockFetch({ 'GET /api/session': notLoggedIn })
    renderApp('/login')

    await userEvent.setup().click(await screen.findByRole('button', { name: 'Log in' }))

    expect(await screen.findByText('Enter your email address')).toBeInTheDocument()
    expect(fetchMock.mock.calls.some(([, init]) => init?.method === 'POST')).toBe(false)
  })

  it('logs out and returns to the login page', async () => {
    mockFetch({ 'GET /api/session': { status: 200, body: { user: hrUser } }, 'DELETE /api/session': { status: 204 } })
    renderApp('/employees')

    await userEvent.setup().click(await screen.findByRole('button', { name: 'Log out' }))

    expect(await screen.findByRole('button', { name: 'Log in' })).toBeInTheDocument()
  })

  it('sends the user to the login page when any request gets a 401', async () => {
    mockFetch({
      'GET /api/session': { status: 200, body: { user: hrUser } },
      'GET /api/employees': { status: 401, body: { errors: ['Not logged in'] } },
    })
    renderApp('/employees')
    await screen.findByRole('heading', { name: 'Employees' })

    await apiRequest('/employees').catch(() => {})

    await waitFor(() => expect(screen.getByRole('button', { name: 'Log in' })).toBeInTheDocument())
  })
})
