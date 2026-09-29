// The portal's functions (ADR 0010): what the six Cloud Functions were, as handlers the Next
// server runs. `invoke.ts` verifies the caller and hands each one `db`, `auth`, `messaging`, the
// verified `caller` and the request `data`. Names are the wire names — `POST /api/functions/{name}`
// for the app, `callFunction(name)` for the portal's own Server Actions.
//
// Gone with the triggers: onRequestCreated (its work is inside createRequest, up front),
// onMatchAnswered (inside respondToMatch, after the write), onRequestApproved (inside
// reviewRequest, after the status flips).
import { confirmDonation } from './confirm-donation.js';
import { createRequest } from './create-request.js';
import { deleteAccount } from './delete-account.js';
import { respondToMatch } from './respond-to-match.js';
import { reviewRequest } from './review-request.js';
import { setAppConfig } from './app-config.js';

/**
 * @typedef {object} Context
 * @property {import('firebase-admin/firestore').Firestore} db
 * @property {import('firebase-admin/auth').Auth} auth
 * @property {{sendEach: Function}} messaging
 * @property {{uid: string, token: object}|null} caller the verified ID token, or null
 * @property {unknown} data the request body's `data`
 * @property {{info: Function, warn: Function}} log
 */

/** @type {Record<string, (ctx: Context) => Promise<unknown>>} */
export const FUNCTIONS = Object.freeze({
    // The app.
    createRequest,
    respondToMatch,
    deleteAccount,
    // The portal admin.
    reviewRequest,
    confirmDonation,
    setAppConfig,
});

export const FUNCTION_NAMES = Object.freeze(Object.keys(FUNCTIONS));
