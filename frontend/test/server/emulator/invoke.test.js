// invoke() on the Auth and Firestore emulators (ADR 0010): the token is verified before any
// handler runs, a bad one is "no caller" and refused by the handler, and an unknown name is
// not-found. The one test of the route's shape lives with it.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
process.env.FIREBASE_PROJECT_ID = 'demo-lifelink';
const PROJECT = 'demo-lifelink';

// After the env is set: the module initialises the Admin SDK from it on first use.
const { invoke } = await import('../../../src/server/invoke.ts');
const { POST } = await import('../../../src/app/api/functions/[name]/route.ts');

let app;
let db;

/** A real, emulator-issued ID token for a fresh user — what the app sends. */
async function signUp(email) {
    const res = await fetch(
        `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=any`,
        {
            method: 'POST',
            headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ email, password: 'password-1234', returnSecureToken: true }),
        },
    );
    const body = await res.json();
    return { uid: body.localId, token: body.idToken };
}

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'invoke-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
    await fetch(
        `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/accounts`,
        { method: 'DELETE' },
    );
    await db.doc('hospitals/calmette').set({ name: 'Calmette Hospital', districtCode: '1202' });
});

const draft = {
    hospitalId: 'calmette',
    patientBloodType: 'AB+',
    unitsNeeded: 1,
    urgency: 'URGENT',
    contactName: 'Chea Srey',
    contactPhone: '+85512345678',
};

describe('invoke', () => {
    test('a verified token is the caller', async () => {
        const { uid, token } = await signUp('family@example.com');
        const outcome = await invoke('createRequest', draft, token);
        expect(outcome.ok).toBe(true);
        expect((await db.doc(`requests/${outcome.result.requestId}`).get()).get('createdBy')).toBe(
            uid,
        );
    });

    test('no token, a forged token: no caller, and the handler refuses', async () => {
        for (const token of [null, 'not-a-jwt', 'eyJhbGciOiJub25lIn0.eyJzdWIiOiJ4In0.']) {
            const outcome = await invoke('createRequest', draft, token);
            expect(outcome.ok).toBe(false);
            expect(outcome.error.code).toBe('unauthenticated');
        }
        expect((await db.collection('requests').get()).size).toBe(0);
    });

    test('an unknown function is not-found; an admin function refuses a donor', async () => {
        const { token } = await signUp('donor@example.com');
        expect((await invoke('nope', {}, token)).error.code).toBe('not-found');
        expect(
            (await invoke('reviewRequest', { requestId: 'r1', decision: 'APPROVE' }, token)).error
                .code,
        ).toBe('permission-denied');
    });
});

describe('POST /api/functions/{name}', () => {
    const post = (name, body, token) =>
        POST(
            new Request(`http://portal.test/api/functions/${name}`, {
                method: 'POST',
                headers: {
                    'content-type': 'application/json',
                    ...(token ? { authorization: `Bearer ${token}` } : {}),
                },
                body: typeof body === 'string' ? body : JSON.stringify(body),
            }),
            { params: Promise.resolve({ name }) },
        );

    test('speaks the callable protocol: {data} in, {result} out', async () => {
        const { token } = await signUp('family@example.com');
        const res = await post('createRequest', { data: draft }, token);
        expect(res.status).toBe(200);
        expect(await res.json()).toMatchObject({ result: { status: 'PENDING' } });
    });

    test('a refusal is {error: {status, message, details}} with the matching HTTP status', async () => {
        const { token } = await signUp('family@example.com');
        const res = await post('createRequest', { data: { ...draft, unitsNeeded: 0 } }, token);
        expect(res.status).toBe(400);
        expect(await res.json()).toEqual({
            error: {
                status: 'INVALID_ARGUMENT',
                message: 'unitsNeeded is 1–20.',
                details: { code: 'INVALID_REQUEST' },
            },
        });
        expect((await post('createRequest', { data: draft }, null)).status).toBe(401);
        expect((await post('createRequest', '{not json', token)).status).toBe(400);
    });
});
