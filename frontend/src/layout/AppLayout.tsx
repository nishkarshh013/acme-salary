import { Button, Layout, Menu, Space, Typography } from 'antd'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useLogout, useSession } from '../auth/useSession'

const NAV_ITEMS = [
  { key: '/employees', label: <Link to="/employees">Employees</Link> },
  { key: '/insights', label: <Link to="/insights">Insights</Link> },
]

export function AppLayout() {
  const { data: user } = useSession()
  const logout = useLogout()
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const selected = NAV_ITEMS.find((item) => pathname.startsWith(item.key))?.key

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Layout.Header style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
        <Typography.Text strong style={{ color: '#fff', whiteSpace: 'nowrap' }}>
          ACME Salary
        </Typography.Text>
        <Menu
          theme="dark"
          mode="horizontal"
          items={NAV_ITEMS}
          selectedKeys={selected ? [selected] : []}
          style={{ flex: 1, minWidth: 0 }}
        />
        <Space>
          <Typography.Text style={{ color: 'rgba(255,255,255,0.85)' }}>{user?.email_address}</Typography.Text>
          <Button
            loading={logout.isPending}
            onClick={() => logout.mutate(undefined, { onSettled: () => navigate('/login', { replace: true }) })}
          >
            Log out
          </Button>
        </Space>
      </Layout.Header>
      <Layout.Content style={{ padding: 24 }}>
        <Outlet />
      </Layout.Content>
    </Layout>
  )
}
