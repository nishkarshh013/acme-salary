import { Alert, Button, Card, Flex, Form, Input, Typography } from 'antd'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { ApiError } from '../api/client'
import type { Credentials } from '../api/session'
import { useLogin, useSession } from './useSession'

export function LoginPage() {
  const session = useSession()
  const login = useLogin()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from ?? '/employees'

  if (session.data) return <Navigate to={from} replace />

  const errors = login.error instanceof ApiError ? login.error.messages : login.error ? [login.error.message] : []

  return (
    <Flex justify="center" align="center" style={{ minHeight: '100vh', padding: 16 }}>
      <Card style={{ width: '100%', maxWidth: 380 }}>
        <Typography.Title level={3}>ACME Salary</Typography.Title>
        <Typography.Paragraph type="secondary">Log in to manage salaries.</Typography.Paragraph>

        {errors.length > 0 && (
          <Alert type="error" showIcon title={errors.join(' ')} style={{ marginBottom: 16 }} role="alert" />
        )}

        <Form<Credentials>
          layout="vertical"
          requiredMark={false}
          onFinish={(values) => login.mutate(values, { onSuccess: () => navigate(from, { replace: true }) })}
        >
          <Form.Item
            label="Email"
            name="email_address"
            rules={[{ required: true, type: 'email', message: 'Enter your email address' }]}
          >
            <Input autoComplete="username" autoFocus />
          </Form.Item>
          <Form.Item label="Password" name="password" rules={[{ required: true, message: 'Enter your password' }]}>
            <Input.Password autoComplete="current-password" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block loading={login.isPending}>
            Log in
          </Button>
        </Form>
      </Card>
    </Flex>
  )
}
