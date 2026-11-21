import { Alert, Button, Flex, Typography } from 'antd'
import { ApiError } from '../api/client'
import { EmployeeFilters } from '../employees/EmployeeFilters'
import { EmployeesTable } from '../employees/EmployeesTable'
import { useEmployeeListState, useEmployees } from '../employees/useEmployeeList'

export function EmployeesPage() {
  const [state, update] = useEmployeeListState()
  const employees = useEmployees(state)
  const errorMessages =
    employees.error instanceof ApiError ? employees.error.messages : employees.error ? [employees.error.message] : []

  return (
    <>
      <Flex justify="space-between" align="center" wrap gap={16} style={{ marginBottom: 16 }}>
        <Typography.Title level={2} style={{ margin: 0 }}>
          Employees
        </Typography.Title>
        {/* Opens the hire form once it exists. */}
        <Button type="primary">Hire employee</Button>
      </Flex>

      <EmployeeFilters state={state} onChange={update} />

      {employees.isError && (
        <Alert
          type="error"
          showIcon
          title="Couldn’t load employees"
          description={errorMessages.join(' ')}
          action={
            <Button size="small" onClick={() => employees.refetch()}>
              Retry
            </Button>
          }
          style={{ marginBottom: 16 }}
        />
      )}

      <EmployeesTable
        state={state}
        onChange={update}
        page={employees.data}
        loading={employees.isFetching}
        failed={employees.isError}
      />
    </>
  )
}
