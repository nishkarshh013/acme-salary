import { waitFor, within } from '@testing-library/react'
import type { UserEvent } from '@testing-library/user-event'

/** Picks an option in the Ant Design Select labelled `label` inside `container` (e.g. a dialog). */
export async function chooseOption(user: UserEvent, container: HTMLElement, label: string, option: string) {
  await user.click(within(container).getByRole('combobox', { name: label }))
  const item = await waitFor(() => {
    // A closed dropdown can stay mounted while it animates out, with
    // pointer-events: none; only an open one can be clicked.
    const found = document.querySelector<HTMLElement>(
      '.ant-select-dropdown:not(.ant-select-dropdown-hidden):not([style*="pointer-events: none"]) ' +
        `.ant-select-item-option[title="${option}"]`,
    )
    if (!found) throw new Error(`No option "${option}" in ${label}`)
    return found
  })
  await user.click(item)
}
