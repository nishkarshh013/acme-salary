import { Input } from 'antd'
import { useEffect, useEffectEvent, useState } from 'react'

export const SEARCH_DEBOUNCE_MS = 300

interface Props {
  /** The search applied now (from the URL). */
  value: string
  onSearch: (q: string) => void
}

/** Applies the search 300 ms after typing stops, or at once on Enter or clear. */
export function EmployeeSearchBox({ value, onSearch }: Props) {
  const [text, setText] = useState(value)
  const [appliedValue, setAppliedValue] = useState(value)

  // The URL changed from outside (back button, a link): show its search.
  // Not when it's our own search coming back, which would eat a trailing space mid-typing.
  if (value !== appliedValue) {
    setAppliedValue(value)
    if (value !== text.trim()) setText(value)
  }

  const search = useEffectEvent((q: string) => onSearch(q))
  useEffect(() => {
    const q = text.trim()
    if (q === value) return
    const timer = setTimeout(() => search(q), SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(timer)
  }, [text, value])

  return (
    <Input.Search
      aria-label="Search employees"
      placeholder="Search name, email or employee code"
      allowClear
      value={text}
      onChange={(event) => setText(event.target.value)}
      onSearch={(q) => onSearch(q.trim())}
      style={{ width: 300 }}
    />
  )
}
