// POST /portal/requests/{id}/confirm-donation, as a callable Function (ADR 0009, phase 5). One
// transaction, three writes, as PortalService did: the donation, the donor's lastDonationDate,
// and FULFILLED when this was the last unit the request needed. The rules refuse all three to
// every client, so this is the only way any of them happens. v1 has no hospital staff: an admin
// confirms at any hospital.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from './https-error.js';
import { isAdmin } from './portal-accounts.js';
import { cooldownDaysFor } from './matching.js';


/** Today's date in Phnom Penh, as YYYY-MM-DD — the portal's date picker speaks this calendar. */
export function phnomPenhToday(now = new Date()) {
    return new Date(now.getTime() + 7 * 3600_000).toISOString().slice(0, 10);
}

/**
 * Midnight in Phnom Penh. The app writes a date as the device's local midnight and reads one
 * back with `toDate()`, so a Cambodian phone shows the day that was picked.
 */
export function dateToTimestamp(date) {
    return Timestamp.fromDate(new Date(`${date}T00:00:00+07:00`));
}

function addDays(date, days) {
    const d = new Date(`${date}T00:00:00Z`);
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
}

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{uid: string, token: object}|undefined} deps.caller the verified ID token's claims
 * @param {{requestId: string, matchId: string, donatedOn: string}} deps.data
 */
export async function confirmDonation({ db, caller, data, now = new Date(), log = console }) {
    if (!(await isAdmin(db, caller))) {
        throw new HttpsError('permission-denied', 'Admins only.');
    }
    const { requestId, matchId, donatedOn } = data ?? {};
    if (
        typeof requestId !== 'string' ||
        typeof matchId !== 'string' ||
        requestId === '' ||
        matchId === ''
    ) {
        throw new HttpsError('invalid-argument', 'requestId and matchId are required.');
    }
    if (
        typeof donatedOn !== 'string' ||
        !/^\d{4}-\d{2}-\d{2}$/.test(donatedOn) ||
        Number.isNaN(Date.parse(`${donatedOn}T00:00:00Z`))
    ) {
        throw new HttpsError('invalid-argument', 'donatedOn is a YYYY-MM-DD date.');
    }
    if (donatedOn > phnomPenhToday(now)) {
        throw new HttpsError('invalid-argument', 'The donation date cannot be in the future.', {
            code: 'DONATION_DATE_IN_FUTURE',
        });
    }

    const requestRef = db.doc(`requests/${requestId}`);
    const matchRef = db.doc(`matches/${matchId}`);

    const result = await db.runTransaction(async (tx) => {
        const [request, match] = await Promise.all([tx.get(requestRef), tx.get(matchRef)]);
        if (!request.exists) {
            throw new HttpsError('not-found', 'No such request.', { code: 'REQUEST_NOT_FOUND' });
        }
        // Only an OPEN request takes a donation. A CANCELLED or REJECTED one has no need to fill,
        // and confirming against it would still start the donor's cooldown and count a
        // donation in the metrics that no hospital asked for. FULFILLED is refused too: every
        // unit it needed is already on record.
        if (request.get('status') !== 'OPEN') {
            throw new HttpsError('failed-precondition', 'The request is not open.', {
                code: 'REQUEST_NOT_OPEN',
                status: request.get('status'),
            });
        }
        if (
            !match.exists ||
            match.get('requestId') !== requestId ||
            match.get('response') !== 'ACCEPTED'
        ) {
            throw new HttpsError(
                'failed-precondition',
                'No accepted match with that id on this request.',
                { code: 'MATCH_NOT_ACCEPTED' },
            );
        }

        const donorUid = match.get('donorUid');
        // One donation per donor per request, by id — what V9__donations_unique.sql guaranteed. A
        // retry of the same confirmation finds it and stops, inside the transaction, so two clicks
        // racing cannot both write.
        const donationRef = db.doc(`donations/${requestId}_${donorUid}`);
        const donorRef = db.doc(`donors/${donorUid}`);
        const [existing, donor, confirmed] = await Promise.all([
            tx.get(donationRef),
            tx.get(donorRef),
            tx.get(db.collection('donations').where('requestId', '==', requestId)),
        ]);
        if (existing.exists) {
            throw new HttpsError(
                'already-exists',
                "This donor's donation against this request is already confirmed.",
                { code: 'DONATION_ALREADY_CONFIRMED' },
            );
        }
        if (!donor.exists) {
            throw new HttpsError('not-found', 'No donor profile for that match.', {
                code: 'DONOR_PROFILE_NOT_FOUND',
            });
        }

        const donatedAt = dateToTimestamp(donatedOn);
        tx.set(donationRef, {
            donorUid,
            hospitalId: request.get('hospitalId'),
            requestId,
            donatedOn: donatedAt,
            confirmedBy: caller.uid,
            createdAt: FieldValue.serverTimestamp(),
        });
        // Only when this is the newest donation on record: a backdated one must not move a
        // donor's cooldown backwards past a donation already known to be more recent.
        const last = donor.get('lastDonationDate');
        if (!last || last.toMillis() < donatedAt.toMillis()) {
            tx.update(donorRef, {
                lastDonationDate: donatedAt,
                updatedAt: FieldValue.serverTimestamp(),
            });
        }
        let status = request.get('status');
        if (confirmed.size + 1 >= request.get('unitsNeeded')) {
            status = 'FULFILLED';
            tx.update(requestRef, { status, updatedAt: FieldValue.serverTimestamp() });
        }
        return {
            id: donationRef.id,
            donorDisplayName: donor.get('fullName') ?? '',
            donorSex: donor.get('sex') ?? null,
            requestStatus: status,
        };
    });

    log.info(
        `donation confirmed ${result.id} by=${caller.uid} request=${requestId} status=${result.requestStatus}`,
    );
    // ConfirmDonationResponse's shape.
    const { donorSex, ...response } = result;
    return {
        ...response,
        donatedOn,
        // The donor's own interval (DEC-019): 90 days for men, 120 otherwise.
        donorNextEligibleOn: addDays(donatedOn, cooldownDaysFor(donorSex)),
    };
}
