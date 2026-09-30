// FCM messages — the port of RequestAlertNotifier and AcceptanceNotifier (ADR 0009).
//
// The text is the backend's, word for word, so a donor sees the same alert on either branch.
// The data half is what makes a notification actionable: the app routes on `type` and
// `requestId` (PushArrival), and a notification-only message gives it nothing to route on.

import { FieldValue } from 'firebase-admin/firestore';

const TEXT = {
    REQUEST_ALERT: {
        title: { en: 'Urgent blood request', km: 'សំណើឈាមបន្ទាន់' },
        body: {
            en: (type, hospital) => `${type} needed at ${hospital}`,
            km: (type, hospital) => `ត្រូវការឈាមប្រភេទ ${type} នៅ ${hospital}`,
        },
    },
    // DEC-015. Neither names the reason or a person: it can sit on a lock screen.
    REQUEST_APPROVED: {
        title: { en: 'Your request was approved', km: 'សំណើរបស់អ្នកត្រូវបានអនុម័ត' },
        body: {
            en: (type, hospital) => `${type} at ${hospital} — donors nearby are being alerted`,
            km: (type, hospital) =>
                `ឈាមប្រភេទ ${type} នៅ ${hospital} — កំពុងជូនដំណឹងដល់អ្នកបរិច្ចាគនៅក្បែរ`,
        },
    },
    // The same approval when matching found nobody. "Donors are being alerted" would be a lie
    // the family waits on; the truth, plus who is now on it, is what lets them call the
    // hospital or a blood center instead. Same `type` on the data half: the app opens the
    // request either way.
    REQUEST_APPROVED_NO_DONORS: {
        title: { en: 'Your request was approved', km: 'សំណើរបស់អ្នកត្រូវបានអនុម័ត' },
        body: {
            en: (type, hospital) =>
                `${type} at ${hospital} — no eligible donor is nearby right now. Our admin has been told; please also ask the hospital`,
            km: (type, hospital) =>
                `ឈាមប្រភេទ ${type} នៅ ${hospital} — មិនទាន់មានអ្នកបរិច្ចាគដែលអាចផ្តល់បាននៅក្បែរទេ។ អ្នកគ្រប់គ្រងបានដឹងហើយ សូមសួរមន្ទីរពេទ្យផងដែរ`,
        },
    },
    REQUEST_REJECTED: {
        title: { en: 'Your request was not approved', km: 'សំណើរបស់អ្នកមិនត្រូវបានអនុម័តទេ' },
        body: {
            en: (type, hospital) => `${type} at ${hospital} — open LifeLink to see why`,
            km: (type, hospital) =>
                `ឈាមប្រភេទ ${type} នៅ ${hospital} — បើក LifeLink ដើម្បីមើលមូលហេតុ`,
        },
    },
    DONOR_ACCEPTED: {
        title: { en: 'A donor accepted your request', km: 'មានអ្នកបរិច្ចាគទទួលយកសំណើរបស់អ្នក' },
        body: {
            en: (type, hospital) => `${type} at ${hospital} — open LifeLink to see your request`,
            km: (type, hospital) =>
                `ឈាមប្រភេទ ${type} នៅ ${hospital} — បើក LifeLink ដើម្បីមើលសំណើរបស់អ្នក`,
        },
    },
};

/** FCM's two answers for "this token will never work again". Anything else may be transient. */
export const DEAD_TOKEN_CODES = new Set([
    'messaging/registration-token-not-registered',
    'messaging/invalid-registration-token',
]);

/**
 * The Android channel every push lands on. The app creates it at launch with high importance
 * (MainActivity.kt) — the importance is what makes Android pop the alert over whatever is on
 * screen instead of filing it silently in the tray. The ids must match.
 */
export const ANDROID_CHANNEL_ID = 'lifelink_urgent_requests';

/**
 * The title and body a recipient reads, in their language. `language` anything but 'en' reads
 * Khmer, same as the backend. `alerted` matters to REQUEST_APPROVED only: zero picks the
 * wording that says so.
 */
function render(type, { language, patientBloodType, hospitalName, alerted }) {
    const lang = language === 'en' ? 'en' : 'km';
    const text =
        TEXT[type === 'REQUEST_APPROVED' && alerted === 0 ? 'REQUEST_APPROVED_NO_DONORS' : type];
    return {
        title: text.title[lang],
        body: text.body[lang](patientBloodType, hospitalName),
    };
}

/** One message per recipient. */
export function buildMessage(
    type,
    { token, language, requestId, patientBloodType, hospitalName, alerted },
) {
    return {
        token,
        notification: render(type, { language, patientBloodType, hospitalName, alerted }),
        data: { type, requestId },
        android: {
            priority: 'high',
            notification: { channelId: ANDROID_CHANNEL_ID, sound: 'default' },
        },
    };
}

/**
 * The inbox copy of a push: `users/{uid}/notifications/{id}`, what the app's bell lists. Written
 * whether or not the push is delivered — a phone with notifications turned off, or no token at
 * all, still finds it there. The text is the push's, in the language it was sent in.
 *
 * `id` makes a redelivered event overwrite rather than duplicate, so it names what happened
 * once: the request for everything but an acceptance, which happens once per donor.
 */
export function inboxEntry(
    type,
    { id, language, requestId, patientBloodType, hospitalName, alerted },
) {
    return {
        id,
        data: {
            type,
            requestId,
            ...render(type, { language, patientBloodType, hospitalName, alerted }),
            createdAt: FieldValue.serverTimestamp(),
            readAt: null,
        },
    };
}

/**
 * Files the entries in each recipient's inbox. Never throws: the push and the status change are
 * the facts, the inbox is a record of them, and losing it must not fail either.
 *
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {Array<{uid: string, entry: {id: string, data: object}}>} incoming
 */
export async function fileInInbox(db, incoming, log = console) {
    if (incoming.length === 0) return;
    try {
        for (let i = 0; i < incoming.length; i += 400) {
            const batch = db.batch();
            for (const { uid, entry } of incoming.slice(i, i + 400)) {
                batch.set(db.doc(`users/${uid}/notifications/${entry.id}`), entry.data);
            }
            await batch.commit();
        }
    } catch (error) {
        log.warn(`inbox write failed: ${error.code ?? 'unknown'}`);
    }
}

/**
 * Sends one message per recipient and sorts the outcome.
 *
 * @param {{sendEach: Function}} messaging firebase-admin Messaging, or a fake in tests
 * @param {Array<{uid: string, message: object}>} outgoing
 * @returns {Promise<{sent: string[], dead: string[]}>} uids delivered to, uids whose token is dead
 */
export async function sendAll(messaging, outgoing) {
    if (outgoing.length === 0) return { sent: [], dead: [] };
    const batch = await messaging.sendEach(outgoing.map((o) => o.message));
    const sent = [];
    const dead = [];
    batch.responses.forEach((response, i) => {
        if (response.success) sent.push(outgoing[i].uid);
        else if (DEAD_TOKEN_CODES.has(response.error?.code)) dead.push(outgoing[i].uid);
    });
    return { sent, dead };
}
