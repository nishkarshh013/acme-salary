import { Segmented, Select, Space } from 'antd'
import type { UseQueryResult } from '@tanstack/react-query'
import type { Lookup } from '../api/types'
import { useCountries, useDepartments, useJobTitles } from '../lookups/useLookups'
import { EmployeeSearchBox } from './EmployeeSearchBox'
import type { EmployeeListState, StatusFilter } from './listState'

interface Props {
  state: EmployeeListState
  onChange: (change: Partial<EmployeeListState>) => void
}

const STATUS_OPTIONS: { label: string; value: StatusFilter }[] = [
  { label: 'Active', value: 'active' },
  { label: 'Inactive', value: 'inactive' },
  { label: 'All', value: 'all' },
]

export function EmployeeFilters({ state, onChange }: Props) {
  const countries = useCountries()
  const departments = useDepartments()
  const jobTitles = useJobTitles()

  return (
    <Space wrap size="middle" style={{ marginBottom: 16 }}>
      <EmployeeSearchBox value={state.q} onSearch={(q) => onChange({ q })} />
      <LookupSelect
        label="Country"
        allLabel="All countries"
        query={countries}
        value={state.countryId}
        onChange={(countryId) => onChange({ countryId })}
      />
      <LookupSelect
        label="Department"
        allLabel="All departments"
        query={departments}
        value={state.departmentId}
        onChange={(departmentId) => onChange({ departmentId })}
      />
      <LookupSelect
        label="Job title"
        allLabel="All job titles"
        query={jobTitles}
        value={state.jobTitleId}
        onChange={(jobTitleId) => onChange({ jobTitleId })}
        width={220}
      />
      <Segmented<StatusFilter>
        aria-label="Status"
        options={STATUS_OPTIONS}
        value={state.status}
        onChange={(status) => onChange({ status })}
      />
    </Space>
  )
}

interface LookupSelectProps {
  label: string
  allLabel: string
  query: UseQueryResult<Lookup[]>
  value: number | undefined
  onChange: (id: number | undefined) => void
  width?: number
}

function LookupSelect({ label, allLabel, query, value, onChange, width = 180 }: LookupSelectProps) {
  return (
    <Select<number>
      aria-label={label}
      placeholder={query.isError ? `Couldn't load ${label.toLowerCase()}s` : allLabel}
      status={query.isError ? 'error' : undefined}
      allowClear
      showSearch={{ optionFilterProp: 'label' }}
      loading={query.isPending}
      value={value}
      onChange={(id) => onChange(id ?? undefined)}
      options={query.data?.map((item) => ({ value: item.id, label: item.name }))}
      style={{ width }}
    />
  )
}
