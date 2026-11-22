import userEvent, { PointerEventsCheckLevel, type Options } from '@testing-library/user-event'

/**
 * userEvent.setup() tuned for Ant Design under jsdom, where every
 * getComputedStyle call is slow (jsdom matches it against all the CSS-in-JS
 * rules Ant Design injects).
 *
 * - The delay stays at its default: user-event yields to the event loop
 *   between actions. Ant Design's Select closes in a later task, so with
 *   `delay: null` a close left over from one pick could land after the
 *   next click had reopened it.
 * - pointerEventsCheck: EachTarget still refuses to click an element with
 *   `pointer-events: none`, but checks each element only the first time it is
 *   used, then reuses that answer for as long as the element exists (the
 *   default re-checks on every call). If a test needs the check repeated,
 *   pass `pointerEventsCheck: PointerEventsCheckLevel.EachApiCall`.
 */
export function setupUser(options: Options = {}) {
  return userEvent.setup({ pointerEventsCheck: PointerEventsCheckLevel.EachTarget, ...options })
}
