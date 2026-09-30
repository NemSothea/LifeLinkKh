// What POST /requests did after the insert, split in two by DEC-015 (ADR 0009), and run on the
// Next server since ADR 0010:
//
//   handleRequestCreated  — kept for the seed and the operator scripts: the rate limit and the
//                           hospital's name for a request written straight to Firestore.
//                           The app goes through createRequest, which does both up front.
//   handleRequestApproved — the admin approved it (reviewRequest, PENDING → OPEN): match, write
//                           the matches, push the donors, stamp the counts, tell the requester.
//
// reviewRequest calls the second inside the approval; tests call both directly with an emulator
// Firestore and a fake messaging.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import {
    COMPATIBLE_DONORS,
    REQUEST_RATE_LIMIT,
    phnomPenhDate,
    selectCandidates,
} from './matching.js';
import { buildMessage, fileInInbox, inboxEntry, sendAll } from './push.js';

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {string} deps.requestId
 * @param {Date} [deps.now]
 * @param {{info: Function, warn: Function}} [deps.log]
 * @returns {Promise<{outcome: string, alerted?: number, pushed?: number}>}
 */
/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {string} deps.requestId
 * @param {Date} [deps.now]
 * @param {{info: Function, warn: Function}} [deps.log]
 * @returns {Promise<{outcome: string}>}
 */
export async function handleRequestCreated({ db, requestId, now = new Date(), log = console }) {
    const requestRef = db.doc(`requests/${requestId}`);
    const snap = await requestRef.get();
    // Only a PENDING request is this handler's. Anything else was already acted on.
    if (!snap.exists || snap.get('status') !== 'PENDING') return { outcome: 'ignored' };
    const request = snap.data();

    // RequestRateLimiter, after the fact: the rules cannot count, so an over-limit request is
    // written and then closed here, before it reaches the admin's queue. A redelivered event
    // counts the same requests again and reaches the same answer.
    const windowStart = Timestamp.fromMillis(now.getTime() - REQUEST_RATE_LIMIT.windowMs);
    const recent = await db
        .collection('requests')
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
        log.warn(`request ${requestId} over the rate limit; closed before review`);
        return { outcome: 'rate-limited' };
    }

    // The admin reviews by hospital name, and the portal reads it off the request.
    const hospital = (await db.doc(`hospitals/${request.hospitalId}`).get()).data() ?? {};
    await requestRef.update({
        hospital: { name: hospital.name ?? '', districtCode: hospital.districtCode ?? null },
    });
    log.info(`request ${requestId} waiting for review`);
    return { outcome: 'pending-review' };
}

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {string} deps.requestId
 * @param {Date} [deps.now]
 * @param {{info: Function, warn: Function}} [deps.log]
 * @returns {Promise<{outcome: string, alerted?: number, pushed?: number}>}
 */
export async function handleRequestApproved({
    db,
    messaging,
    requestId,
    now = new Date(),
    log = console,
}) {
    const requestRef = db.doc(`requests/${requestId}`);

    // Functions deliver at least once. `matchedAt` is claimed in a transaction before anything
    // else, so a redelivered event finds it set and stops: matches are written once and donors
    // are pushed at most once, never twice.
    const request = await db.runTransaction(async (tx) => {
        const snap = await tx.get(requestRef);
        if (!snap.exists || snap.get('status') !== 'OPEN' || snap.get('matchedAt')) return null;
        tx.update(requestRef, { matchedAt: FieldValue.serverTimestamp() });
        return snap.data();
    });
    if (!request) return { outcome: 'already-handled' };

    const hospitalSnap = await db.doc(`hospitals/${request.hospitalId}`).get();
    const hospital = hospitalSnap.data();

    const donorSnaps = await db
        .collection('donors')
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
            sex: d.get('sex') ?? null,
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

    // Every matched donor gets the inbox copy, token or not: a donor who turned
    // notifications off still finds the alert under the bell.
    await fileInInbox(
        db,
        users
            .filter((u) => u.exists)
            .map((u) => ({
                uid: u.id,
                entry: inboxEntry('REQUEST_ALERT', {
                    id: `REQUEST_ALERT_${requestId}`,
                    language: u.get('language'),
                    requestId,
                    patientBloodType: request.patientBloodType,
                    hospitalName: hospital.name,
                }),
            })),
        log,
    );

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
        stamp.update(db.doc(`matches/${requestId}_${uid}`), {
            notifiedAt: FieldValue.serverTimestamp(),
        });
    }
    // DeadTokenCleaner: without this every future request pays a failed send per dead token.
    for (const uid of dead) {
        stamp.update(db.doc(`users/${uid}`), { fcmToken: null });
    }
    if (sent.length || dead.length) await stamp.commit();

    // DEC-015: the requester has been waiting for review; tell them it is live — and, when
    // nobody matched, that nobody did. The request stays OPEN with alertedCount 0, which is
    // what the portal's bell flags for the admin.
    await notifyRequester({
        db,
        messaging,
        requestId,
        request,
        hospitalName: hospital.name,
        type: 'REQUEST_APPROVED',
        alerted: candidates.length,
        log,
    });

    if (candidates.length === 0)
        log.warn(`request ${requestId}: no eligible donor matched — needs the admin`);
    log.info(
        `request ${requestId}: ${candidates.length} matched, ${sent.length} pushed, ${dead.length} dead tokens`,
    );
    return { outcome: 'matched', alerted: candidates.length, pushed: sent.length };
}

/**
 * One push to the request's creator — approved or rejected (DEC-015). Never fails the caller:
 * the status change is the fact, the push is a courtesy.
 */
export async function notifyRequester({
    db,
    messaging,
    requestId,
    request,
    hospitalName,
    type,
    alerted,
    log = console,
}) {
    // A portal-created request, or one whose creator deleted their account, has nobody to tell.
    if (!request.createdBy) return 0;
    const requester = await db.doc(`users/${request.createdBy}`).get();
    if (!requester.exists) return 0;
    const about = {
        language: requester.get('language'),
        requestId,
        patientBloodType: request.patientBloodType,
        hospitalName: hospitalName ?? request.hospital?.name ?? '',
        alerted,
    };
    // Approved and rejected are each decided once per request, so the type and request name it.
    await fileInInbox(
        db,
        [
            {
                uid: request.createdBy,
                entry: inboxEntry(type, { ...about, id: `${type}_${requestId}` }),
            },
        ],
        log,
    );
    const token = requester.get('fcmToken');
    if (!token) return 0;
    try {
        const { sent, dead } = await sendAll(messaging, [
            { uid: request.createdBy, message: buildMessage(type, { ...about, token }) },
        ]);
        if (dead.length) await requester.ref.update({ fcmToken: null });
        return sent.length;
    } catch (error) {
        log.warn(`FCM send failed for requester of ${requestId}: ${error.code ?? 'unknown'}`);
        return 0;
    }
}
