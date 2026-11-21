import { Typography } from 'antd'
import type { ConvertedMoney, Money } from '../api/types'
import { formatConvertedMoney, formatMoney } from './formatMoney'

interface Props {
  value: Money | ConvertedMoney | null
  locale?: string
}

function isConverted(value: Money | ConvertedMoney): value is ConvertedMoney {
  return 'converted' in value && value.converted
}

/** Shows a money value; a converted value always shows its label, so it can't pass for a local amount. */
export function MoneyText({ value, locale }: Props) {
  if (value === null) return <Typography.Text type="secondary">—</Typography.Text>
  if (!isConverted(value)) return <span>{formatMoney(value, locale)}</span>

  const { text, label } = formatConvertedMoney(value, locale)
  return (
    <span>
      {text !== null && <span>{text} </span>}
      <Typography.Text type="secondary" className="money-label">
        {label}
      </Typography.Text>
    </span>
  )
}
