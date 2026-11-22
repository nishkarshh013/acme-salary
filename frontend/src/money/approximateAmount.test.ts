import { describe, expect, it } from 'vitest'
import { approximateAmount, barPercent, compareAmounts } from './approximateAmount'

const eur = (amount: string) => ({ amount, currency: 'EUR' })

describe('approximateAmount', () => {
  it('converts the amount string to a number', () => {
    expect(approximateAmount(eur('72000.50'))).toBe(72000.5)
  })

  it('returns null for a missing value or a converted value without an amount', () => {
    expect(approximateAmount(null)).toBeNull()
    expect(
      approximateAmount({ amount: null, currency: 'USD', converted: true, rates_as_of: null, label: 'unavailable' }),
    ).toBeNull()
  })
})

describe('compareAmounts', () => {
  it('orders by numeric value, not as text', () => {
    const sorted = [eur('10000.00'), eur('9000.00'), eur('100000.00')].sort(compareAmounts)

    expect(sorted.map((money) => money.amount)).toEqual(['9000.00', '10000.00', '100000.00'])
  })

  it('keeps the largest amounts the database holds in order', () => {
    expect(compareAmounts(eur('9999999999999.98'), eur('9999999999999.99'))).toBeLessThan(0)
  })

  it('puts missing amounts first', () => {
    expect([eur('1.00'), null].sort(compareAmounts)).toEqual([null, eur('1.00')])
  })
})

describe('barPercent', () => {
  it('is the share of the largest value', () => {
    expect(barPercent(eur('250.00'), 1000)).toBe(25)
    expect(barPercent(eur('1000.00'), 1000)).toBe(100)
  })

  it('is 0 for a missing amount or when everything is zero', () => {
    expect(barPercent(null, 1000)).toBe(0)
    expect(barPercent(eur('0.00'), 0)).toBe(0)
  })
})
