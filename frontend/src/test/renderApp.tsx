import { render } from '@testing-library/react'
import { ConfigProvider } from 'antd'
import { useEffect } from 'react'
import { MemoryRouter, useLocation } from 'react-router-dom'
import { createQueryClient } from '../api/queryClient'
import { AppProviders } from '../app/AppProviders'
import { AppRoutes } from '../app/AppRoutes'

/**
 * Renders the whole app at a path, with a fresh query client that doesn't
 * retry. `location()` returns the current path and query string.
 */
export function renderApp(path: string) {
  const queryClient = createQueryClient()
  queryClient.setDefaultOptions({ queries: { ...queryClient.getDefaultOptions().queries, retry: false } })

  const probe = { location: path }
  function LocationProbe() {
    const { pathname, search } = useLocation()
    useEffect(() => {
      probe.location = pathname + search
    }, [pathname, search])
    return null
  }

  render(
    // Tests only: Ant Design generates no styles at runtime. Under jsdom,
    // parsing those styles and matching them on every getComputedStyle call
    // made each test file's first render take about a second. Tests don't
    // check styling, and the real app keeps its runtime styles.
    <ConfigProvider theme={{ zeroRuntime: true }}>
      <AppProviders queryClient={queryClient}>
        <MemoryRouter initialEntries={[path]}>
          <AppRoutes />
          <LocationProbe />
        </MemoryRouter>
      </AppProviders>
    </ConfigProvider>,
  )
  return { queryClient, location: () => probe.location }
}
