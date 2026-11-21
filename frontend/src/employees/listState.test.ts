import { describe, expect, it } from 'vitest'
import { applyChange, DEFAULT_LIST_STATE, parseListState, serializeListState, toApiParams } from './listState'

const parse = (query: string) => parseListState(new URLSearchParams(query))

describe('parseListState', () => {
  it('uses defaults for an empty query string', () => {
    expect(parse('')).toEqual(DEFAULT_LIST_STATE)
  })

  it('reads every field', () => {
    expect(
      parse('q=rao&country_id=3&department_id=4&job_title_id=5&status=all&sort=current_salary&direction=desc&page=2&per_page=50'),
    ).toEqual({
      q: 'rao', countryId: 3, departmentId: 4, jobTitleId: 5, status: 'all',
      sort: 'current_salary', direction: 'desc', page: 2, perPage: 50,
    })
  })

  it('falls back to defaults for invalid values instead of sending them to the API', () => {
    expect(parse('country_id=abc&status=retired&sort=email&page=0&per_page=500&direction=up')).toEqual(
      DEFAULT_LIST_STATE,
    )
  })

  it('drops a salary sort without a country filter', () => {
    expect(parse('sort=current_salary&direction=desc').sort).toBeUndefined()
  })
})

describe('serializeListState', () => {
  it('leaves out defaults, so the plain list has a clean URL', () => {
    expect(serializeListState(DEFAULT_LIST_STATE).toString()).toBe('')
  })

  it('round-trips through the URL', () => {
    const query = 'q=rao&country_id=3&status=inactive&sort=hire_date&direction=desc&page=4&per_page=100'

    expect(serializeListState(parse(query)).toString()).toBe(query)
  })
})

describe('applyChange', () => {
  const onPage3 = { ...DEFAULT_LIST_STATE, page: 3 }

  it.each([
    ['search', { q: 'rao' }],
    ['country', { countryId: 2 }],
    ['department', { departmentId: 2 }],
    ['job title', { jobTitleId: 2 }],
    ['status', { status: 'all' as const }],
    ['sort', { sort: 'hire_date' as const, direction: 'desc' as const }],
  ])('goes back to page 1 when the %s changes', (_, change) => {
    expect(applyChange(onPage3, change).page).toBe(1)
  })

  it('keeps an explicit page change', () => {
    expect(applyChange(onPage3, { page: 4 }).page).toBe(4)
  })

  it('drops a salary sort when the country filter is removed', () => {
    const sortedBySalary = { ...DEFAULT_LIST_STATE, countryId: 1, sort: 'current_salary' as const, direction: 'desc' as const }

    expect(applyChange(sortedBySalary, { countryId: undefined })).toMatchObject({ sort: undefined, direction: 'asc' })
  })
})

describe('toApiParams', () => {
  it('always sends status, page and per_page, and a direction only with a sort', () => {
    expect(toApiParams(DEFAULT_LIST_STATE)).toEqual({
      q: undefined, country_id: undefined, department_id: undefined, job_title_id: undefined,
      status: 'active', sort: undefined, direction: undefined, page: 1, per_page: 25,
    })
  })
})
