// POST /matches/{id}/respond (ADR 0009, on the Next server since ADR 0010). The app used to write
// the answer to `matches/{id}` itself, with the rules enforcing who may answer and that an answer
// is given once, and the onMatchAnswered trigger reacting. With no triggers the write moved here:
// `respondToMatch` checks what the rules checked, writes the answer, and then `handleMatchAnswered`
// does what the trigger did — count an acceptance, put the donor on the public board, push the
// family (FR-NOTIFY-003).
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from './https-error.js';
import { buildMessage, fileInInbox, inboxEntry, sendAll } from './push.js';
import { boardId } from './board-id.js';
import { docId } from './ids.js';

/**
 * The donor's answer. What the rules said, as refusals the app can name:
 *   ALREADY_RESPONDED — one answer, never overwritten (FR-REQUEST-004 deferred). A replay of the
 *                       same answer is not a refusal: it is the offline queue landing twice.
 *   REQUEST_NOT_OPEN  — the request closed (fulfilled, cancelled) before the answer arrived.
 *
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {{uid: string, token: object}|null|undefined} deps.caller
 * @param {{matchId: string, response: 'ACCEPTED'|'DECLINED'}} deps.data
 * @returns {Promise<{matchId: string, response: string, respondedAt: string, replay: boolean}>}
 */
export async function respondToMatch({ db, messaging, caller, data, log = console }) {
    if (!caller?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    const { matchId, response } = data ?? {};
    docId(matchId, 'matchId');
    if (response !== 'ACCEPTED' && response !== 'DECLINED') {
        throw new HttpsError('invalid-argument', 'response is ACCEPTED or DECLINED.');
    }

    const matchRef = db.doc(`matches/${matchId}`);
    const { before, after, replay } = await db.runTransaction(async (tx) => {
        const snap = await tx.get(matchRef);
        // Not found and not mine read the same from outside, as the rules made them.
        if (!snap.exists || snap.get('donorUid') !== caller.uid) {
            throw new HttpsError('not-found', 'No such match.', { code: 'MATCH_NOT_FOUND' });
        }
        const stored = snap.data();
        if (stored.response != null) {
            if (stored.response === response)
                return { before: stored, after: stored, replay: true };
            throw new HttpsError('failed-precondition', 'This match was already answered.', {
                code: 'ALREADY_RESPONDED',
            });
        }
        const request = await tx.get(db.doc(`requests/${stored.requestId}`));
        if (request.get('status') !== 'OPEN') {
            throw new HttpsError('failed-precondition', 'The request is no longer open.', {
                code: 'REQUEST_NOT_OPEN',
            });
        }
        const respondedAt = FieldValue.serverTimestamp();
        tx.update(matchRef, { response, respondedAt });
        return { before: stored, after: { ...stored, response }, replay: false };
    });

    // What the trigger did, at most once (it is keyed on the board row); a replay reaches it too
    // and finds the row, which is how a retry after a crash between the two steps recovers.
    const reacted = await handleMatchAnswered({
        db,
        messaging,
        matchId,
        before: replay ? { ...before, response: null } : before,
        after,
        log,
    });
    const respondedAt = (await matchRef.get()).get('respondedAt');
    return {
        matchId,
        response,
        respondedAt: respondedAt?.toDate?.().toISOString() ?? new Date().toISOString(),
        replay,
        pushed: reacted.pushed ?? 0,
    };
}

/**
 * The name the public board shows: the first word and the initials of the rest — "Nem Sothea"
 * becomes "Nem S.". The board is readable by anyone signed out, and a full name next to a blood
 * type and a district identifies a person; the family and the admin do not need it from here (the
 * admin reads the full name from donors/{uid}, which only the admin can). Works on Khmer script
 * too: words are split on whitespace, and an initial is the first character of a word.
 */
export function publicName(fullName) {
    const words = String(fullName ?? '')
        .trim()
        .split(/\s+/)
        .filter(Boolean);
    if (words.length === 0) return '';
    return [words[0], ...words.slice(1).map((w) => `${Array.from(w)[0]}.`)].join(' ');
}

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{sendEach: Function}} deps.messaging
 * @param {string} deps.matchId
 * @param {object|undefined} deps.before the match before the write
 * @param {object|undefined} deps.after the match after the write
 * @param {{info: Function, warn: Function}} [deps.log]
 */
export async function handleMatchAnswered({
    db,
    messaging,
    matchId,
    before,
    after,
    log = console,
}) {
    // Only the one transition that means something: unanswered → ACCEPTED. A decline changes
    // no count and pushes nobody; any other update is the Function's own notifiedAt stamp.
    if (!after || before?.response != null || after.response !== 'ACCEPTED') {
        return { outcome: 'ignored' };
    }

    const requestRef = db.doc(`requests/${after.requestId}`);
    const boardRef = requestRef
        .collection('acceptedDonors')
        .doc(boardId(after.requestId, after.donorUid));

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
        // PublicDonorResponse's fields: no match id, no uid in the body, and a shortened name.
        tx.set(boardRef, {
            displayName: publicName(donor.fullName),
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

    // AcceptanceNotifier: the creator. A portal-created request, or a creator who deleted
    // their account, has nobody to tell.
    const requester = request.createdBy ? await db.doc(`users/${request.createdBy}`).get() : null;
    if (!requester?.exists) return { outcome: 'accepted', pushed: 0 };

    const about = {
        language: requester.get('language'),
        requestId: after.requestId,
        patientBloodType: request.patientBloodType,
        hospitalName:
            request.hospital?.name ??
            (await db.doc(`hospitals/${request.hospitalId}`).get()).get('name') ??
            '',
    };
    // One entry per acceptance, keyed on the board row's id — the same opaque id the public
    // board already shows, so the requester's inbox names no donor either.
    await fileInInbox(
        db,
        [
            {
                uid: request.createdBy,
                entry: inboxEntry('DONOR_ACCEPTED', {
                    ...about,
                    id: `DONOR_ACCEPTED_${boardRef.id}`,
                }),
            },
        ],
        log,
    );

    // A requester who declined push has no token, and that is not an error.
    const token = requester.get('fcmToken');
    if (!token) {
        log.info(`requester of ${after.requestId} has no FCM token; acceptance not pushed`);
        return { outcome: 'accepted', pushed: 0 };
    }
    try {
        const { sent, dead } = await sendAll(messaging, [
            {
                uid: request.createdBy,
                message: buildMessage('DONOR_ACCEPTED', { ...about, token }),
            },
        ]);
        if (dead.length) await requester.ref.update({ fcmToken: null });
        log.info(`match ${matchId} accepted; requester pushed: ${sent.length === 1}`);
        return { outcome: 'accepted', pushed: sent.length };
    } catch (error) {
        // The code only. The error text can carry a token, and a token is a credential.
        log.warn(`FCM send failed for match ${matchId}: ${error.code ?? 'unknown'}`);
        return { outcome: 'accepted', pushed: 0 };
    }
}
