import { useQueryClient } from '@tanstack/react-query'
import { employeeKeys } from '../employeeKeys'

/** After a 409: fetch the employee again (new lock_version) and clear the error, keeping what the user typed. */
export function useReloadEmployee(id: number, resetError: () => void) {
  const client = useQueryClient()
  return async () => {
    await client.refetchQueries({ queryKey: employeeKeys.detail(id) })
    resetError()
  }
}
