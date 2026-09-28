// Demo data for the emulator (ADR 0009, phase 6) — what scripts/seed-demo-request.sql and
// reset-demo-data.sql did for Postgres. Two O- donors in Doun Penh, one requester, and:
//
//   - one CRITICAL request at Calmette, approved (DEC-015) and matched by the real
//     handleRequestApproved — the portal's own code, called here (ADR 0010) — then accepted by
//     the first donor through the real respondToMatch — the portal has a donation to confirm;
//   - one URGENT request left PENDING — the portal's review queue has something to approve live.
//
// The emulator must be running (`npm run emulators:app`).
//
//   npm run seed:demo             # emulator, project lifelinkkh. Clears requests/matches/donations first.
//
// Emulator only, by design: it deletes data.
import { geohashForLocation } from 'geofire-common';
// The portal's firebase-admin, not this package's: see admin-sdk.js for why.
import { FieldValue, getFirestore, initializeApp } from '../../frontend/src/server/admin-sdk.js';
import { handleRequestApproved } from '../../frontend/src/server/request-lifecycle.js';
import { respondToMatch } from '../../frontend/src/server/respond-to-match.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
initializeApp({ projectId: 'lifelinkkh' });
const db = getFirestore();
const now = () => FieldValue.serverTimestamp();
// FCM has no emulator, and the demo donors have no token anyway: record instead of send.
const messaging = {
  async sendEach(messages) {
    await Promise.all(messages.map((m) => db.collection('_outbox').add(m)));
    return { responses: messages.map(() => ({ success: true })) };
  },
};
const quiet = { info() {}, warn() {} };
const CALMETTE = '8c251b94-1968-481a-9b77-112b87790b00';
const DOUN_PENH = { lat: 11.5725, lng: 104.9173 };

for (const collection of ['requests', 'matches', 'donations']) {
  await db.recursiveDelete(db.collection(collection));
}

for (const [uid, name] of [['demo-donor-a', 'Nem Sothea'], ['demo-donor-b', 'Sok Dara']]) {
  await db.doc(`users/${uid}`).set({ displayName: name, language: 'km', role: 'DONOR', fcmToken: null, createdAt: now(), updatedAt: now() });
  await db.doc(`donors/${uid}`).set({
    fullName: name, bloodType: 'O-', districtCode: '1202', lastDonationDate: null, isAvailable: true,
    ...DOUN_PENH, geohash: geohashForLocation([DOUN_PENH.lat, DOUN_PENH.lng]), createdAt: now(), updatedAt: now(),
  });
}
await db.doc('users/demo-family').set({ displayName: 'Chea Srey', language: 'km', role: 'REQUESTER', fcmToken: null, createdAt: now(), updatedAt: now() });

async function post(id, fields) {
  const ref = db.doc(`requests/${id}`);
  const batch = db.batch();
  batch.set(ref, {
    createdBy: 'demo-family', hospitalId: CALMETTE, unitsNeeded: 1, status: 'PENDING',
    alertedCount: 0, acceptedCount: 0, createdAt: now(), updatedAt: now(), ...fields,
  });
  batch.set(ref.collection('private').doc('contact'), { contactName: 'Chea Srey', contactPhone: '+85512345678' });
  await batch.commit();
  return ref;
}

const request = await post('demo-request', { patientBloodType: 'AB+', urgency: 'CRITICAL' });
// The admin's approval, as reviewRequest does it: the status flips, then the matching runs.
await request.update({ status: 'OPEN', reviewedBy: 'demo-seed', reviewedAt: now(), updatedAt: now() });
const matched = await handleRequestApproved({ db, messaging, requestId: 'demo-request', log: quiet });
if (matched.outcome !== 'matched' || matched.alerted === 0) {
  console.error(`matching found nobody (${JSON.stringify(matched)}) — is the seed data intact?`);
  process.exit(1);
}
// The first donor's answer, as the app sends it.
await respondToMatch({
  db, messaging, caller: { uid: 'demo-donor-a', token: {} },
  data: { matchId: 'demo-request_demo-donor-a', response: 'ACCEPTED' }, log: quiet,
});

await post('demo-pending', { patientBloodType: 'O+', urgency: 'URGENT' });

const r = (await request.get()).data();
console.log(`demo request: ${r.alertedCount} donors alerted, ${r.acceptedCount} accepted — ready to confirm in the portal`);
console.log('demo-pending: waiting in the portal\'s review queue');
process.exit(0);
