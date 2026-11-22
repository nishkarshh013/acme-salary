import react from '@vitejs/plugin-react'
import { defineConfig } from 'vitest/config'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:3000',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
    restoreMocks: true,
    // One worker per physical core (this machine has 4 cores, 8 threads).
    // Each test file is CPU-bound in jsdom; with Vitest's default of one
    // worker per thread minus one (7), files share cores and every test
    // runs about twice as slowly, enough to miss Testing Library's waits.
    maxWorkers: 4,
    // Like Testing Library's wait timeout (src/test/setup.ts), this only
    // matters when a test is failing, and it keeps slower machines from
    // failing on timing alone. Test speed is tracked with the slowest-tests
    // report instead.
    testTimeout: 15_000,
    // Same results on every machine: the browser clock's local date is a UTC date.
    env: { TZ: 'UTC' },
    unstubGlobals: true,
  },
})
