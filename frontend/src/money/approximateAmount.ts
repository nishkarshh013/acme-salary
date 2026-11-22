import type { ConvertedMoney, Money } from '../api/types'

// The one place an amount becomes a JavaScript number. A float can be off
// in the last digits, so this is only for bar widths and sort comparisons
// (see CLAUDE.md): never display the result or send it to the API.

/** The amount as an approximate number, or null when there is none. */
export function approximateAmount(money: Money | ConvertedMoney | null): number | null {
  if (money === null || money.amount === null) return null
  return Number(money.amount)
}

/** A sort comparator for amounts; missing amounts sort before any amount. */
export function compareAmounts(a: Money | ConvertedMoney | null, b: Money | ConvertedMoney | null): number {
  const x = approximateAmount(a)
  const y = approximateAmount(b)
  if (x === null || y === null) return (x === null ? 0 : 1) - (y === null ? 0 : 1)
  return x - y
}

/** Each amount as a percentage of the largest (0 when there is nothing to compare against). */
export function barPercent(money: Money | ConvertedMoney | null, largest: number): number {
  const value = approximateAmount(money)
  if (value === null || largest <= 0) return 0
  return Math.max(0, Math.min(100, (value / largest) * 100))
}
