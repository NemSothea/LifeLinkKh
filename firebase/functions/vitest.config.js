import { defineConfig } from 'vitest/config';

// Unit tests are pure. The emulator tests share one Firestore and clear it between tests,
// so they run one at a time.
export default defineConfig({
  test: {
    include: ['test/**/*.test.js'],
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 30_000,
  },
});
