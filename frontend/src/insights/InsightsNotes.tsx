import { Typography } from 'antd'

export const ACTIVE_ONLY_NOTE = 'Active employees only'
export const ROUNDING_NOTE = 'Totals may differ by a cent due to rounding.'

/** What every insights figure is based on. */
export function InsightsNotes() {
  return (
    <Typography.Paragraph type="secondary" style={{ marginTop: -8 }}>
      <span>{ACTIVE_ONLY_NOTE}</span> · <span>{ROUNDING_NOTE}</span>
    </Typography.Paragraph>
  )
}
