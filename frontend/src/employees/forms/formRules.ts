import type { Rule } from 'antd/es/form'

/**
 * Money is checked as a string (digits, at most 2 decimals, not zero) and
 * sent as typed: it is never converted with Number or parseFloat. The
 * server still decides.
 */
export function moneyRules(label: string, { required = true } = {}): Rule[] {
  return [
    {
      validator: async (_, value: string | undefined) => {
        const amount = (value ?? '').trim()
        if (!amount) {
          if (required) throw new Error(`Enter the ${label.toLowerCase()}`)
          return
        }
        if (!/^\d+(\.\d+)?$/.test(amount)) throw new Error(`${label} must be a number, like 85000 or 85000.50`)
        if (!/^\d+(\.\d{1,2})?$/.test(amount)) throw new Error(`${label} can have at most 2 decimal places`)
        if (!/[1-9]/.test(amount)) throw new Error(`${label} must be greater than 0`)
      },
    },
  ]
}

/**
 * A required YYYY-MM-DD date, no later than `today` (the server's today, from
 * useToday). Compared as strings, which sort like dates.
 */
export function pastDateRules(label: string, today: string): Rule[] {
  return [
    { required: true, message: `Choose the ${label.toLowerCase()}` },
    {
      validator: async (_, value: string | undefined) => {
        if (value && value > today) throw new Error(`${label} can't be in the future`)
      },
    },
  ]
}

export const requiredRule = (message: string): Rule[] => [{ required: true, whitespace: true, message }]
