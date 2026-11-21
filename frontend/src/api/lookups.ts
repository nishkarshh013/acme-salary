import { apiRequest } from './client'
import type { CountriesResponse, Country, DepartmentsResponse, JobTitlesResponse, Lookup } from './types'

export async function fetchCountries(): Promise<Country[]> {
  return (await apiRequest<CountriesResponse>('/countries')).countries
}

export async function fetchDepartments(): Promise<Lookup[]> {
  return (await apiRequest<DepartmentsResponse>('/departments')).departments
}

export async function fetchJobTitles(): Promise<Lookup[]> {
  return (await apiRequest<JobTitlesResponse>('/job_titles')).job_titles
}
