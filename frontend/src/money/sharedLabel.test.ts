import { describe, expect, it } from 'vitest'
import type { ConvertedMoney } from '../api/types'
import { sharedLabel } from './sharedLabel'

const usd = (label: string): ConvertedMoney => ({
  amount: '1.00',
  currency: 'USD',
  converted: true,
  rates_as_of: '2026-10-01',
  label,
})

describe('sharedLabel', () => {
  it('is the label most values share', () => {
    expect(sharedLabel([usd('missing'), usd('as of 2026-10-01'), usd('as of 2026-10-01')])).toBe('as of 2026-10-01')
  })

  it('takes the first label on a tie', () => {
    expect(sharedLabel([usd('a'), usd('b')])).toBe('a')
  })

  it('is null when there are no values', () => {
    expect(sharedLabel([])).toBeNull()
  })
})
