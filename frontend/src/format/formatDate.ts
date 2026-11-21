/**
 * Formats an API date ("2020-01-15") for display. The date is read as UTC
 * and formatted in UTC, so it never shifts a day in the user's time zone.
 */
export function formatDate(isoDate: string, locale?: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeZone: 'UTC' }).format(
    new Date(`${isoDate}T00:00:00Z`),
  )
}
