// createRequest on the Firestore emulator (ADR 0010): the shape check the rules made, the rate
// limit up front, the hospital's name stamped on, and the two documents in one batch.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { createRequest } from '../../../src/server/create-request.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';
const NOW = new Date('2026-09-26T03:00:00Z');

let app;
let db;
const quiet = { info() {}, warn() {} };
const family = { uid: 'family', token: {} };
const draft = {
    hospitalId: 'calmette',
    patientBloodType: 'AB+',
    unitsNeeded: 2,
    urgency: 'CRITICAL',
    contactName: 'Chea Srey',
    contactPhone: '+85512345678',
};
const create = (data = {}, caller = family) =>
    createRequest({ db, caller, data: { ...draft, ...data }, now: NOW, log: quiet });

async function refused(promise, code, detail) {
    const error = await promise.then(
        () => null,
        (e) => e,
    );
    expect(error, 'expected a refusal').not.toBeNull();
    expect(error.code).toBe(code);
    if (detail) expect(error.details?.code).toBe(detail);
}

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'create-request-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
    await db.doc('hospitals/calmette').set({ name: 'Calmette Hospital', districtCode: '1202' });
    await db.doc('users/family').set({ language: 'km', role: 'REQUESTER' });
});

describe('createRequest', () => {
    test('writes the request as PENDING with the hospital stamped on, and the contact beside it', async () => {
        const { requestId, status } = await create();
        expect(status).toBe('PENDING');
        const request = (await db.doc(`requests/${requestId}`).get()).data();
        expect(request).toMatchObject({
            createdBy: 'family',
            hospitalId: 'calmette',
            hospital: { name: 'Calmette Hospital', districtCode: '1202' },
            patientBloodType: 'AB+',
            unitsNeeded: 2,
            urgency: 'CRITICAL',
            status: 'PENDING',
            alertedCount: 0,
            acceptedCount: 0,
        });
        expect(request.createdAt).toBeInstanceOf(Timestamp);
        expect((await db.doc(`requests/${requestId}/private/contact`).get()).data()).toEqual({
            contactName: 'Chea Srey',
            contactPhone: '+85512345678',
        });
    });

    test('validNewRequest(), line for line', async () => {
        await refused(create({ hospitalId: '' }), 'invalid-argument', 'INVALID_REQUEST');
        // SEC-REVIEW-003 F-10: a path, not an id.
        await refused(
            create({ hospitalId: 'calmette/private/x' }),
            'invalid-argument',
            'INVALID_REQUEST',
        );
        await refused(create({ patientBloodType: 'X+' }), 'invalid-argument', 'INVALID_REQUEST');
        await refused(create({ unitsNeeded: 0 }), 'invalid-argument', 'INVALID_REQUEST');
        await refused(create({ unitsNeeded: 21 }), 'invalid-argument', 'INVALID_REQUEST');
        await refused(create({ unitsNeeded: 1.5 }), 'invalid-argument', 'INVALID_REQUEST');
        await refused(create({ urgency: 'NOW' }), 'invalid-argument', 'INVALID_REQUEST');
        await refused(create({ contactName: '  ' }), 'invalid-argument', 'INVALID_REQUEST');
        for (const bad of [
            '012345678',
            '+85513345678',
            '+8551234567',
            '+855181234567 ',
            '+1 555 0100',
        ]) {
            await refused(create({ contactPhone: bad }), 'invalid-argument', 'INVALID_REQUEST');
        }
        await refused(create({ hospitalId: 'nowhere' }), 'not-found', 'HOSPITAL_NOT_FOUND');
        await refused(create({}, null), 'unauthenticated');
        expect((await db.collection('requests').get()).size).toBe(0);
        // A 9-digit prefix is a mobile too.
        await create({ contactPhone: '+855181234567' });
    });

    test('the sixth request in ten minutes is refused, not written and closed', async () => {
        for (let i = 0; i < 5; i++) await create();
        await refused(create(), 'resource-exhausted', 'RATE_LIMITED');
        expect((await db.collection('requests').get()).size).toBe(5);
        // Another family is not held back by this one.
        await db.doc('users/other').set({ language: 'km', role: 'REQUESTER' });
        await create({}, { uid: 'other', token: {} });
    });

    // SEC-REVIEW-003 F-05: a token issued before deleteAccount is refused by invoke's
    // checkRevoked; with no profile left, createRequest refuses as well.
    test('a caller with no user profile — deleted, or never signed up — posts nothing', async () => {
        await db.doc('users/family').delete();
        await refused(create(), 'failed-precondition', 'NO_PROFILE');
        expect((await db.collection('requests').get()).size).toBe(0);
    });
});
