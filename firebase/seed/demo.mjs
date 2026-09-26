// Demo data for the emulator (ADR 0009, phase 6) — what scripts/seed-demo-request.sql and
// reset-demo-data.sql did for Postgres. Two O- donors in Doun Penh, one requester, and:
//
//   - one CRITICAL request at Calmette, approved (DEC-015) so the real onRequestApproved Function
//     matches it, then accepted by the first donor — the portal has a donation to confirm;
//   - one URGENT request left PENDING — the portal's review queue has something to approve live.
//
// The emulator must be running with Functions (`npm run emulators:app`).
//
//   npm run seed:demo             # emulator, project lifelinkkh. Clears requests/matches/donations first.
//
// Emulator only, by design: it deletes data.
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { geohashForLocation } from 'geofire-common';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
initializeApp({ projectId: 'lifelinkkh' });
const db = getFirestore();
const now = () => FieldValue.serverTimestamp();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
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
// The admin's approval, as reviewRequest writes it — the PENDING → OPEN update is what fires matching.
await request.update({ status: 'OPEN', reviewedBy: 'demo-seed', reviewedAt: now(), updatedAt: now() });

// The match document, not `matchedAt`: the Function claims `matchedAt` first and writes the
// matches after, so waiting on the claim races the write.
const match = db.doc('matches/demo-request_demo-donor-a');
for (let i = 0; i < 30 && !(await match.get()).exists; i++) await sleep(1000);
if (!(await match.get()).exists) {
  console.error('onRequestApproved never ran. Start the emulators with Functions: npm run emulators:app');
  process.exit(1);
}
await match.update({ response: 'ACCEPTED', respondedAt: Timestamp.now() });
for (let i = 0; i < 30 && !(await request.collection('acceptedDonors').doc('demo-donor-a').get()).exists; i++) await sleep(1000);

await post('demo-pending', { patientBloodType: 'O+', urgency: 'URGENT' });

const r = (await request.get()).data();
console.log(`demo request: ${r.alertedCount} donors alerted, ${r.acceptedCount} accepted — ready to confirm in the portal`);
console.log('demo-pending: waiting in the portal\'s review queue');
process.exit(0);
