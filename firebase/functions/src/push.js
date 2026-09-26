// FCM messages — the port of RequestAlertNotifier and AcceptanceNotifier (ADR 0009).
//
// The text is the backend's, word for word, so a donor sees the same alert on either branch.
// The data half is what makes a notification actionable: the app routes on `type` and
// `requestId` (PushArrival), and a notification-only message gives it nothing to route on.

const TEXT = {
  REQUEST_ALERT: {
    title: { en: 'Urgent blood request', km: 'សំណើឈាមបន្ទាន់' },
    body: {
      en: (type, hospital) => `${type} needed at ${hospital}`,
      km: (type, hospital) => `ត្រូវការឈាមប្រភេទ ${type} នៅ ${hospital}`,
    },
  },
  DONOR_ACCEPTED: {
    title: { en: 'A donor accepted your request', km: 'មានអ្នកបរិច្ចាគទទួលយកសំណើរបស់អ្នក' },
    body: {
      en: (type, hospital) => `${type} at ${hospital} — open LifeLink to see your request`,
      km: (type, hospital) => `ឈាមប្រភេទ ${type} នៅ ${hospital} — បើក LifeLink ដើម្បីមើលសំណើរបស់អ្នក`,
    },
  },
};

/** FCM's two answers for "this token will never work again". Anything else may be transient. */
export const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** One message per recipient; `language` anything but 'en' reads Khmer, same as the backend. */
export function buildMessage(type, { token, language, requestId, patientBloodType, hospitalName }) {
  const lang = language === 'en' ? 'en' : 'km';
  const text = TEXT[type];
  return {
    token,
    notification: {
      title: text.title[lang],
      body: text.body[lang](patientBloodType, hospitalName),
    },
    data: { type, requestId },
    android: { priority: 'high' },
  };
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
