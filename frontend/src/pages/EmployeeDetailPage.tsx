import { Typography } from 'antd'
import { Link, useParams } from 'react-router-dom'

export function EmployeeDetailPage() {
  const { id } = useParams()

  return (
    <>
      <Link to="/employees">← Employees</Link>
      <Typography.Title level={2}>Employee {id}</Typography.Title>
      <Typography.Paragraph type="secondary">Employee details are coming next.</Typography.Paragraph>
    </>
  )
}
