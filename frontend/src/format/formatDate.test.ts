import { describe, expect, it } from 'vitest'
import { formatDate } from './formatDate'

describe('formatDate', () => {
  it('formats an API date', () => {
    expect(formatDate('2020-01-15', 'en-US')).toBe('Jan 15, 2020')
  })

  it('never shifts the day, whatever the time zone', () => {
    expect(formatDate('2026-01-01', 'en-GB')).toBe('1 Jan 2026')
  })
})
