import type { ConvertedMoney, Money } from '../api/types'

const DECIMAL = /^-?\d+(\.\d+)?$/

/**
 * Formats the API's { amount, currency } for display. The amount string is
 * passed straight to Intl.NumberFormat, which formats numeric strings
 * exactly, so it never becomes a JavaScript number (a float). Fraction
 * digits follow the currency: 2 for USD and INR, 0 for JPY.
 */
export function formatMoney(money: Money, locale?: string): string {
  if (!DECIMAL.test(money.amount)) throw new Error(`Not a decimal amount: ${money.amount}`)

  return new Intl.NumberFormat(locale, { style: 'currency', currency: money.currency }).format(
    money.amount as Intl.StringNumericLiteral,
  )
}

/** A converted USD figure: the formatted amount (null when a rate is missing) and its label. */
export function formatConvertedMoney(money: ConvertedMoney, locale?: string): { text: string | null; label: string } {
  return {
    text: money.amount === null ? null : formatMoney({ amount: money.amount, currency: money.currency }, locale),
    label: money.label,
  }
}
