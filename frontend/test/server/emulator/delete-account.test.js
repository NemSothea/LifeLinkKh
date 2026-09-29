// deleteAccount on the Firestore and Auth emulators (DEC-016): personal data deleted, live
// requests closed, open acceptances withdrawn, counts kept anonymous, and the guards.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { deleteAccount, deleteAccountData } from '../../../src/server/delete-account.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
const PROJECT = 'demo-lifelink';
const NOW = new Date('2026-09-26T05:00:00Z');
const fresh = Math.floor(NOW.getTime() / 1000) - 60;

let app;
let db;
let auth;
const quiet = { info() {}, warn() {} };
const me = (overrides = {}) => ({ uid: 'sothea', token: { auth_time: fresh, ...overrides } });
const del = (caller = me()) => deleteAccount({ db, auth, caller, now: NOW, log: quiet });

async function refused(promise, code, detail) {
    const error = await promise.then(
        () => null,
        (e) => e,
    );
    expect(error, 'expected a refusal').not.toBeNull();
    expect(error.code).toBe(code);
    if (detail) expect(error.details?.code).toBe(detail);
}

const request = (createdBy, status, extra = {}) => ({
    createdBy,
    hospitalId: 'calmette',
    patientBloodType: 'AB+',
    unitsNeeded: 2,
    urgency: 'CRITICAL',
    status,
    alertedCount: 2,
    acceptedCount: 1,
    createdAt: Timestamp.fromDate(NOW),
    ...extra,
});

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'delete-account-test');
    db = getFirestore(app);
    auth = getAuth(app);
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

    await auth.createUser({ uid: 'sothea', displayName: 'Nem Sothea' });
    await db
        .doc('users/sothea')
        .set({ displayName: 'Nem Sothea', language: 'km', role: 'DONOR', fcmToken: 'tok' });
    await db.doc('donors/sothea').set({
        fullName: 'Nem Sothea',
        bloodType: 'O-',
        districtCode: '1202',
        lat: 11.57,
        lng: 104.91,
    });

    // As a requester: one open, one pending, one fulfilled — each with a phone number.
    for (const [id, status] of [
        ['mine-open', 'OPEN'],
        ['mine-pending', 'PENDING'],
        ['mine-done', 'FULFILLED'],
    ]) {
        await db.doc(`requests/${id}`).set(request('sothea', status));
        await db
            .doc(`requests/${id}/private/contact`)
            .set({ contactName: 'Nem Sothea', contactPhone: '+85512345678' });
    }
    await db.doc('matches/mine-open_dara').set({
        requestId: 'mine-open',
        donorUid: 'dara',
        requesterUid: 'sothea',
        response: 'ACCEPTED',
    });

    // As a donor: accepted on someone's OPEN request, and on a FULFILLED one they gave blood to.
    await db.doc('requests/theirs-open').set(request('family', 'OPEN'));
    await db
        .doc('requests/theirs-open/acceptedDonors/sothea')
        .set({ displayName: 'Nem Sothea', bloodType: 'O-' });
    await db.doc('matches/theirs-open_sothea').set({
        requestId: 'theirs-open',
        donorUid: 'sothea',
        requesterUid: 'family',
        response: 'ACCEPTED',
    });
    await db.doc('requests/theirs-done').set(request('family', 'FULFILLED'));
    await db
        .doc('requests/theirs-done/acceptedDonors/sothea')
        .set({ displayName: 'Nem Sothea', bloodType: 'O-' });
    await db.doc('matches/theirs-done_sothea').set({
        requestId: 'theirs-done',
        donorUid: 'sothea',
        requesterUid: 'family',
        response: 'ACCEPTED',
    });
    await db.doc('donations/theirs-done_sothea').set({
        donorUid: 'sothea',
        hospitalId: 'calmette',
        requestId: 'theirs-done',
        confirmedBy: 'admin-1',
    });
});

