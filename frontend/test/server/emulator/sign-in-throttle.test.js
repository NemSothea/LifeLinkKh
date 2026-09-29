// Password sign-in throttling per IP (SEC-REVIEW-003 F-08) on the Firestore emulator.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
    SIGN_IN_LIMIT,
    clearSignInFailures,
    recordSignInFailure,
    signInBlocked,
} from '../../../src/server/sign-in-throttle.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';
const NOW = Date.parse('2026-09-29T10:00:00Z');

let app;
let db;

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'sign-in-throttle-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
});

describe('sign-in throttle', () => {
    test('the tenth failure from one IP blocks it; another IP is not held back', async () => {
        for (let i = 0; i < SIGN_IN_LIMIT.maxFailures - 1; i++) {
            await recordSignInFailure(db, '203.0.113.7', NOW + i);
        }
        expect(await signInBlocked(db, '203.0.113.7', NOW + 20)).toBe(false);
        await recordSignInFailure(db, '203.0.113.7', NOW + 20);
        expect(await signInBlocked(db, '203.0.113.7', NOW + 21)).toBe(true);
        expect(await signInBlocked(db, '198.51.100.1', NOW + 21)).toBe(false);
    });

    test('the window passes, and a success clears the count', async () => {
        for (let i = 0; i < SIGN_IN_LIMIT.maxFailures; i++) {
            await recordSignInFailure(db, '203.0.113.7', NOW + i);
        }
        expect(await signInBlocked(db, '203.0.113.7', NOW + SIGN_IN_LIMIT.windowMs + 10)).toBe(
            false,
        );
        await clearSignInFailures(db, '203.0.113.7');
        expect(await signInBlocked(db, '203.0.113.7', NOW + 20)).toBe(false);
    });

    test('the address is not stored, only a hash of it', async () => {
        await recordSignInFailure(db, '203.0.113.7', NOW);
        const docs = (await db.collection('signInThrottle').get()).docs;
        expect(docs).toHaveLength(1);
        expect(docs[0].id).not.toContain('203');
        expect(JSON.stringify(docs[0].data())).not.toContain('203.0.113.7');
    });
});
