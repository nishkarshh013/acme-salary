/** Query keys for employee data. Everything under ['employees'] is employee data. */
export const employeeKeys = {
  all: ['employees'] as const,
  lists: ['employees', 'list'] as const,
  detail: (id: number) => ['employees', 'detail', id] as const,
}
