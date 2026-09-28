// POST /requests, as a portal function (ADR 0010). The app used to write `requests/{id}` and its
// `private/contact` itself, with the rules checking the shape and the onRequestCreated trigger
// doing the rest after the fact. With no triggers, the write moved here: the same shape check the
// rules made, the rate limit, and the hospital's name stamped on for the admin's queue — in one
// batch, before anything is visible. The rules now refuse the client write outright.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from './https-error.js';
import { COMPATIBLE_DONORS, REQUEST_RATE_LIMIT } from './matching.js';

const BLOOD_TYPES = Object.keys(COMPATIBLE_DONORS);
const URGENCIES = ['CRITICAL', 'URGENT', 'ROUTINE'];
/**
 * Already normalised to +855 by the app — the same prefixes CambodianPhone and, until ADR 0010,
 * the rules' isCambodianMobile() accepted.
 */
const PHONE =
    /^\+855((10|11|12|14|15|16|17|60|61|66|67|68|69|70|77|78|81|85|86|87|89|90|92|93|95|98|99)[0-9]{6}|(18|31|71|76|88|96|97)[0-9]{7})$/;

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{uid: string, token: object}|null|undefined} deps.caller
 * @param {{hospitalId: string, patientBloodType: string, unitsNeeded: number, urgency: string,
 *   contactName: string, contactPhone: string}} deps.data
 * @returns {Promise<{requestId: string, status: 'PENDING'}>}
 */
export async function createRequest({ db, caller, data, now = new Date(), log = console }) {
    if (!caller?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    const { hospitalId, patientBloodType, unitsNeeded, urgency, contactName, contactPhone } =
        data ?? {};

    // validNewRequest() in firestore.rules, line for line.
    if (typeof hospitalId !== 'string' || hospitalId === '') invalid('hospitalId is required.');
    if (!BLOOD_TYPES.includes(patientBloodType)) invalid('patientBloodType is a blood type.');
    if (!Number.isInteger(unitsNeeded) || unitsNeeded < 1 || unitsNeeded > 20)
        invalid('unitsNeeded is 1–20.');
    if (!URGENCIES.includes(urgency)) invalid('urgency is CRITICAL, URGENT or ROUTINE.');
    const name = typeof contactName === 'string' ? contactName.trim() : '';
    if (name === '' || name.length > 80) invalid('contactName is 1–80 characters.');
    if (typeof contactPhone !== 'string' || !PHONE.test(contactPhone))
        invalid('contactPhone is a +855 number.');

    const hospital = (await db.doc(`hospitals/${hospitalId}`).get()).data();
    if (!hospital)
        throw new HttpsError('not-found', 'No such hospital.', { code: 'HOSPITAL_NOT_FOUND' });

    // RequestRateLimiter: at most 5 requests per creator in any 10 minutes. Counted before the
    // write now, so an over-limit request is refused rather than written and closed.
    const windowStart = Timestamp.fromMillis(now.getTime() - REQUEST_RATE_LIMIT.windowMs);
    const recent = await db
        .collection('requests')
        .where('createdBy', '==', caller.uid)
        .where('createdAt', '>=', windowStart)
        .count()
        .get();
    if (recent.data().count >= REQUEST_RATE_LIMIT.maxAttempts) {
        log.warn(`request refused for ${caller.uid}: over the rate limit`);
        throw new HttpsError(
            'resource-exhausted',
            'Too many requests in a short time. Try again later.',
            { code: 'RATE_LIMITED' },
        );
    }

    const ref = db.collection('requests').doc();
    const batch = db.batch();
    batch.set(ref, {
        createdBy: caller.uid,
        hospitalId,
        // The admin reviews by hospital name, and the portal and the app read it off the request.
        hospital: { name: hospital.name ?? '', districtCode: hospital.districtCode ?? null },
        patientBloodType,
        unitsNeeded,
        urgency,
        // DEC-015: every request waits for an admin before it alerts anyone.
        status: 'PENDING',
        alertedCount: 0,
        acceptedCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
    });
    // Its own document: a rule cannot hide one field of a public one (ADR 0009).
    batch.set(ref.collection('private').doc('contact'), { contactName: name, contactPhone });
    await batch.commit();

    log.info(`request ${ref.id} waiting for review`);
    return { requestId: ref.id, status: 'PENDING' };
}

function invalid(message) {
    throw new HttpsError('invalid-argument', message, { code: 'INVALID_REQUEST' });
}
