import { Button, Space, Table, Tag, Tooltip } from 'antd'
import type { ColumnsType, SorterResult } from 'antd/es/table/interface'
import type { ReactNode } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import type { Employee, EmployeesPage } from '../api/types'
import { formatDate } from '../format/formatDate'
import { MoneyText } from '../money/MoneyText'
import { type EmployeeListState, PAGE_SIZES, type SortField } from './listState'

export const SALARY_SORT_HINT =
  'Filter by one country to sort by salary. Salaries in different currencies can’t be sorted together.'

interface Props {
  state: EmployeeListState
  onChange: (change: Partial<EmployeeListState>) => void
  page: EmployeesPage | undefined
  loading: boolean
  failed: boolean
}

export function EmployeesTable({ state, onChange, page, loading, failed }: Props) {
  const navigate = useNavigate()
  // No sort in the URL means the API default, last name ascending; show it.
  const activeSort: SortField = state.sort ?? 'last_name'
  const activeOrder = state.sort && state.direction === 'desc' ? 'descend' : 'ascend'
  const sortOrder = (field: SortField) => (field === activeSort ? activeOrder : null)
  const salarySortable = state.countryId !== undefined

  const columns: ColumnsType<Employee> = [
    {
      key: 'employee_code',
      title: 'Code',
      sorter: true,
      sortOrder: sortOrder('employee_code'),
      render: (_, employee) => <Link to={`/employees/${employee.id}`}>{employee.employee_code}</Link>,
    },
    {
      key: 'last_name',
      title: 'Name',
      sorter: true,
      sortOrder: sortOrder('last_name'),
      render: (_, employee) => `${employee.first_name} ${employee.last_name}`,
    },
    { key: 'country', title: 'Country', render: (_, employee) => employee.country.name },
    { key: 'department', title: 'Department', render: (_, employee) => employee.department.name },
    { key: 'job_title', title: 'Job title', render: (_, employee) => employee.job_title.name },
    {
      key: 'current_salary',
      title: salarySortable ? (
        'Current salary'
      ) : (
        <Tooltip title={SALARY_SORT_HINT}>
          <span style={{ textDecoration: 'underline dotted', cursor: 'help' }}>Current salary</span>
        </Tooltip>
      ),
      align: 'right',
      sorter: salarySortable,
      sortOrder: salarySortable ? sortOrder('current_salary') : null,
      render: (_, employee) => <MoneyText value={employee.current_salary} />,
    },
    {
      key: 'status',
      title: 'Status',
      render: (_, employee) =>
        employee.status === 'active' ? <Tag color="green">Active</Tag> : <Tag>Inactive</Tag>,
    },
    {
      key: 'hire_date',
      title: 'Hire date',
      sorter: true,
      sortOrder: sortOrder('hire_date'),
      render: (_, employee) => formatDate(employee.hire_date),
    },
  ]

  return (
    <Table<Employee>
      rowKey="id"
      columns={columns}
      dataSource={page?.employees}
      loading={loading}
      showSorterTooltip={false}
      sortDirections={['ascend', 'descend']}
      scroll={{ x: 'max-content' }}
      locale={{ emptyText: emptyText(page, loading, failed, () => onChange({ page: 1 })) }}
      onRow={(employee) => ({
        // Links in the row handle their own clicks (so Ctrl/Cmd-click opens a new tab without also navigating here).
        onClick: (event) => {
          if (!(event.target as HTMLElement).closest('a')) navigate(`/employees/${employee.id}`)
        },
        style: { cursor: 'pointer' },
      })}
      pagination={{
        current: state.page,
        pageSize: state.perPage,
        total: page?.meta.total_count ?? 0,
        pageSizeOptions: [...PAGE_SIZES],
        showSizeChanger: true,
        showTotal: (total, [from, to]) => `${from}–${to} of ${total} employees`,
      }}
      onChange={(pagination, _filters, sorter, { action }) => {
        if (action === 'sort') {
          const { columnKey, order } = (Array.isArray(sorter) ? sorter[0] : sorter) as SorterResult<Employee>
          onChange(
            order && columnKey
              ? { sort: columnKey as SortField, direction: order === 'descend' ? 'desc' : 'asc' }
              : { sort: undefined },
          )
        } else if (action === 'paginate') {
          const perPage = pagination.pageSize ?? state.perPage
          onChange(perPage === state.perPage ? { page: pagination.current ?? 1 } : { perPage, page: 1 })
        }
      }}
    />
  )
}

function emptyText(
  page: EmployeesPage | undefined,
  loading: boolean,
  failed: boolean,
  goToFirstPage: () => void,
): ReactNode {
  if (failed) return 'Couldn’t load employees'
  if (!page) return loading ? 'Loading employees…' : ''
  if (page.meta.total_count > 0) {
    // A bookmarked or edited URL past the last page; the filters still match employees.
    return (
      <Space orientation="vertical">
        No employees on this page.
        <Button onClick={goToFirstPage}>Go to first page</Button>
      </Space>
    )
  }
  return 'No employees match these filters'
}
