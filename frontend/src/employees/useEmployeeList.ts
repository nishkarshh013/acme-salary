import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import { fetchEmployees } from '../api/employees'
import { applyChange, type EmployeeListState, parseListState, serializeListState, toApiParams } from './listState'

/** The list state from the URL, and a function that changes it (adding a history entry). */
export function useEmployeeListState() {
  const [searchParams, setSearchParams] = useSearchParams()
  const state = useMemo(() => parseListState(searchParams), [searchParams])

  const update = useCallback(
    (change: Partial<EmployeeListState>) =>
      setSearchParams((current) => serializeListState(applyChange(parseListState(current), change))),
    [setSearchParams],
  )
  return [state, update] as const
}

/** One page of employees. The previous page stays on screen while the next one loads. */
export function useEmployees(state: EmployeeListState) {
  const params = toApiParams(state)
  return useQuery({
    queryKey: ['employees', 'list', params],
    queryFn: ({ signal }) => fetchEmployees(params, signal),
    placeholderData: keepPreviousData,
  })
}
