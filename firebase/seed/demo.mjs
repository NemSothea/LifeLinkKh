// Demo data for the emulator (ADR 0009, phase 6) — what scripts/seed-demo-request.sql and
// reset-demo-data.sql did for Postgres. Two O- donors in Doun Penh, one requester, and one open
// CRITICAL request at Calmette. The request goes through the real onRequestCreated Function, so
// the emulator must be running with Functions (`npm run emulators:app`); this waits for it to
// match, then has the first donor accept so the portal has a donation to confirm.
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

const request = db.doc('requests/demo-request');
const batch = db.batch();
batch.set(request, {
  createdBy: 'demo-family', hospitalId: CALMETTE, patientBloodType: 'AB+', unitsNeeded: 1,
  urgency: 'CRITICAL', status: 'OPEN', alertedCount: 0, acceptedCount: 0, createdAt: now(), updatedAt: now(),
});
batch.set(request.collection('private').doc('contact'), { contactName: 'Chea Srey', contactPhone: '+85512345678' });
await batch.commit();

// The match document, not `matchedAt`: the Function claims `matchedAt` first and writes the
// matches after, so waiting on the claim races the write.
const match = db.doc('matches/demo-request_demo-donor-a');
for (let i = 0; i < 30 && !(await match.get()).exists; i++) await sleep(1000);
if (!(await match.get()).exists) {
  console.error('onRequestCreated never ran. Start the emulators with Functions: npm run emulators:app');
  process.exit(1);
}
await match.update({ response: 'ACCEPTED', respondedAt: Timestamp.now() });
for (let i = 0; i < 30 && !(await request.collection('acceptedDonors').doc('demo-donor-a').get()).exists; i++) await sleep(1000);

const r = (await request.get()).data();
console.log(`demo request: ${r.alertedCount} donors alerted, ${r.acceptedCount} accepted — ready to confirm in the portal`);
process.exit(0);
