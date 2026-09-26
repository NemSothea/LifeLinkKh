// What POST /requests did after the insert: rate limit, match, write the matches, push the
// donors, stamp the counts (ADR 0009). The trigger in index.js calls this; tests call it
// directly with an emulator Firestore and a fake messaging.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { COMPATIBLE_DONORS, REQUEST_RATE_LIMIT, phnomPenhDate, selectCandidates } from './matching.js';
import { buildMessage, sendAll } from './push.js';

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {string} deps.requestId
 * @param {Date} [deps.now]
 * @param {{info: Function, warn: Function}} [deps.log]
 * @returns {Promise<{outcome: string, alerted?: number, pushed?: number}>}
 */
export async function handleRequestCreated({ db, messaging, requestId, now = new Date(), log = console }) {
  const requestRef = db.doc(`requests/${requestId}`);

  // Functions deliver at least once. `matchedAt` is claimed in a transaction before anything
  // else, so a redelivered event finds it set and stops: matches are written once and donors
  // are pushed at most once, never twice.
  const request = await db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    if (!snap.exists || snap.get('matchedAt')) return null;
    tx.update(requestRef, { matchedAt: FieldValue.serverTimestamp() });
    return snap.data();
  });
  if (!request) return { outcome: 'already-handled' };

  // RequestRateLimiter, after the fact: the rules cannot count, so an over-limit request is
  // written and then closed here, before it alerts anyone.
  const windowStart = Timestamp.fromMillis(now.getTime() - REQUEST_RATE_LIMIT.windowMs);
  const recent = await db.collection('requests')
    .where('createdBy', '==', request.createdBy)
    .where('createdAt', '>=', windowStart)
    .count()
    .get();
  if (recent.data().count > REQUEST_RATE_LIMIT.maxAttempts) {
    await requestRef.update({
      status: 'CANCELLED',
      cancelReason: 'RATE_LIMITED',
      updatedAt: FieldValue.serverTimestamp(),
    });
    log.warn(`request ${requestId} over the rate limit; closed without alerting`);
    return { outcome: 'rate-limited' };
  }

  const hospitalSnap = await db.doc(`hospitals/${request.hospitalId}`).get();
  const hospital = hospitalSnap.data();

  const donorSnaps = await db.collection('donors')
    .where('isAvailable', '==', true)
    .where('bloodType', 'in', COMPATIBLE_DONORS[request.patientBloodType] ?? ['none'])
    .get();
  const donors = donorSnaps.docs.map((d) => {
    const last = d.get('lastDonationDate');
    return {
      uid: d.id,
      bloodType: d.get('bloodType'),
      isAvailable: d.get('isAvailable'),
      lastDonationDate: last instanceof Timestamp ? phnomPenhDate(last.toDate()) : null,
      lat: d.get('lat') ?? null,
      lng: d.get('lng') ?? null,
    };
  });

  const candidates = selectCandidates({ request, hospital, donors, now });

  // Every candidate gets a match document; only the ones FCM accepted get notifiedAt —
  // the same split as request_matches.notified_at.
  const batch = db.batch();
  for (const c of candidates) {
    batch.set(db.doc(`matches/${requestId}_${c.uid}`), {
      requestId,
      donorUid: c.uid,
      requesterUid: request.createdBy,
      hospitalId: request.hospitalId,
      distanceKm: c.distanceKm,
      notifiedAt: null,
      response: null,
      respondedAt: null,
    });
  }
  batch.update(requestRef, {
    hospital: { name: hospital.name, districtCode: hospital.districtCode ?? null },
    alertedCount: candidates.length,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  // Push. A failure here never undoes the matches — the backend made the same call:
  // "not worth failing a request over — the matches are written either way".
  const users = candidates.length
    ? await db.getAll(...candidates.map((c) => db.doc(`users/${c.uid}`)))
    : [];
  const outgoing = users
    .filter((u) => u.exists && u.get('fcmToken'))
    .map((u) => ({
      uid: u.id,
      message: buildMessage('REQUEST_ALERT', {
        token: u.get('fcmToken'),
        language: u.get('language'),
        requestId,
        patientBloodType: request.patientBloodType,
        hospitalName: hospital.name,
      }),
    }));

  let sent = [];
  let dead = [];
  try {
    ({ sent, dead } = await sendAll(messaging, outgoing));
  } catch (error) {
    // The code only. The error text can carry a token, and a token is a credential.
    log.warn(`FCM send failed for request ${requestId}: ${error.code ?? 'unknown'}`);
  }

  const stamp = db.batch();
  for (const uid of sent) {
    stamp.update(db.doc(`matches/${requestId}_${uid}`), { notifiedAt: FieldValue.serverTimestamp() });
  }
  // DeadTokenCleaner: without this every future request pays a failed send per dead token.
  for (const uid of dead) {
    stamp.update(db.doc(`users/${uid}`), { fcmToken: null });
  }
  if (sent.length || dead.length) await stamp.commit();

  log.info(`request ${requestId}: ${candidates.length} matched, ${sent.length} pushed, ${dead.length} dead tokens`);
  return { outcome: 'matched', alerted: candidates.length, pushed: sent.length };
}
