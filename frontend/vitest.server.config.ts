import path from 'node:path';
import { defineConfig } from 'vitest/config';

// The server-side functions (ADR 0010): plain Node, no DOM. `test/server/unit` is pure;
// `test/server/emulator` shares one Firestore emulator and clears it between tests, so those
// files run one at a time — `npm run test:server:emulator` starts the emulators around them.
export default defineConfig({
    test: {
        environment: 'node',
        include: ['test/server/**/*.test.js'],
        fileParallelism: false,
        testTimeout: 20_000,
        hookTimeout: 30_000,
    },
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
            'server-only': path.resolve(__dirname, './test/server/stubs/server-only.js'),
        },
    },
});
