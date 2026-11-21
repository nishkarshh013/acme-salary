import { render } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { createQueryClient } from '../api/queryClient'
import { AppProviders } from '../app/AppProviders'
import { AppRoutes } from '../app/AppRoutes'

/** Renders the whole app at a path, with a fresh query client that doesn't retry. */
export function renderApp(path: string) {
  const queryClient = createQueryClient()
  queryClient.setDefaultOptions({ queries: { ...queryClient.getDefaultOptions().queries, retry: false } })

  render(
    <AppProviders queryClient={queryClient}>
      <MemoryRouter initialEntries={[path]}>
        <AppRoutes />
      </MemoryRouter>
    </AppProviders>,
  )
  return { queryClient }
}
