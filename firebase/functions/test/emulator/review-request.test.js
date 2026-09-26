// reviewRequest on the Firestore emulator (DEC-015): only an admin, only a PENDING request, a
// rejection needs a reason, and the requester is told.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { reviewRequest } from '../../src/review-request.js';

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
const admin = { uid: 'admin-1', token: { role: 'ADMIN' } };
const review = (data, caller = admin) => reviewRequest({ db, messaging, caller, data: { requestId: 'r1', ...data }, log: quiet });

async function refused(promise, code, detail) {
  const error = await promise.then(() => null, (e) => e);
  expect(error, 'expected a refusal').not.toBeNull();
  expect(error.code).toBe(code);
  if (detail) expect(error.details?.code).toBe(detail);
}

beforeAll(() => {
  app = initializeApp({ projectId: PROJECT }, 'review-request-test');
  db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  sent = [];
  await db.doc('admins/admin-1').set({ displayName: 'Soborey', username: 'soborey' });
  await db.doc('users/family').set({ language: 'km', role: 'REQUESTER', fcmToken: 'family-token' });
  await db.doc('requests/r1').set({
    createdBy: 'family', hospitalId: 'calmette', patientBloodType: 'AB+', unitsNeeded: 1,
    urgency: 'CRITICAL', status: 'PENDING', alertedCount: 0, acceptedCount: 0,
    hospital: { name: 'Calmette Hospital', districtCode: '1202' },
  });
});

describe('reviewRequest', () => {
  test('approving opens the request and records who approved it — the trigger does the matching', async () => {
    expect(await review({ decision: 'APPROVE' })).toEqual({ requestId: 'r1', status: 'OPEN' });
    expect((await db.doc('requests/r1').get()).data()).toMatchObject({ status: 'OPEN', reviewedBy: 'admin-1' });
    // No push here: onRequestApproved tells the requester once donors are alerted.
    expect(sent).toEqual([]);
  });

  test('rejecting needs a reason, stores it, and tells the requester without naming it', async () => {
    await refused(review({ decision: 'REJECT' }), 'invalid-argument', 'REASON_REQUIRED');
    await refused(review({ decision: 'REJECT', reason: '   ' }), 'invalid-argument', 'REASON_REQUIRED');
    await refused(review({ decision: 'REJECT', reason: 'x'.repeat(201) }), 'invalid-argument', 'REASON_REQUIRED');

    await review({ decision: 'REJECT', reason: 'Calmette has no record of this patient.' });
    expect((await db.doc('requests/r1').get()).data()).toMatchObject({
      status: 'REJECTED', rejectReason: 'Calmette has no record of this patient.', reviewedBy: 'admin-1',
    });
    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({ token: 'family-token', data: { type: 'REQUEST_REJECTED', requestId: 'r1' } });
    expect(JSON.stringify(sent[0].notification)).not.toContain('record');
  });

  test('a request that is not PENDING cannot be reviewed — the second admin to click loses', async () => {
    await review({ decision: 'APPROVE' });
    await refused(review({ decision: 'REJECT', reason: 'too late' }), 'failed-precondition', 'NOT_PENDING');
    expect((await db.doc('requests/r1').get()).get('status')).toBe('OPEN');
  });

  test('an unknown request, a bad decision', async () => {
    await refused(review({ requestId: 'nope', decision: 'APPROVE' }), 'not-found', 'REQUEST_NOT_FOUND');
    await refused(review({ decision: 'MAYBE' }), 'invalid-argument');
  });

  test('admins only, by claim and by record', async () => {
    await refused(review({ decision: 'APPROVE' }, null), 'permission-denied');
    await refused(review({ decision: 'APPROVE' }, { uid: 'family', token: {} }), 'permission-denied');
    await db.doc('admins/admin-1').delete();
    await refused(review({ decision: 'APPROVE' }), 'permission-denied');
    expect((await db.doc('requests/r1').get()).get('status')).toBe('PENDING');
  });
});
