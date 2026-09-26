// Cloud Functions for LifeLink KH (ADR 0009). Each trigger is a thin wrapper: the logic lives
// in its own module so tests can call it without deploying anything.
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';
import { handleRequestCreated } from './on-request-created.js';

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

export const onRequestCreated = onDocumentCreated('requests/{requestId}', (event) =>
  handleRequestCreated({
    db: getFirestore(),
    messaging: messaging(),
    requestId: event.params.requestId,
    log: logger,
  }),
);
