import { Typography } from 'antd'
import type { ConvertedMoney, Money } from '../api/types'
import { formatConvertedMoney, formatMoney } from './formatMoney'

interface Props {
  value: Money | ConvertedMoney | null
  locale?: string
  /** Puts a converted value's label on its own line, in smaller text (for tables and lists). */
  stacked?: boolean
  /**
   * The label already shown once for this value's group, in a column header
   * or chart heading (see ConvertedTitle). A converted value with that same
   * label shows only its amount; one with a different label still shows its own.
   */
  sharedLabel?: string | null
}

function isConverted(value: Money | ConvertedMoney): value is ConvertedMoney {
  return 'converted' in value && value.converted
}

const dash = <Typography.Text type="secondary">—</Typography.Text>

/**
 * Shows a money value. A converted value is always labelled, beside it or in
 * its column header or chart heading, so it can't pass for a local amount.
 */
export function MoneyText({ value, locale, stacked = false, sharedLabel }: Props) {
  if (value === null) return dash
  if (!isConverted(value)) return <span>{formatMoney(value, locale)}</span>

  const { text, label } = formatConvertedMoney(value, locale)
  if (sharedLabel != null && label === sharedLabel) return text === null ? dash : <span>{text}</span>

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

/** A column title or chart heading with the label its converted values share, on a second line. */
export function ConvertedTitle({ title, label }: { title: string; label: string | null }) {
  return (
    <span>
      {title}
      {label !== null && (
        <Typography.Text type="secondary" className="money-label" style={{ display: 'block', fontSize: 12, fontWeight: 'normal' }}>
          {label}
        </Typography.Text>
      )}
    </span>
  )
}
