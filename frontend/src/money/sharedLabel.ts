import type { ConvertedMoney } from '../api/types'

/**
 * The label to show once for a group of converted values, in a column
 * header or a chart heading: the one most of them share (the first such
 * label on a tie). Null when there are none. A value whose own label
 * differs, such as one whose rate is missing, keeps its label beside it.
 */
export function sharedLabel(values: ConvertedMoney[]): string | null {
  const counts = new Map<string, number>()
  for (const { label } of values) counts.set(label, (counts.get(label) ?? 0) + 1)

  let best: string | null = null
  for (const [label, count] of counts) if (best === null || count > counts.get(best)!) best = label
  return best
}
