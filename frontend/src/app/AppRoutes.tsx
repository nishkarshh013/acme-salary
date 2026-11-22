import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { RequireAuth } from '../auth/RequireAuth'
import { AppLayout } from '../layout/AppLayout'
import { PageLoading } from './PageLoading'

// Each page is its own chunk, downloaded the first time its route is
// visited, so the login page doesn't load the employee and insights code.
const LoginPage = lazy(() => import('../auth/LoginPage').then((m) => ({ default: m.LoginPage })))
const EmployeesPage = lazy(() => import('../pages/EmployeesPage').then((m) => ({ default: m.EmployeesPage })))
const EmployeeDetailPage = lazy(() =>
  import('../pages/EmployeeDetailPage').then((m) => ({ default: m.EmployeeDetailPage })),
)
const InsightsPage = lazy(() => import('../pages/InsightsPage').then((m) => ({ default: m.InsightsPage })))
const CountryInsightsPage = lazy(() =>
  import('../pages/CountryInsightsPage').then((m) => ({ default: m.CountryInsightsPage })),
)

/** Every route except /login needs a session. */
export function AppRoutes() {
  return (
    // Pages inside AppLayout load under its own Suspense, so the header stays put.
    <Suspense fallback={<PageLoading />}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<RequireAuth />}>
          <Route element={<AppLayout />}>
            <Route path="/employees" element={<EmployeesPage />} />
            <Route path="/employees/:id" element={<EmployeeDetailPage />} />
            <Route path="/insights" element={<InsightsPage />} />
            <Route path="/insights/countries/:id" element={<CountryInsightsPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/employees" replace />} />
      </Routes>
    </Suspense>
  )
}
