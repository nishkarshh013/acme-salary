import { render } from '@testing-library/react'
import { ConfigProvider } from 'antd'
import { createMemoryRouter, RouterProvider } from 'react-router-dom'
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

  // An in-memory router that the test holds on to. location() reads its
  // state, which changes when a navigation completes, before React renders
  // the new page, so it is never behind what the test sees on screen.
  const router = createMemoryRouter([{ path: '*', element: <AppRoutes /> }], { initialEntries: [path] })

  render(
    // Tests only: Ant Design generates no styles at runtime. Under jsdom,
    // parsing those styles and matching them on every getComputedStyle call
    // made each test file's first render take about a second. Tests don't
    // check styling, and the real app keeps its runtime styles.
    <ConfigProvider theme={{ zeroRuntime: true }}>
      <AppProviders queryClient={queryClient}>
        <RouterProvider router={router} />
      </AppProviders>
    </ConfigProvider>,
  )

  const location = () => {
    const { pathname, search } = router.state.location
    return pathname + search
  }
  return { queryClient, location }
}
