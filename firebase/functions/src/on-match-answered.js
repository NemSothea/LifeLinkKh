// What POST /matches/{id}/respond did after the write, for an acceptance: count it, put the
// donor on the public board, and push the family (FR-NOTIFY-003) — ADR 0009. The rules have
// already enforced who may answer and that an answer is given once; this only reacts.
import { FieldValue } from 'firebase-admin/firestore';
import { buildMessage, sendAll } from './push.js';

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {string} deps.matchId
 * @param {object|undefined} deps.before the match before the write
 * @param {object|undefined} deps.after the match after the write
 * @param {{info: Function, warn: Function}} [deps.log]
 */
export async function handleMatchAnswered({ db, messaging, matchId, before, after, log = console }) {
  // Only the one transition that means something: unanswered → ACCEPTED. A decline changes
  // no count and pushes nobody; any other update is the Function's own notifiedAt stamp.
  if (!after || before?.response != null || after.response !== 'ACCEPTED') {
    return { outcome: 'ignored' };
  }

  const requestRef = db.doc(`requests/${after.requestId}`);
  const boardRef = requestRef.collection('acceptedDonors').doc(after.donorUid);

  // At most once, keyed on the board document: a redelivered event finds it and stops, so
  // acceptedCount is never counted twice and the family is never pushed twice.
  const request = await db.runTransaction(async (tx) => {
    const [board, requestSnap, donorSnap] = await Promise.all([
      tx.get(boardRef),
      tx.get(requestRef),
      tx.get(db.doc(`donors/${after.donorUid}`)),
    ]);
    if (board.exists || !requestSnap.exists) return null;
    const donor = donorSnap.data() ?? {};
    // PublicDonorResponse's fields exactly: no match id, no uid in the body.
    tx.set(boardRef, {
      displayName: donor.fullName ?? '',
      bloodType: donor.bloodType ?? null,
      districtCode: donor.districtCode ?? null,
      respondedAt: after.respondedAt ?? FieldValue.serverTimestamp(),
    });
    tx.update(requestRef, {
      acceptedCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return requestSnap.data();
  });
  if (!request) return { outcome: 'already-handled' };

  // AcceptanceNotifier: the creator, if they have a token. A portal-created request or a
  // requester who declined push has none, and that is not an error.
  const requester = await db.doc(`users/${request.createdBy}`).get();
  const token = requester.get('fcmToken');
  if (!token) {
    log.info(`requester of ${after.requestId} has no FCM token; acceptance not pushed`);
    return { outcome: 'accepted', pushed: 0 };
  }

  const hospitalName = request.hospital?.name
    ?? (await db.doc(`hospitals/${request.hospitalId}`).get()).get('name')
    ?? '';
  try {
    const { sent, dead } = await sendAll(messaging, [{
      uid: request.createdBy,
      message: buildMessage('DONOR_ACCEPTED', {
        token,
        language: requester.get('language'),
        requestId: after.requestId,
        patientBloodType: request.patientBloodType,
        hospitalName,
      }),
    }]);
    if (dead.length) await requester.ref.update({ fcmToken: null });
    log.info(`match ${matchId} accepted; requester pushed: ${sent.length === 1}`);
    return { outcome: 'accepted', pushed: sent.length };
  } catch (error) {
    // The code only. The error text can carry a token, and a token is a credential.
    log.warn(`FCM send failed for match ${matchId}: ${error.code ?? 'unknown'}`);
    return { outcome: 'accepted', pushed: 0 };
  }
}
