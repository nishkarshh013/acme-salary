import { describe, expect, it } from 'vitest'
import { formatConvertedMoney, formatMoney } from './formatMoney'

describe('formatMoney', () => {
  it('formats USD with two decimals', () => {
    expect(formatMoney({ amount: '100000.00', currency: 'USD' }, 'en-US')).toBe('$100,000.00')
  })

  it('formats INR with Indian digit grouping in the en-IN locale', () => {
    expect(formatMoney({ amount: '2350000.00', currency: 'INR' }, 'en-IN')).toBe('₹23,50,000.00')
  })

  it('formats JPY without decimals', () => {
    expect(formatMoney({ amount: '1500000.00', currency: 'JPY' }, 'en-US')).toBe('¥1,500,000')
  })

  it('formats the largest amount the database holds exactly', () => {
    expect(formatMoney({ amount: '9999999999999.99', currency: 'USD' }, 'en-US')).toBe('$9,999,999,999,999.99')
  })

  it('never goes through a JavaScript number, which would lose these digits', () => {
    const amount = '12345678901234567.89'
    expect(Number(amount).toFixed(2)).not.toBe(amount) // a float can't hold it

    expect(formatMoney({ amount, currency: 'USD' }, 'en-US')).toBe('$12,345,678,901,234,567.89')
  })

  it("uses the locale's separators and keeps trailing cents", () => {
    expect(formatMoney({ amount: '0.10', currency: 'EUR' }, 'en-US')).toBe('€0.10')
    // de-DE puts a non-breaking space before the symbol
    expect(formatMoney({ amount: '1234.56', currency: 'EUR' }, 'de-DE')).toBe('1.234,56 €')
  })

  it('rejects a value that is not a decimal string', () => {
    expect(() => formatMoney({ amount: '1e5', currency: 'USD' })).toThrow('Not a decimal amount: 1e5')
  })
})

describe('formatConvertedMoney', () => {
  const converted = {
    amount: '140400.54',
    currency: 'USD' as const,
    converted: true as const,
    rates_as_of: '2026-10-01',
    label: 'USD, converted at fixed rates as of 2026-10-01',
  }

  it('returns the amount and its label', () => {
    expect(formatConvertedMoney(converted, 'en-US')).toEqual({
      text: '$140,400.54',
      label: 'USD, converted at fixed rates as of 2026-10-01',
    })
  })

  it('returns no amount when a rate was missing', () => {
    const missing = { ...converted, amount: null, label: 'USD conversion unavailable: an exchange rate is missing' }

    expect(formatConvertedMoney(missing)).toEqual({ text: null, label: missing.label })
  })
})
