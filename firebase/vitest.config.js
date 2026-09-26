import { defineConfig } from 'vitest/config';

// One emulator, cleared before every test — so files and tests run one at a time.
export default defineConfig({
  test: {
    include: ['rules-tests/**/*.test.js'],
    fileParallelism: false,
    sequence: { concurrent: false },
    testTimeout: 20_000,
    hookTimeout: 30_000,
  },
});
