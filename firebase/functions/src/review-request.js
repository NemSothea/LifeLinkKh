// DEC-015: the admin approves or rejects a PENDING request. The only way a request leaves
// PENDING other than its creator cancelling it — the rules refuse the transition to every client.
// Approving only flips the status; the onRequestApproved trigger does the matching, so a retried
// approval can never alert anyone twice.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { notifyRequester } from './on-request-created.js';
import { isAdmin } from './portal-accounts.js';

export const REASON_MAX = 200;

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {{uid: string, token: object}|null|undefined} deps.caller
 * @param {{requestId: string, decision: 'APPROVE'|'REJECT', reason?: string}} deps.data
 */
export async function reviewRequest({ db, messaging, caller, data, log = console }) {
  if (!(await isAdmin(db, caller))) throw new HttpsError('permission-denied', 'Admins only.');

  const { requestId, decision } = data ?? {};
  if (typeof requestId !== 'string' || requestId === '') {
    throw new HttpsError('invalid-argument', 'requestId is required.');
  }
  if (decision !== 'APPROVE' && decision !== 'REJECT') {
    throw new HttpsError('invalid-argument', 'decision is APPROVE or REJECT.');
  }
  const reason = typeof data.reason === 'string' ? data.reason.trim() : '';
  if (decision === 'REJECT' && (reason === '' || reason.length > REASON_MAX)) {
    // The requester reads this in the app. An empty one tells them nothing they can fix.
    throw new HttpsError('invalid-argument', `A rejection needs a reason of 1–${REASON_MAX} characters.`, { code: 'REASON_REQUIRED' });
  }

  const requestRef = db.doc(`requests/${requestId}`);
  const request = await db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    if (!snap.exists) throw new HttpsError('not-found', 'No such request.', { code: 'REQUEST_NOT_FOUND' });
    if (snap.get('status') !== 'PENDING') {
      // Cancelled by its creator, closed by the rate limit, or reviewed by another admin first.
      throw new HttpsError('failed-precondition', 'This request is no longer waiting for review.', { code: 'NOT_PENDING' });
    }
    tx.update(requestRef, decision === 'APPROVE'
      ? { status: 'OPEN', reviewedBy: caller.uid, reviewedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() }
      : { status: 'REJECTED', rejectReason: reason, reviewedBy: caller.uid, reviewedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
    return snap.data();
  });

  // The approval push is sent by onRequestApproved once donors are alerted; a rejection has no
  // later step, so it is told here.
  if (decision === 'REJECT') {
    await notifyRequester({ db, messaging, requestId, request, type: 'REQUEST_REJECTED', log });
  }
  log.info(`request ${requestId} ${decision === 'APPROVE' ? 'approved' : 'rejected'} by=${caller.uid}`);
  return { requestId, status: decision === 'APPROVE' ? 'OPEN' : 'REJECTED' };
}
