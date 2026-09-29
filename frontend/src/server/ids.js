// Document ids that arrive in a request body (SEC-REVIEW-003 F-10). `db.doc(\`matches/${id}\`)`
// with an id holding a `/` reads a different path — `x/private/contact` under hospitals — or
// throws, which surfaced as a generic 500. Firestore's own auto-ids, Firebase uids, the
// `{requestId}_{uid}` match ids and the seeded hospital slugs all fit this.
import { HttpsError } from './https-error.js';

const DOC_ID = /^[A-Za-z0-9_-]{1,128}$/;

/** @param {unknown} value */
export function isDocId(value) {
    return typeof value === 'string' && DOC_ID.test(value);
}

/**
 * The id, or an `invalid-argument` naming the field.
 *
 * @param {unknown} value
 * @param {string} field
 * @returns {string}
 */
export function docId(value, field) {
    if (!isDocId(value)) {
        throw new HttpsError('invalid-argument', `${field} is required.`);
    }
    return value;
}
