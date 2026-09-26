// handleRequestCreated end to end on the Firestore emulator: the documents it reads, the
// documents it writes, and what it would have pushed. FCM itself is a fake that records.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { handleRequestCreated } from '../../src/on-request-created.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';

let app;
let db;
let sent;
const quiet = { info() {}, warn() {} };
const messaging = {
  async sendEach(messages) {
    sent.push(...messages);
    return {
      responses: messages.map((m) => (m.token === 'dead-token'
        ? { success: false, error: { code: 'messaging/registration-token-not-registered' } }
        : { success: true })),
    };
  },
};
const NOW = new Date('2026-09-26T03:00:00Z');
const handle = (requestId, now = NOW) => handleRequestCreated({ db, messaging, requestId, now, log: quiet });

async function clear() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
}

async function postRequest(id, overrides = {}) {
  await db.doc(`requests/${id}`).set({
    createdBy: 'requester',
    hospitalId: 'calmette',
    patientBloodType: 'AB+',
    unitsNeeded: 2,
    urgency: 'CRITICAL',
    status: 'OPEN',
    alertedCount: 0,
    acceptedCount: 0,
    createdAt: Timestamp.fromDate(NOW),
    updatedAt: Timestamp.fromDate(NOW),
    ...overrides,
  });
}

async function donor(uid, { token, language = 'km', ...fields } = {}) {
  await db.doc(`donors/${uid}`).set({
    fullName: uid, bloodType: 'A+', districtCode: '1201', lastDonationDate: null,
    isAvailable: true, lat: 11.5806, lng: 104.9165, geohash: 'w649gkjvgs', ...fields,
  });
  await db.doc(`users/${uid}`).set({ language, role: 'DONOR', fcmToken: token ?? null });
}

beforeAll(() => {
  app = initializeApp({ projectId: PROJECT }, 'on-request-created-test');
  db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  await clear();
  sent = [];
  await db.doc('hospitals/calmette').set({
    name: 'Calmette Hospital', lat: 11.581329, lng: 104.91569, districtCode: '1202',
  });
});

describe('onRequestCreated', () => {
  test('the golden path: a matching donor gets a match, a push, and notifiedAt', async () => {
    await donor('sothea', { token: 'token-1', language: 'en' });
    await postRequest('r1');

    expect(await handle('r1')).toMatchObject({ outcome: 'matched', alerted: 1, pushed: 1 });

    const match = (await db.doc('matches/r1_sothea').get()).data();
    expect(match).toMatchObject({ requestId: 'r1', donorUid: 'sothea', requesterUid: 'requester',
      hospitalId: 'calmette', response: null, distanceKm: 0 });
    expect(match.notifiedAt).toBeInstanceOf(Timestamp);

    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({
      token: 'token-1',
      notification: { title: 'Urgent blood request', body: 'AB+ needed at Calmette Hospital' },
      data: { type: 'REQUEST_ALERT', requestId: 'r1' },
    });

    const request = (await db.doc('requests/r1').get()).data();
    expect(request.alertedCount).toBe(1);
    expect(request.hospital).toEqual({ name: 'Calmette Hospital', districtCode: '1202' });
    expect(request.matchedAt).toBeInstanceOf(Timestamp);
  });

  test('a donor with no token is matched but SILENT — preflight-match.sql\'s verdict', async () => {
    await donor('no-token');
    await postRequest('r1');
    expect(await handle('r1')).toMatchObject({ alerted: 1, pushed: 0 });
    expect((await db.doc('matches/r1_no-token').get()).get('notifiedAt')).toBeNull();
  });

  test('the requester\'s own donor profile is not alerted', async () => {
    await donor('requester', { token: 'self' });
    await postRequest('r1');
    expect(await handle('r1')).toMatchObject({ alerted: 0 });
    expect(sent).toEqual([]);
  });

  test('a donor in cooldown, unavailable, or incompatible is not alerted', async () => {
    await donor('cooldown', { token: 'a', lastDonationDate: Timestamp.fromDate(new Date('2026-09-01T00:00:00+07:00')) });
    await donor('away', { token: 'b', isAvailable: false });
    await donor('o-neg', { token: 'c', bloodType: 'O-' });
    await postRequest('r1', { patientBloodType: 'O-' });
    expect(await handle('r1')).toMatchObject({ alerted: 1 });
    expect(sent.map((m) => m.token)).toEqual(['c']);
  });

  test('a redelivered event matches nothing twice and pushes nobody twice', async () => {
    await donor('sothea', { token: 'token-1' });
    await postRequest('r1');
    await handle('r1');
    expect(await handle('r1')).toEqual({ outcome: 'already-handled' });
    expect(sent).toHaveLength(1);
  });

  test('a dead token is cleared, so the next request does not pay for it', async () => {
    await donor('gone', { token: 'dead-token' });
    await postRequest('r1');
    await handle('r1');
    expect((await db.doc('users/gone').get()).get('fcmToken')).toBeNull();
    expect((await db.doc('matches/r1_gone').get()).get('notifiedAt')).toBeNull();
  });

  test('the sixth request in ten minutes is closed before it alerts anyone', async () => {
    await donor('sothea', { token: 'token-1' });
    for (let i = 1; i <= 6; i++) await postRequest(`r${i}`);
    expect(await handle('r6')).toEqual({ outcome: 'rate-limited' });
    expect((await db.doc('requests/r6').get()).data()).toMatchObject({ status: 'CANCELLED', cancelReason: 'RATE_LIMITED' });
    expect(sent).toEqual([]);
  });
});
