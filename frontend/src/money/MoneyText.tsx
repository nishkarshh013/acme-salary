import { Typography } from 'antd'
import type { ConvertedMoney, Money } from '../api/types'
import { formatConvertedMoney, formatMoney } from './formatMoney'

interface Props {
  value: Money | ConvertedMoney | null
  locale?: string
  /** Puts a converted value's label on its own line, in smaller text (for tables and lists). */
  stacked?: boolean
}

function isConverted(value: Money | ConvertedMoney): value is ConvertedMoney {
  return 'converted' in value && value.converted
}

/** Shows a money value; a converted value always shows its label, so it can't pass for a local amount. */
export function MoneyText({ value, locale, stacked = false }: Props) {
  if (value === null) return <Typography.Text type="secondary">—</Typography.Text>
  if (!isConverted(value)) return <span>{formatMoney(value, locale)}</span>

  const { text, label } = formatConvertedMoney(value, locale)
  if (stacked) {
    return (
      <span className="money-stacked">
        {text !== null && <span style={{ display: 'block' }}>{text}</span>}
        <Typography.Text type="secondary" className="money-label" style={{ display: 'block', fontSize: 12 }}>
          {label}
        </Typography.Text>
      </span>
    )
  }
  return (
    <span>
      {text !== null && <span>{text} </span>}
      <Typography.Text type="secondary" className="money-label">
        {label}
      </Typography.Text>
    </span>
  )
}
