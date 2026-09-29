// The id of a donor's row on a request's public board, `requests/{id}/acceptedDonors/{boardId}`
// (SEC-REVIEW-003 F-11). The board is readable signed out; keyed by the donor's uid, it let
// anyone follow one donor from request to request. The id is still deterministic — the server
// finds the row again to take it down when the donor deletes their account — but it is per
// request, so two rows of the same donor share nothing a reader can see.
import { createHash } from 'node:crypto';

/**
 * @param {string} requestId
 * @param {string} donorUid
 * @returns {string}
 */
export function boardId(requestId, donorUid) {
    return createHash('sha256').update(`${requestId}:${donorUid}`).digest('hex').slice(0, 24);
}
