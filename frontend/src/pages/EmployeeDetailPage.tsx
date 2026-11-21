import { Alert, Button, Card, Descriptions, Flex, Result, Skeleton, Space, Tag, Tooltip, Typography } from 'antd'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import type { EmployeeDetail } from '../api/types'
import { EmployeeTimeline } from '../employees/detail/EmployeeTimeline'
import { ChangeAssignmentModal } from '../employees/forms/ChangeAssignmentModal'
import { EditEmployeeModal } from '../employees/forms/EditEmployeeModal'
import { ReviseSalaryModal } from '../employees/forms/ReviseSalaryModal'
import { useEmployee } from '../employees/useEmployee'
import { formatDate } from '../format/formatDate'
import { MoneyText } from '../money/MoneyText'

export const INACTIVE_HINT = 'Inactive employees can’t have their salary or assignment changed. Make them active first (Edit details).'

type OpenModal = 'revise' | 'assignment' | 'edit' | null

export function EmployeeDetailPage() {
  const id = Number(useParams().id)
  const employee = useEmployee(id)

  const notFound =
    !Number.isInteger(id) || id <= 0 || (employee.error instanceof ApiError && employee.error.status === 404)
  if (notFound) {
    return (
      <Result
        status="404"
        title="Employee not found"
        extra={<Link to="/employees">Back to employees</Link>}
      />
    )
  }
  if (employee.isError) {
    return (
      <Alert
        type="error"
        showIcon
        title="Couldn’t load this employee"
        description={employee.error.message}
        action={<Button onClick={() => employee.refetch()}>Retry</Button>}
      />
    )
  }
  if (!employee.data) return <Skeleton active paragraph={{ rows: 8 }} />

  return <EmployeeDetailView employee={employee.data} />
}

function EmployeeDetailView({ employee }: { employee: EmployeeDetail }) {
  const [openModal, setOpenModal] = useState<OpenModal>(null)
  const close = () => setOpenModal(null)
  const inactive = employee.status === 'inactive'

  const historyAction = (label: string, modal: OpenModal) => (
    // A disabled button gets no mouse events, so the tooltip sits on a wrapper.
    <Tooltip title={inactive ? INACTIVE_HINT : undefined}>
      <span style={{ display: 'inline-block', cursor: inactive ? 'not-allowed' : undefined }}>
        <Button disabled={inactive} onClick={() => setOpenModal(modal)}>
          {label}
        </Button>
      </span>
    </Tooltip>
  )

  return (
    <>
      <Link to="/employees">← Employees</Link>
      <Flex justify="space-between" align="center" wrap gap={16} style={{ margin: '8px 0 16px' }}>
        <Space align="center" wrap>
          <Typography.Title level={2} style={{ margin: 0 }}>
            {employee.first_name} {employee.last_name}
          </Typography.Title>
          <Typography.Text type="secondary">{employee.employee_code}</Typography.Text>
          {employee.status === 'active' ? <Tag color="green">Active</Tag> : <Tag>Inactive</Tag>}
        </Space>
        <Space wrap>
          {historyAction('Revise salary', 'revise')}
          {historyAction('Change assignment', 'assignment')}
          <Button onClick={() => setOpenModal('edit')}>Edit details</Button>
        </Space>
      </Flex>

      <Card style={{ marginBottom: 16 }}>
        <Descriptions
          column={{ xs: 1, sm: 2, lg: 3 }}
          items={[
            { key: 'email', label: 'Email', children: employee.email },
            { key: 'country', label: 'Country', children: employee.country.name },
            { key: 'department', label: 'Department', children: employee.department.name },
            { key: 'job_title', label: 'Job title', children: employee.job_title.name },
            { key: 'hire_date', label: 'Hire date', children: formatDate(employee.hire_date) },
            { key: 'salary', label: 'Current salary', children: <MoneyText value={employee.current_salary} /> },
          ]}
        />
      </Card>

      <Card title="History">
        <EmployeeTimeline entries={employee.timeline} />
      </Card>

      {openModal === 'revise' && <ReviseSalaryModal employee={employee} onClose={close} />}
      {openModal === 'assignment' && <ChangeAssignmentModal employee={employee} onClose={close} />}
      {openModal === 'edit' && <EditEmployeeModal employee={employee} onClose={close} />}
    </>
  )
}
