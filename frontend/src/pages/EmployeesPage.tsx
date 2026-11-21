import { Alert, Button, Flex, Typography } from 'antd'
import { useState } from 'react'
import { ApiError } from '../api/client'
import { EmployeeFilters } from '../employees/EmployeeFilters'
import { EmployeesTable } from '../employees/EmployeesTable'
import { HireEmployeeModal } from '../employees/forms/HireEmployeeModal'
import { useEmployeeListState, useEmployees } from '../employees/useEmployeeList'

export function EmployeesPage() {
  const [state, update] = useEmployeeListState()
  const employees = useEmployees(state)
  const [hiring, setHiring] = useState(false)
  const errorMessages =
    employees.error instanceof ApiError ? employees.error.messages : employees.error ? [employees.error.message] : []

  return (
    <>
      <Flex justify="space-between" align="center" wrap gap={16} style={{ marginBottom: 16 }}>
        <Typography.Title level={2} style={{ margin: 0 }}>
          Employees
        </Typography.Title>
        <Button type="primary" onClick={() => setHiring(true)}>
          Hire employee
        </Button>
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

      {hiring && <HireEmployeeModal onClose={() => setHiring(false)} />}
    </>
  )
}
