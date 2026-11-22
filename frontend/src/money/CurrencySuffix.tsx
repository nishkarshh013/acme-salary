interface Props {
  /** The amount's currency; undefined until it is known (e.g. before a country is chosen). */
  currency: string | undefined
}

/**
 * The currency shown inside a money input, as its `suffix`. Always an
 * element, even while the currency is unknown: Ant Design's Input renders
 * different markup with and without a suffix, so a suffix that appears or
 * disappears while the input is focused would make it lose focus.
 */
export function CurrencySuffix({ currency }: Props) {
  return <span className="currency-suffix">{currency ?? ''}</span>
}
