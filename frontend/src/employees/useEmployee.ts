import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { fetchEmployee } from '../api/employees'
import type { EmployeeDetail } from '../api/types'
import { employeeKeys } from './employeeKeys'

/** One employee with their history. Disabled for an id that isn't a positive integer. */
export function useEmployee(id: number) {
  return useQuery({
    queryKey: employeeKeys.detail(id),
    queryFn: ({ signal }) => fetchEmployee(id, signal),
    enabled: Number.isInteger(id) && id > 0,
  })
}

/**
 * Any write that returns the full employee: the response goes straight into
 * the cache (the page updates without refetching), and lists and insights
 * are marked stale, since a name, status or salary in them may have changed.
 */
export function useEmployeeWrite<TBody>(write: (body: TBody) => Promise<EmployeeDetail>) {
  const client = useQueryClient()
  return useMutation({
    mutationFn: write,
    onSuccess: (employee) => {
      client.setQueryData(employeeKeys.detail(employee.id), employee)
      void client.invalidateQueries({ queryKey: employeeKeys.lists })
      void client.invalidateQueries({ queryKey: ['insights'] })
    },
  })
}
