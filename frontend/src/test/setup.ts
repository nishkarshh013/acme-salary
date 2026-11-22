import '@testing-library/jest-dom/vitest'
import { cleanup, configure } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

afterEach(() => cleanup())

// findBy and waitFor give up after 3 s instead of 1 s. A wait only takes
// that long when a test is failing anyway, and this keeps slower machines
// (or a laptop in power-saver mode) from failing on timing alone.
configure({ asyncUtilTimeout: 3000 })

// Ant Design's responsive helpers call matchMedia, which jsdom doesn't implement.
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
})

// jsdom doesn't implement getComputedStyle for pseudo-elements and logs an error when asked.
const getComputedStyle = window.getComputedStyle.bind(window)
window.getComputedStyle = (element: Element) => getComputedStyle(element)

// Ant Design's Menu measures itself with ResizeObserver, which jsdom lacks.
class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}
window.ResizeObserver ??= ResizeObserverStub

// React Testing Library only recognises Jest's fake timers: after each user
// action it waits on a setTimeout(0), and advances the clock itself only when
// a `jest` global exists. Without this, that wait never ends under Vitest's
// fake timers. It has no effect while timers are real.
;(globalThis as unknown as { jest: { advanceTimersByTime: (ms: number) => void } }).jest = {
  advanceTimersByTime: (ms) => vi.advanceTimersByTime(ms),
}
