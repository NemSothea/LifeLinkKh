// confirmDonation on the Firestore emulator: PortalService.confirmDonation's three writes and
// every refusal it made, and the at-most-once donation. v1 has no hospital staff: admins only.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
    confirmDonation,
    dateToTimestamp,
    phnomPenhToday,
} from '../../../src/server/confirm-donation.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';
const NOW = new Date('2026-09-26T05:00:00Z'); // 12:00 in Phnom Penh

let app;
let db;
const quiet = { info() {}, warn() {} };
const admin = { uid: 'admin-1', token: { role: 'ADMIN' } };
const confirm = (data, caller = admin) =>
    confirmDonation({
        db,
        caller,
        data: { requestId: 'r1', matchId: 'r1_d1', donatedOn: '2026-09-25', ...data },
        now: NOW,
        log: quiet,
    });

async function refused(promise, code, detail) {
    const error = await promise.then(
        () => null,
        (e) => e,
    );
    expect(error, 'expected a refusal').not.toBeNull();
    expect(error.code).toBe(code);
    if (detail) expect(error.details?.code).toBe(detail);
}

async function acceptedMatch(donorUid, fullName, extra = {}) {
    await db
        .doc(`donors/${donorUid}`)
        .set({ fullName, bloodType: 'O+', districtCode: '1201', lastDonationDate: null, ...extra });
    await db
        .doc(`matches/r1_${donorUid}`)
        .set({ requestId: 'r1', donorUid, hospitalId: 'calmette', response: 'ACCEPTED' });
}

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'confirm-donation-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
    await db.doc('admins/admin-1').set({ displayName: 'Soborey', username: 'soborey' });
    await db
        .doc('requests/r1')
        .set({
            createdBy: 'family',
            hospitalId: 'calmette',
            unitsNeeded: 2,
            status: 'OPEN',
            acceptedCount: 1,
        });
    await acceptedMatch('d1', 'Nem Sothea');
});

describe('confirmDonation', () => {
    test("a man's next eligible date is 90 days on, a woman's 120 (DEC-019)", async () => {
        await acceptedMatch('d1', 'Nem Sothea', { sex: 'M' });
        expect((await confirm()).donorNextEligibleOn).toBe('2026-12-24');
    });

    test("records the donation, starts the cooldown, and answers in ConfirmDonationResponse's shape", async () => {
        expect(await confirm()).toEqual({
            id: 'r1_d1',
            donorDisplayName: 'Nem Sothea',
            donatedOn: '2026-09-25',
            requestStatus: 'OPEN',
            // No sex on file: the 120-day wait (DEC-019).
            donorNextEligibleOn: '2027-01-23',
        });
        expect((await db.doc('donations/r1_d1').get()).data()).toMatchObject({
            donorUid: 'd1',
            hospitalId: 'calmette',
            requestId: 'r1',
            confirmedBy: 'admin-1',
            donatedOn: dateToTimestamp('2026-09-25'),
        });
        expect((await db.doc('donors/d1').get()).get('lastDonationDate')).toEqual(
            dateToTimestamp('2026-09-25'),
        );
    });

    test('the date is stored as midnight in Phnom Penh, the way the app writes one', () => {
        expect(dateToTimestamp('2026-09-25').toDate().toISOString()).toBe(
            '2026-09-24T17:00:00.000Z',
        );
    });

    test('the last unit a request needed marks it FULFILLED', async () => {
        await acceptedMatch('d2', 'Sok Dara');
        await confirm();
        expect((await confirm({ matchId: 'r1_d2' })).requestStatus).toBe('FULFILLED');
        expect((await db.doc('requests/r1').get()).get('status')).toBe('FULFILLED');
    });

    test('confirming the same donor twice is refused, and writes nothing the second time', async () => {
        await confirm();
        await refused(
            confirm({ donatedOn: '2026-09-26' }),
            'already-exists',
            'DONATION_ALREADY_CONFIRMED',
        );
        expect((await db.doc('donors/d1').get()).get('lastDonationDate')).toEqual(
            dateToTimestamp('2026-09-25'),
        );
    });

    // A request the family withdrew, or the admin rejected, has no need left to fill — and a
    // confirmation against it would still start the donor's cooldown and count in the metrics.
    for (const status of ['CANCELLED', 'REJECTED', 'FULFILLED', 'PENDING']) {
        test(`a ${status} request takes no donation`, async () => {
            await db.doc('requests/r1').update({ status });
            await refused(confirm(), 'failed-precondition', 'REQUEST_NOT_OPEN');
            expect((await db.collection('donations').get()).size).toBe(0);
            expect((await db.doc('donors/d1').get()).get('lastDonationDate')).toBeNull();
        });
    }

    test('two clicks racing write one donation', async () => {
        const results = await Promise.allSettled([confirm(), confirm()]);
        expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
        expect((await db.collection('donations').get()).size).toBe(1);
    });

    test('a backdated donation does not move the cooldown backwards', async () => {
        await db.doc('donors/d1').update({ lastDonationDate: dateToTimestamp('2026-09-20') });
        await confirm({ donatedOn: '2026-08-01' });
        expect((await db.doc('donors/d1').get()).get('lastDonationDate')).toEqual(
            dateToTimestamp('2026-09-20'),
        );
    });

    test('today in Phnom Penh is allowed; tomorrow is not', async () => {
        expect(phnomPenhToday(new Date('2026-09-25T18:00:00Z'))).toBe('2026-09-26');
        await confirm({ donatedOn: '2026-09-26' });
        await db.doc('donations/r1_d1').delete();
        await refused(
            confirm({ donatedOn: '2026-09-27' }),
            'invalid-argument',
            'DONATION_DATE_IN_FUTURE',
        );
        await refused(confirm({ donatedOn: 'yesterday' }), 'invalid-argument');
    });

    test('an unknown request is not found', async () => {
        await refused(confirm({ requestId: 'nope' }), 'not-found', 'REQUEST_NOT_FOUND');
    });

    test('a declined, unanswered or mismatched match is refused', async () => {
        await db.doc('matches/r1_d1').update({ response: 'DECLINED' });
        await refused(confirm(), 'failed-precondition', 'MATCH_NOT_ACCEPTED');
        await db.doc('matches/r1_d1').update({ response: null });
        await refused(confirm(), 'failed-precondition', 'MATCH_NOT_ACCEPTED');
        await db
            .doc('matches/r2_d1')
            .set({ requestId: 'r2', donorUid: 'd1', response: 'ACCEPTED' });
        await refused(confirm({ matchId: 'r2_d1' }), 'failed-precondition', 'MATCH_NOT_ACCEPTED');
    });

    test('admins only, by claim and by record', async () => {
        await refused(confirm({}, null), 'permission-denied');
        await refused(confirm({}, { uid: 'd1', token: {} }), 'permission-denied');
        // A HOSPITAL claim is not a role in v1, even at the request's own hospital.
        await refused(
            confirm({}, { uid: 'staff-1', token: { role: 'HOSPITAL', hospitalId: 'calmette' } }),
            'permission-denied',
        );
        // A revoked admin's token still says ADMIN for up to an hour; the record is gone.
        await db.doc('admins/admin-1').delete();
        await refused(confirm(), 'permission-denied');
        expect((await db.collection('donations').get()).size).toBe(0);
    });
});
