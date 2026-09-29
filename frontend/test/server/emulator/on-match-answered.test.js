// respondToMatch on the Firestore emulator (ADR 0010): the donor's answer as a server write, with
// the refusals the rules used to make — then handleMatchAnswered, the reaction the trigger was:
// the count, the public board row, and the "donor accepted" push to the family (FR-NOTIFY-003).
// FCM is a fake that records.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { handleMatchAnswered, respondToMatch } from '../../../src/server/respond-to-match.js';
import { boardId } from '../../../src/server/board-id.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';

let app;
let db;
let sent;
const quiet = { info() {}, warn() {} };
const messaging = {
    async sendEach(messages) {
        sent.push(...messages);
        return { responses: messages.map(() => ({ success: true })) };
    },
};
const RESPONDED = Timestamp.fromDate(new Date('2026-09-26T03:05:00Z'));
const unanswered = {
    requestId: 'r1',
    donorUid: 'sothea',
    requesterUid: 'family',
    hospitalId: 'calmette',
    response: null,
    respondedAt: null,
};
const accepted = { ...unanswered, response: 'ACCEPTED', respondedAt: RESPONDED };
const answer = (before, after) =>
    handleMatchAnswered({ db, messaging, matchId: 'r1_sothea', before, after, log: quiet });
const respond = (data, caller = { uid: 'sothea', token: {} }) =>
    respondToMatch({ db, messaging, caller, data: { matchId: 'r1_sothea', ...data }, log: quiet });

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
    app = initializeApp({ projectId: PROJECT }, 'on-match-answered-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
    sent = [];
    await db.doc('requests/r1').set({
        createdBy: 'family',
        hospitalId: 'calmette',
        patientBloodType: 'AB+',
        status: 'OPEN',
        alertedCount: 1,
        acceptedCount: 0,
        hospital: { name: 'Calmette Hospital', districtCode: '1202' },
    });
    await db
        .doc('donors/sothea')
        .set({ fullName: 'Nem Sothea', bloodType: 'A+', districtCode: '1201' });
    await db
        .doc('users/family')
        .set({ language: 'en', role: 'REQUESTER', fcmToken: 'family-token' });
});

describe('onMatchAnswered', () => {
    test('an acceptance counts, lands on the board, and pushes the family', async () => {
        expect(await answer(unanswered, accepted)).toEqual({ outcome: 'accepted', pushed: 1 });

        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(1);
        // SEC-REVIEW-003 F-11: the row is not keyed by the uid, and carries none.
        expect((await db.doc('requests/r1/acceptedDonors/sothea').get()).exists).toBe(false);
        expect(
            (await db.doc(`requests/r1/acceptedDonors/${boardId('r1', 'sothea')}`).get()).data(),
        ).toEqual({
            displayName: 'Nem S.',
            bloodType: 'A+',
            districtCode: '1201',
            respondedAt: RESPONDED,
        });
        expect(sent).toHaveLength(1);
        expect(sent[0]).toMatchObject({
            token: 'family-token',
            notification: {
                title: 'A donor accepted your request',
                body: 'AB+ at Calmette Hospital — open LifeLink to see your request',
            },
            data: { type: 'DONOR_ACCEPTED', requestId: 'r1' },
        });
    });

    test('the push names no donor — it can sit on a lock screen', async () => {
        await answer(unanswered, accepted);
        expect(JSON.stringify(sent[0].notification)).not.toContain('Sothea');
    });

    test('a decline changes nothing and pushes nobody', async () => {
        expect(await answer(unanswered, { ...accepted, response: 'DECLINED' })).toEqual({
            outcome: 'ignored',
        });
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(0);
        expect(sent).toEqual([]);
    });

    test("the Function's own notifiedAt stamp is not an answer", async () => {
        expect(await answer(unanswered, { ...unanswered, notifiedAt: RESPONDED })).toEqual({
            outcome: 'ignored',
        });
    });

    test('a redelivered event counts once and pushes once', async () => {
        await answer(unanswered, accepted);
        expect(await answer(unanswered, accepted)).toEqual({ outcome: 'already-handled' });
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(1);
        expect(sent).toHaveLength(1);
    });

    test('a family with no token is fine — the acceptance still counts', async () => {
        await db.doc('users/family').update({ fcmToken: null });
        expect(await answer(unanswered, accepted)).toEqual({ outcome: 'accepted', pushed: 0 });
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(1);
    });
});

describe('respondToMatch', () => {
    beforeEach(() => db.doc('matches/r1_sothea').set(unanswered));

    test('accepting writes the answer and does everything the trigger did', async () => {
        const result = await respond({ response: 'ACCEPTED' });
        expect(result).toMatchObject({
            matchId: 'r1_sothea',
            response: 'ACCEPTED',
            replay: false,
            pushed: 1,
        });
        expect(typeof result.respondedAt).toBe('string');
        const match = (await db.doc('matches/r1_sothea').get()).data();
        expect(match.response).toBe('ACCEPTED');
        expect(match.respondedAt).toBeTruthy();
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(1);
        expect(
            (await db.doc(`requests/r1/acceptedDonors/${boardId('r1', 'sothea')}`).get()).get(
                'displayName',
            ),
        ).toBe('Nem S.');
        expect(sent.map((m) => m.data.type)).toEqual(['DONOR_ACCEPTED']);
    });

    test('declining writes the answer and nothing else', async () => {
        expect(await respond({ response: 'DECLINED' })).toMatchObject({
            response: 'DECLINED',
            pushed: 0,
        });
        expect((await db.doc('matches/r1_sothea').get()).get('response')).toBe('DECLINED');
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(0);
        expect(sent).toEqual([]);
    });

    test('the same answer again is a replay, not a refusal — the offline queue lands twice', async () => {
        await respond({ response: 'ACCEPTED' });
        expect(await respond({ response: 'ACCEPTED' })).toMatchObject({ replay: true });
        expect((await db.doc('requests/r1').get()).get('acceptedCount')).toBe(1);
        expect(sent).toHaveLength(1);
    });

    test('a different answer after one is stored is ALREADY_RESPONDED', async () => {
        await respond({ response: 'DECLINED' });
        await refused(
            respond({ response: 'ACCEPTED' }),
            'failed-precondition',
            'ALREADY_RESPONDED',
        );
        expect((await db.doc('matches/r1_sothea').get()).get('response')).toBe('DECLINED');
    });

    test('a request that closed first is REQUEST_NOT_OPEN', async () => {
        await db.doc('requests/r1').update({ status: 'CANCELLED' });
        await refused(respond({ response: 'ACCEPTED' }), 'failed-precondition', 'REQUEST_NOT_OPEN');
        expect((await db.doc('matches/r1_sothea').get()).get('response')).toBeNull();
    });

    test("someone else's match, or none, is not found — the same from outside", async () => {
        await refused(
            respond({ response: 'ACCEPTED' }, { uid: 'stranger', token: {} }),
            'not-found',
            'MATCH_NOT_FOUND',
        );
        await refused(
            respond({ matchId: 'nope', response: 'ACCEPTED' }),
            'not-found',
            'MATCH_NOT_FOUND',
        );
        await refused(respond({ response: 'ACCEPTED' }, null), 'unauthenticated');
        await refused(respond({ response: 'MAYBE' }), 'invalid-argument');
    });
});
