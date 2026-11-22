import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { MoneyText } from './MoneyText'

describe('MoneyText', () => {
  it('shows a local amount', () => {
    render(<MoneyText value={{ amount: '65000.25', currency: 'EUR' }} locale="en-US" />)

    expect(screen.getByText('€65,000.25')).toBeInTheDocument()
  })

  it('shows a converted amount together with its label', () => {
    render(
      <MoneyText
        locale="en-US"
        value={{
          amount: '260400.54',
          currency: 'USD',
          converted: true,
          rates_as_of: '2026-09-15',
          label: 'USD, converted at fixed rates as of 2026-09-15',
        }}
      />,
    )

    expect(screen.getByText('$260,400.54')).toBeInTheDocument()
    expect(screen.getByText('USD, converted at fixed rates as of 2026-09-15')).toBeInTheDocument()
  })

  it('can put the label on its own line, and shows only the label when a rate is missing', () => {
    const { container } = render(
      <MoneyText
        stacked
        locale="en-US"
        value={{
          amount: null,
          currency: 'USD',
          converted: true,
          rates_as_of: null,
          label: 'USD conversion unavailable: an exchange rate is missing',
        }}
      />,
    )

    expect(screen.getByText('USD conversion unavailable: an exchange rate is missing')).toBeInTheDocument()
    expect(container).not.toHaveTextContent('$')
  })

  it('shows a dash for a missing value', () => {
    render(<MoneyText value={null} />)

    expect(screen.getByText('—')).toBeInTheDocument()
  })
})
