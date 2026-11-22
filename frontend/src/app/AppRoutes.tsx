import { Navigate, Route, Routes } from 'react-router-dom'
import { LoginPage } from '../auth/LoginPage'
import { RequireAuth } from '../auth/RequireAuth'
import { AppLayout } from '../layout/AppLayout'
import { CountryInsightsPage } from '../pages/CountryInsightsPage'
import { EmployeeDetailPage } from '../pages/EmployeeDetailPage'
import { EmployeesPage } from '../pages/EmployeesPage'
import { InsightsPage } from '../pages/InsightsPage'

/** Every route except /login needs a session. */
export function AppRoutes() {
  return (
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
  )
}
