import userEvent, { PointerEventsCheckLevel, type Options } from '@testing-library/user-event'

/**
 * userEvent.setup() tuned for Ant Design under jsdom, where every
 * getComputedStyle call is slow (jsdom matches it against all the CSS-in-JS
 * rules Ant Design injects).
 *
 * - delay: null types without yielding to the event loop after each key.
 * - pointerEventsCheck: EachTarget still refuses to click an element with
 *   `pointer-events: none`, but checks each element only the first time it is
 *   used, then reuses that answer for as long as the element exists (the
 *   default re-checks on every call). If a test needs the check repeated,
 *   pass `pointerEventsCheck: PointerEventsCheckLevel.EachApiCall`.
 */
export function setupUser(options: Options = {}) {
  return userEvent.setup({ delay: null, pointerEventsCheck: PointerEventsCheckLevel.EachTarget, ...options })
}
