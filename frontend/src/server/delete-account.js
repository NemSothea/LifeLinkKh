// DEC-016: delete a user's account. Personal data is deleted, anonymous counts are kept, and
// nobody is left waiting on a person who is gone. `deleteAccountData` is the whole job and is
// safe to run twice — the `deleteAccount` callable wraps it for the app, and
// scripts/delete-account.mjs wraps it for an operator answering a web request.
import { FieldValue } from 'firebase-admin/firestore';
import { boardId } from './board-id.js';
import { HttpsError } from './https-error.js';

/** How fresh the caller's sign-in must be. The app re-authenticates with Google just before. */
export const RECENT_SIGN_IN_SECONDS = 5 * 60;

const LIVE = ['PENDING', 'OPEN'];

/** Firestore batches cap at 500 writes; commit in chunks so a heavy user cannot exceed it. */
async function commitInChunks(db, ops) {
    for (let i = 0; i < ops.length; i += 400) {
        const batch = db.batch();
        for (const op of ops.slice(i, i + 400)) op(batch);
        await batch.commit();
    }
}

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {import('firebase-admin/auth').Auth} deps.auth
 * @param {string} deps.uid
 * @returns {Promise<{requestsClosed: number, acceptancesWithdrawn: number, recordsAnonymised: number}>}
 */
export async function deleteAccountData({ db, auth, uid, log = console }) {
    // 1. Their own requests: the phone number goes, a live request is closed, the rest is kept
    //    with no creator so the metrics still count it.
    const ownRequests = await db.collection('requests').where('createdBy', '==', uid).get();
    const requestOps = [];
    let requestsClosed = 0;
    for (const request of ownRequests.docs) {
        requestOps.push((b) => b.delete(request.ref.collection('private').doc('contact')));
        const live = LIVE.includes(request.get('status'));
        if (live) requestsClosed += 1;
        requestOps.push((b) =>
            b.update(request.ref, {
                createdBy: null,
                ...(live ? { status: 'CANCELLED', cancelReason: 'ACCOUNT_DELETED' } : {}),
                updatedAt: FieldValue.serverTimestamp(),
            }),
        );
    }
    await commitInChunks(db, requestOps);

    // 2. Their answers as a donor. An acceptance on a request still OPEN is withdrawn — the count
    //    goes down and their name leaves the board in the same transaction, so a retry cannot
    //    decrement twice. Every match loses the uid.
    const asDonor = await db.collection('matches').where('donorUid', '==', uid).get();
    let acceptancesWithdrawn = 0;
    for (const match of asDonor.docs) {
        const requestRef = db.doc(`requests/${match.get('requestId')}`);
        const board = requestRef.collection('acceptedDonors');
        // The row's id since SEC-REVIEW-003 F-11, and the uid it had before — a board written
        // earlier still has those, and the name must come off it all the same.
        const boardRefs = [board.doc(boardId(match.get('requestId'), uid)), board.doc(uid)];
        const withdrawn = await db.runTransaction(async (tx) => {
            const [fresh, request, ...rows] = await Promise.all([
                tx.get(match.ref),
                tx.get(requestRef),
                ...boardRefs.map((ref) => tx.get(ref)),
            ]);
            const withdraw =
                fresh.get('response') === 'ACCEPTED' && request.get('status') === 'OPEN';
            const onBoard = rows.filter((row) => row.exists);
            if (onBoard.length > 0) {
                for (const row of onBoard) tx.delete(row.ref);
                if (withdraw)
                    tx.update(requestRef, {
                        acceptedCount: FieldValue.increment(-1),
                        updatedAt: FieldValue.serverTimestamp(),
                    });
            }
            tx.update(match.ref, {
                donorUid: null,
                ...(withdraw ? { response: 'WITHDRAWN' } : {}),
            });
            return withdraw;
        });
        if (withdrawn) acceptancesWithdrawn += 1;
    }

    // 3. Everything else that names them: matches on their requests, donations they gave, and
    //    reports they filed (DEC-019). A report keeps its reason, so the count of "asked for
    //    money" stays true, but loses who filed it and the note in their own words.
    const [asRequester, donations, reports] = await Promise.all([
        db.collection('matches').where('requesterUid', '==', uid).get(),
        db.collection('donations').where('donorUid', '==', uid).get(),
        db.collection('reports').where('reporterUid', '==', uid).get(),
    ]);
    await commitInChunks(db, [
        ...asRequester.docs.map((d) => (b) => b.update(d.ref, { requesterUid: null })),
        ...donations.docs.map((d) => (b) => b.update(d.ref, { donorUid: null })),
        ...reports.docs.map((d) => (b) => b.update(d.ref, { reporterUid: null, note: null })),
        (b) => b.delete(db.doc(`donors/${uid}`)),
        (b) => b.delete(db.doc(`users/${uid}`)),
    ]);

    // 4. The sign-in itself, last: until here a failure leaves the person able to sign in and try
    //    again, and everything above is safe to repeat.
    await auth.deleteUser(uid).catch((error) => {
        if (error.code !== 'auth/user-not-found') throw error;
    });

    const recordsAnonymised =
        ownRequests.size + asDonor.size + asRequester.size + donations.size + reports.size;
    // The uid only: this line is the audit trail, and a name in it would defeat the deletion.
    log.info(
        `account deleted uid=${uid} requestsClosed=${requestsClosed} withdrawn=${acceptancesWithdrawn} anonymised=${recordsAnonymised}`,
    );
    return { requestsClosed, acceptancesWithdrawn, recordsAnonymised };
}

/**
 * The app's "Delete account". Only the caller's own account, only with a recent sign-in, and never
 * an admin (DEC-014: admins are removed by an operator).
 */
export async function deleteAccount({ db, auth, caller, now = new Date(), log = console }) {
    if (!caller?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    if (caller.token?.role === 'ADMIN' || (await db.doc(`admins/${caller.uid}`).get()).exists) {
        throw new HttpsError('failed-precondition', 'An admin account is removed by an operator.', {
            code: 'ADMIN_ACCOUNT',
        });
    }
    const authTime = Number(caller.token?.auth_time ?? 0);
    if (now.getTime() / 1000 - authTime > RECENT_SIGN_IN_SECONDS) {
        throw new HttpsError('failed-precondition', 'Sign in again to delete your account.', {
            code: 'RECENT_SIGN_IN_REQUIRED',
        });
    }
    return deleteAccountData({ db, auth, uid: caller.uid, log });
}
