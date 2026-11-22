import { Table } from 'antd'
import type { ColumnsType } from 'antd/es/table/interface'
import { Link, useNavigate } from 'react-router-dom'
import type { GroupBy } from '../api/insights'
import type { GroupInsight } from '../api/types'
import { statisticColumns } from './statisticColumns'
import { employeeListPath, groupByLabel } from './urls'

interface Props {
  countryId: number
  groupBy: GroupBy
  groups: GroupInsight[] | undefined
  loading: boolean
}

/**
 * One country's statistics per department or job title, sortable on every
 * column in the browser. A row opens the employee list filtered to that
 * country and group.
 */
export function GroupInsightsTable({ countryId, groupBy, groups, loading }: Props) {
  const navigate = useNavigate()
  const pathFor = (row: GroupInsight) => employeeListPath(countryId, groupBy, row.group.id)

  const columns: ColumnsType<GroupInsight> = [
    {
      key: 'name',
      title: groupByLabel(groupBy),
      sorter: (a, b) => a.group.name.localeCompare(b.group.name),
      render: (_, row) => <Link to={pathFor(row)}>{row.group.name}</Link>,
    },
    ...statisticColumns<GroupInsight>(true),
  ]

  return (
    <Table<GroupInsight>
      rowKey={(row) => row.group.id}
      columns={columns}
      dataSource={groups}
      loading={loading}
      pagination={false}
      showSorterTooltip={false}
      sortDirections={['ascend', 'descend']}
      scroll={{ x: 'max-content' }}
      locale={{ emptyText: loading ? 'Loading…' : 'No active employees' }}
      onRow={(row) => ({
        // The name link handles its own clicks (so Ctrl/Cmd-click opens a new tab).
        onClick: (event) => {
          if (!(event.target as HTMLElement).closest('a')) navigate(pathFor(row))
        },
        style: { cursor: 'pointer' },
      })}
    />
  )
}
