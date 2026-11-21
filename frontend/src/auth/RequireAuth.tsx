import { Alert, Flex, Spin } from 'antd'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useSession } from './useSession'

/** Renders the child routes only with a session; otherwise sends the user to /login and back afterwards. */
export function RequireAuth() {
  const session = useSession()
  const location = useLocation()

  if (session.isPending) {
    return (
      <Flex justify="center" style={{ padding: 64 }}>
        <Spin size="large" />
      </Flex>
    )
  }
  if (session.isError) {
    return <Alert type="error" showIcon title="Couldn't check your session" description={session.error.message} />
  }
  if (session.data === null) return <Navigate to="/login" replace state={{ from: location.pathname }} />

  return <Outlet />
}
