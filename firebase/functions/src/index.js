// Cloud Functions for LifeLink KH (ADR 0009). Each trigger is a thin wrapper: the logic lives
// in its own module so tests can call it without deploying anything.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import { handleMatchAnswered } from './on-match-answered.js';
import { handleRequestApproved, handleRequestCreated } from './on-request-created.js';
import { reviewRequest as reviewRequestHandler } from './review-request.js';
import { deleteAccount as deleteAccountHandler } from './delete-account.js';
import { confirmDonation as confirmDonationHandler } from './confirm-donation.js';

initializeApp();

// Singapore is the nearest region to Phnom Penh. One instance at most: a class pilot does not
// need a fleet, and a runaway loop cannot fan out into a bill.
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 1 });

/**
 * FCM has no emulator. On a `demo-` project (the emulator, the tests) every message is written
 * to `_outbox` instead of sent, so a test can read exactly what a donor would have received.
 * No rule matches `_outbox`, so no client can read it.
 */
function messaging() {
  if (!process.env.GCLOUD_PROJECT?.startsWith('demo-')) return getMessaging();
  const db = getFirestore();
  return {
    async sendEach(messages) {
      await Promise.all(messages.map((m) => db.collection('_outbox').add(m)));
      return { responses: messages.map(() => ({ success: true })) };
    },
  };
}

// DEC-015: a new request is PENDING. On create: the rate limit and the hospital's name, nothing
// more. Matching and the donor alert wait for an admin's approval.
export const onRequestCreated = onDocumentCreated('requests/{requestId}', (event) =>
  handleRequestCreated({
    db: getFirestore(),
    requestId: event.params.requestId,
    log: logger,
  }),
);

// PENDING → OPEN is the admin's approval (reviewRequest). Only that transition matches.
export const onRequestApproved = onDocumentUpdated('requests/{requestId}', (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (before?.status !== 'PENDING' || after?.status !== 'OPEN') return null;
  return handleRequestApproved({
    db: getFirestore(),
    messaging: messaging(),
    requestId: event.params.requestId,
    log: logger,
  });
});

export const onMatchAnswered = onDocumentUpdated('matches/{matchId}', (event) =>
  handleMatchAnswered({
    db: getFirestore(),
    messaging: messaging(),
    matchId: event.params.matchId,
    before: event.data?.before.data(),
    after: event.data?.after.data(),
    log: logger,
  }),
);

// ── Portal (phase 5) ────────────────────────────────────────────────────────────────────────────
// Callable, so Firebase verifies the caller's ID token before the handler runs: `request.auth`
// is the verified uid and claims, or absent. The handler checks for an admin itself.
export const confirmDonation = onCall((request) =>
  confirmDonationHandler({
    db: getFirestore(),
    caller: request.auth,
    data: request.data,
    log: logger,
  }),
);

export const reviewRequest = onCall((request) =>
  reviewRequestHandler({
    db: getFirestore(),
    messaging: messaging(),
    caller: request.auth,
    data: request.data,
    log: logger,
  }),
);

// DEC-016: the app's "Delete account". The caller's own account only; the handler checks the
// sign-in is recent and refuses an admin.
export const deleteAccount = onCall((request) =>
  deleteAccountHandler({
    db: getFirestore(),
    auth: getAuth(),
    caller: request.auth,
    log: logger,
  }),
);
