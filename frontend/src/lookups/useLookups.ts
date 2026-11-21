import { useQuery } from '@tanstack/react-query'
import { fetchCountries, fetchDepartments, fetchJobTitles } from '../api/lookups'

// Reference data rarely changes; keep it for the whole visit.
const options = { staleTime: Infinity, gcTime: Infinity }

export function useCountries() {
  return useQuery({ queryKey: ['lookups', 'countries'], queryFn: fetchCountries, ...options })
}

export function useDepartments() {
  return useQuery({ queryKey: ['lookups', 'departments'], queryFn: fetchDepartments, ...options })
}

export function useJobTitles() {
  return useQuery({ queryKey: ['lookups', 'job_titles'], queryFn: fetchJobTitles, ...options })
}