describe('deleteAccount', () => {
    test('a report they filed keeps its reason but loses who filed it and the note (DEC-019)', async () => {
        await db.doc('reports/theirs-open_sothea').set({
            requestId: 'theirs-open',
            reporterUid: 'sothea',
            reason: 'MONEY',
            note: 'Asked me for $50',
        });
        await del();
        expect((await db.doc('reports/theirs-open_sothea').get()).data()).toEqual({
            requestId: 'theirs-open',
            reporterUid: null,
            reason: 'MONEY',
            note: null,
        });
    });

    test('personal data is gone: profile, push token, phone numbers, board name, sign-in', async () => {
        await del();
        expect((await db.doc('users/sothea').get()).exists).toBe(false);
        expect((await db.doc('donors/sothea').get()).exists).toBe(false);
        for (const id of ['mine-open', 'mine-pending', 'mine-done']) {
            expect((await db.doc(`requests/${id}/private/contact`).get()).exists).toBe(false);
        }
        expect((await db.doc('requests/theirs-open/acceptedDonors/sothea').get()).exists).toBe(
            false,
        );
        expect((await db.doc('requests/theirs-done/acceptedDonors/sothea').get()).exists).toBe(
            false,
        );
        await expect(auth.getUser('sothea')).rejects.toMatchObject({ code: 'auth/user-not-found' });
    });

    test('their live requests are closed; a finished one is kept with no creator', async () => {
        expect(await del()).toMatchObject({ requestsClosed: 2 });
        for (const id of ['mine-open', 'mine-pending']) {
            expect((await db.doc(`requests/${id}`).get()).data()).toMatchObject({
                status: 'CANCELLED',
                cancelReason: 'ACCOUNT_DELETED',
                createdBy: null,
            });
        }
        expect((await db.doc('requests/mine-done').get()).data()).toMatchObject({
            status: 'FULFILLED',
            createdBy: null,
        });
        expect((await db.doc('matches/mine-open_dara').get()).get('requesterUid')).toBeNull();
    });

    test('an acceptance on an OPEN request is withdrawn and the count comes down', async () => {
        expect(await del()).toMatchObject({ acceptancesWithdrawn: 1 });
        expect((await db.doc('matches/theirs-open_sothea').get()).data()).toMatchObject({
            response: 'WITHDRAWN',
            donorUid: null,
        });
        expect((await db.doc('requests/theirs-open').get()).get('acceptedCount')).toBe(0);
    });

    test('history is kept anonymous: a finished request keeps its count, the donation stays', async () => {
        await del();
        expect((await db.doc('requests/theirs-done').get()).get('acceptedCount')).toBe(1);
        expect((await db.doc('matches/theirs-done_sothea').get()).data()).toMatchObject({
            response: 'ACCEPTED',
            donorUid: null,
        });
        expect((await db.doc('donations/theirs-done_sothea').get()).data()).toMatchObject({
            donorUid: null,
            requestId: 'theirs-done',
        });
    });

    test('running it twice changes nothing the second time — a retry is safe', async () => {
        await deleteAccountData({ db, auth, uid: 'sothea', log: quiet });
        expect(await deleteAccountData({ db, auth, uid: 'sothea', log: quiet })).toEqual({
            requestsClosed: 0,
            acceptancesWithdrawn: 0,
            recordsAnonymised: 0,
        });
        expect((await db.doc('requests/theirs-open').get()).get('acceptedCount')).toBe(0);
    });

    test('needs a sign-in from the last five minutes', async () => {
        await refused(
            del(me({ auth_time: fresh - 10 * 60 })),
            'failed-precondition',
            'RECENT_SIGN_IN_REQUIRED',
        );
        await refused(
            del(me({ auth_time: undefined })),
            'failed-precondition',
            'RECENT_SIGN_IN_REQUIRED',
        );
        expect((await db.doc('users/sothea').get()).exists).toBe(true);
    });

    test('signed out is refused, and an admin cannot delete itself from the app', async () => {
        await refused(del(null), 'unauthenticated');
        await refused(del(me({ role: 'ADMIN' })), 'failed-precondition', 'ADMIN_ACCOUNT');
        await db.doc('admins/sothea').set({ username: 'soborey' });
        await refused(del(), 'failed-precondition', 'ADMIN_ACCOUNT');
        expect((await db.doc('users/sothea').get()).exists).toBe(true);
    });

    test("someone else's data is untouched", async () => {
        await db.doc('users/dara').set({ displayName: 'Sok Dara', language: 'km', role: 'DONOR' });
        await del();
        expect((await db.doc('users/dara').get()).exists).toBe(true);
        expect((await db.doc('requests/theirs-open').get()).get('createdBy')).toBe('family');
        expect((await db.doc('matches/mine-open_dara').get()).get('donorUid')).toBe('dara');
    });
});
