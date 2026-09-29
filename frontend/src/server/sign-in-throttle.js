// Password sign-in throttling per client IP (SEC-REVIEW-003 F-08, ASVS 6.3.1). Firebase Auth
// already locks one account after repeated failures; that does nothing against one password
// tried across many usernames. This counts failures per IP in Firestore — not in memory,
// because each Vercel instance has its own — and refuses that IP for the rest of the window.
//
// The IP is hashed before it is stored: the count needs an identity, not an address. The
// collection has no rule, so no client reads or writes it; only the Admin SDK does.
import { createHash } from 'node:crypto';

export const SIGN_IN_LIMIT = Object.freeze({ maxFailures: 10, windowMs: 15 * 60 * 1000 });

const COLLECTION = 'signInThrottle';

/** @param {string} ip */
function ref(db, ip) {
    const key = createHash('sha256').update(`sign-in:${ip}`).digest('hex').slice(0, 32);
    return db.doc(`${COLLECTION}/${key}`);
}

/** @param {unknown} data */
function recent(data, now) {
    const failures = Array.isArray(data?.failures) ? data.failures : [];
    return failures.filter((t) => typeof t === 'number' && now - t < SIGN_IN_LIMIT.windowMs);
}

/**
 * True when this IP has used up its failures for the window.
 *
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} ip
 */
export async function signInBlocked(db, ip, now = Date.now()) {
    const snap = await ref(db, ip).get();
    return recent(snap.data(), now).length >= SIGN_IN_LIMIT.maxFailures;
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} ip
 */
export async function recordSignInFailure(db, ip, now = Date.now()) {
    const doc = ref(db, ip);
    await db.runTransaction(async (tx) => {
        const failures = [...recent((await tx.get(doc)).data(), now), now];
        // Never more than the limit is needed to decide; the array cannot grow without bound.
        tx.set(doc, { failures: failures.slice(-SIGN_IN_LIMIT.maxFailures), updatedAt: now });
    });
}

/**
 * A successful sign-in from this IP starts it afresh.
 *
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} ip
 */
export async function clearSignInFailures(db, ip) {
    await ref(db, ip).delete();
}
