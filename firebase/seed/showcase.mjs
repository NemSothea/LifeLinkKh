// A fuller demo than demo.mjs, for screenshots and walkthroughs that should look like a city in
// use rather than a two-row test: 24 donors across Phnom Penh, 15 requests over the last 30 days
// at all five hospitals, in every state a request can be in. Everything past the plain inserts
// goes through the portal's own handlers (ADR 0010) — approval runs the real matching, answers go
// through respondToMatch, donations through confirmDonation — so the counters, matches and
// cooldowns agree with each other exactly as live traffic would leave them.
//
// The emulator must be running (`npm run emulators:app`), with `npm run seed:app` done.
//
//   npm run seed:showcase                 # clears requests/matches/donations first
//   npm run seed:showcase -- --me <uid>   # also give that signed-in donor alerts and a history
//
// --me is for the phone in the screenshots: sign in on the emulator stack first, copy the uid
// from the Emulator UI (Firestore → users), then run with it. That user becomes an O+ donor in
// Doun Penh with two past donations (old enough to be eligible again) and is matched like
// everyone else, so Home shows real alerts.
//
// Emulator only, by design: it deletes data.
import { geohashForLocation } from 'geofire-common';
import { FieldValue, Timestamp, getFirestore, initializeApp } from '../../frontend/src/server/admin-sdk.js';
import { handleRequestApproved, handleRequestCreated } from '../../frontend/src/server/request-lifecycle.js';
import { respondToMatch } from '../../frontend/src/server/respond-to-match.js';
import { confirmDonation } from '../../frontend/src/server/confirm-donation.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
if (!process.env.FIRESTORE_EMULATOR_HOST.startsWith('127.0.0.1') && !process.env.FIRESTORE_EMULATOR_HOST.startsWith('localhost')) {
  console.error('showcase seeds the local emulator only.');
  process.exit(1);
}
initializeApp({ projectId: 'lifelinkkh' });
const db = getFirestore();
const meIndex = process.argv.indexOf('--me');
const me = meIndex > 0 ? process.argv[meIndex + 1] : null;

const messaging = {
  async sendEach(messages) {
    await Promise.all(messages.map((m) => db.collection('_outbox').add(m)));
    return { responses: messages.map(() => ({ success: true })) };
  },
};
const quiet = { info() {}, warn() {} };
const DAY = 86_400_000;
const ago = (days, hours = 0) => Timestamp.fromDate(new Date(Date.now() - days * DAY - hours * 3_600_000));
const isoDaysAgo = (days) => new Date(Date.now() + 7 * 3_600_000 - days * DAY).toISOString().slice(0, 10);

const HOSPITAL = {
  calmette: '8c251b94-1968-481a-9b77-112b87790b00',
  soviet: '49f3c5c0-3e53-4c06-aa17-5d21a6b32d81',
  nbtc: '8481fa05-c745-4556-bf6d-cef865e9f9a4',
  pediatric: 'c7ddaa1b-e440-47d4-85af-9563bcf16d95',
  kossamak: 'c861db1e-6afa-4bf7-96d6-8f9a824e1ff6',
};
// Rough centre of each khan, three decimals as the app stores a fix (ADR 0003).
const DISTRICT = {
  1201: [11.548, 104.924], 1202: [11.573, 104.917], 1203: [11.565, 104.905], 1204: [11.575, 104.894],
  1205: [11.496, 104.866], 1206: [11.521, 104.925], 1207: [11.626, 104.905], 1208: [11.573, 104.853],
  1209: [11.544, 104.833], 1210: [11.595, 104.939], 1211: [11.656, 104.868], 1212: [11.530, 104.950],
  1213: [11.555, 104.920], 1214: [11.520, 104.790],
};

// name, blood type, district, sex, available. Blood types weighted roughly as in Cambodia —
// mostly O+, B+ and A+, a handful of AB and negatives.
const DONORS = [
  ['Nem Sothea', 'O+', 1202, 'M', true], ['Sok Dara', 'O-', 1202, 'F', true],
  ['Chan Vuthy', 'B+', 1201, 'M', true], ['Lim Sreymom', 'A+', 1213, 'F', true],
  ['Heng Pisey', 'O+', 1204, 'F', true], ['Kim Sokha', 'B+', 1203, 'M', true],
  ['Chea Rithy', 'AB+', 1210, 'M', true], ['Pich Chanthou', 'O+', 1206, 'F', true],
  ['Ouk Visal', 'A+', 1208, 'M', true], ['Seng Kanha', 'B-', 1212, 'F', true],
  ['Mao Bunthoeun', 'O+', 1207, 'M', true], ['Ros Sreyneang', 'A-', 1201, 'F', true],
  ['Touch Sovann', 'B+', 1205, 'M', false], ['Keo Monika', 'O+', 1213, 'F', true],
  ['Phan Rotha', 'AB-', 1202, 'M', true], ['Nhem Sreyleak', 'B+', 1204, 'F', true],
  ['Say Bora', 'O+', 1209, 'M', true], ['Yim Sopheap', 'A+', 1203, 'F', true],
  ['Tep Chhay', 'O-', 1206, 'M', true], ['Van Malis', 'B+', 1213, 'F', true],
  ['Ly Sambath', 'A+', 1210, 'M', true], ['Hun Sreypov', 'O+', 1201, 'F', false],
  ['Meas Piseth', 'B+', 1211, 'M', true], ['Srun Theary', 'AB+', 1212, 'F', true],
];
const REQUESTERS = [
  ['showcase-family-1', 'Chea Srey', '+85512345678'], ['showcase-family-2', 'Sok Chenda', '+85598765432'],
  ['showcase-family-3', 'Mean Rotanak', '+85511223344'], ['showcase-family-4', 'Kong Sreypich', '+85517654321'],
  ['showcase-family-5', 'Hor Vannak', '+85569988776'],
];
const ADMIN = { uid: 'showcase-admin', token: { role: 'ADMIN' } };

for (const collection of ['requests', 'matches', 'donations']) {
  await db.recursiveDelete(db.collection(collection));
}
await db.doc(`admins/${ADMIN.uid}`).set({ displayName: 'Showcase seed', createdAt: ago(40) });

const donorIds = [];
for (const [i, [name, bloodType, district, sex, isAvailable]] of DONORS.entries()) {
  const uid = `showcase-donor-${String(i + 1).padStart(2, '0')}`;
  donorIds.push(uid);
  const [lat, lng] = DISTRICT[district];
  const joined = ago(10 + ((i * 7) % 50)); // spread sign-ups for the dashboard's donor metric
  await db.doc(`users/${uid}`).set({ displayName: name, language: i % 3 ? 'km' : 'en', role: 'DONOR', fcmToken: null, createdAt: joined, updatedAt: joined });
  await db.doc(`donors/${uid}`).set({
    fullName: name, bloodType, districtCode: String(district), lastDonationDate: null, isAvailable, sex,
    lat, lng, geohash: geohashForLocation([lat, lng], 7), createdAt: joined, updatedAt: joined,
  });
}
for (const [uid, name] of REQUESTERS) {
  await db.doc(`users/${uid}`).set({ displayName: name, language: 'km', role: 'REQUESTER', fcmToken: null, createdAt: ago(35), updatedAt: ago(35) });
}

if (me) {
  const user = await db.doc(`users/${me}`).get();
  if (!user.exists) {
    console.error(`--me ${me}: no such user. Sign in on the phone first (emulator build).`);
    process.exit(1);
  }
  // Registered on the phone already, or not: either way the showcase donor is O+ in Doun Penh,
  // the type and place the most showcase requests can reach.
  const [lat, lng] = DISTRICT[1202];
  await db.doc(`donors/${me}`).set({
    fullName: user.get('displayName') || 'LifeLink donor', bloodType: 'O+', districtCode: '1202',
    lastDonationDate: null, isAvailable: true, sex: 'M',
    lat, lng, geohash: geohashForLocation([lat, lng], 7), createdAt: ago(200), updatedAt: ago(200),
  }, { merge: true });
  // Two past donations, both long enough ago that the donor is eligible again today.
  for (const [n, days] of [[1, 400], [2, 190]]) {
    await db.doc(`donations/showcase-me-${n}`).set({
      donorUid: me, requestId: null, hospitalId: n === 1 ? HOSPITAL.nbtc : HOSPITAL.calmette,
      donatedOn: Timestamp.fromDate(new Date(`${isoDaysAgo(days)}T00:00:00+07:00`)),
      confirmedBy: ADMIN.uid, createdAt: ago(days),
    });
  }
  await db.doc(`donors/${me}`).update({
    lastDonationDate: Timestamp.fromDate(new Date(`${isoDaysAgo(190)}T00:00:00+07:00`)), updatedAt: FieldValue.serverTimestamp(),
  });
}

let family = 0;
async function post(id, { daysAgo, hours = 0, ...fields }) {
  const [createdBy, contactName, contactPhone] = REQUESTERS[family++ % REQUESTERS.length];
  const ref = db.doc(`requests/${id}`);
  const batch = db.batch();
  batch.set(ref, {
    createdBy, unitsNeeded: 1, status: 'PENDING', alertedCount: 0, acceptedCount: 0,
    createdAt: ago(daysAgo, hours), updatedAt: ago(daysAgo, hours), ...fields,
  });
  batch.set(ref.collection('private').doc('contact'), { contactName, contactPhone });
  await batch.commit();
  // As createRequest's trigger does: the rate limit, and the hospital name the review queue shows.
  await handleRequestCreated({ db, requestId: id, log: quiet });
  return ref;
}

async function approve(ref, daysAgo, hours) {
  await ref.update({ status: 'OPEN', reviewedBy: ADMIN.uid, reviewedAt: ago(daysAgo, Math.max(0, hours - 1)), updatedAt: FieldValue.serverTimestamp() });
  return handleRequestApproved({ db, messaging, requestId: ref.id, log: quiet });
}

/** The alerted donors of a request, nearest first as matching stored them — `me` left for the phone to answer. */
async function alerted(requestId) {
  const snaps = await db.collection('matches').where('requestId', '==', requestId).get();
  return snaps.docs
    .sort((a, b) => (a.get('distanceKm') ?? 0) - (b.get('distanceKm') ?? 0))
    .map((d) => d.get('donorUid'))
    .filter((uid) => uid !== me);
}

async function answer(requestId, donorId, response) {
  await respondToMatch({ db, messaging, caller: { uid: donorId, token: {} }, data: { matchId: `${requestId}_${donorId}`, response }, log: quiet });
}

// [id, hospital, patient type, urgency, units, days ago, hours, what happens]
const REQUESTS = [
  ['showcase-01', 'calmette', 'O+', 'CRITICAL', 2, 0, 2, 'open-accepted'],
  ['showcase-02', 'pediatric', 'A+', 'CRITICAL', 1, 0, 5, 'open'],
  ['showcase-03', 'soviet', 'B+', 'URGENT', 2, 1, 3, 'open-accepted'],
  ['showcase-04', 'kossamak', 'O-', 'CRITICAL', 1, 1, 9, 'open'],
  ['showcase-05', 'nbtc', 'AB+', 'ROUTINE', 1, 2, 4, 'open-accepted'],
  ['showcase-06', 'calmette', 'A-', 'URGENT', 1, 3, 1, 'open'],
  ['showcase-07', 'soviet', 'O+', 'URGENT', 1, 5, 6, 'fulfilled'],
  ['showcase-08', 'pediatric', 'B+', 'CRITICAL', 1, 8, 2, 'fulfilled'],
  ['showcase-09', 'kossamak', 'A+', 'ROUTINE', 1, 12, 7, 'fulfilled'],
  ['showcase-10', 'nbtc', 'O+', 'URGENT', 1, 17, 3, 'fulfilled'],
  ['showcase-11', 'calmette', 'B-', 'ROUTINE', 1, 24, 5, 'rejected'],
  ['showcase-12', 'soviet', 'AB-', 'URGENT', 1, 27, 2, 'cancelled'],
  ['showcase-13', 'calmette', 'O+', 'CRITICAL', 1, 0, 1, 'pending'],
  ['showcase-14', 'pediatric', 'B+', 'URGENT', 2, 0, 3, 'pending'],
  ['showcase-15', 'kossamak', 'A+', 'ROUTINE', 1, 0, 6, 'pending'],
];

const tally = {};
for (const [id, hospital, patientBloodType, urgency, unitsNeeded, daysAgo, hours, fate] of REQUESTS) {
  tally[fate] = (tally[fate] ?? 0) + 1;
  const ref = await post(id, { hospitalId: HOSPITAL[hospital], patientBloodType, urgency, unitsNeeded, daysAgo, hours });
  if (fate === 'pending') continue;
  if (fate === 'rejected') {
    await ref.update({
      status: 'REJECTED', reviewedBy: ADMIN.uid, reviewedAt: ago(daysAgo, hours - 1),
      rejectionReason: 'The hospital could not confirm this patient — please ask the ward to post it.',
      updatedAt: FieldValue.serverTimestamp(),
    });
    continue;
  }
  await approve(ref, daysAgo, hours);
  const donors = await alerted(id);
  if (fate === 'cancelled') {
    await ref.update({ status: 'CANCELLED', updatedAt: FieldValue.serverTimestamp() });
    continue;
  }
  if (fate === 'open') {
    if (donors[1]) await answer(id, donors[1], 'DECLINED');
    continue;
  }
  // Accepted, and for the fulfilled ones confirmed, by the nearest donor(s).
  const accepting = donors.slice(0, fate === 'fulfilled' ? unitsNeeded : Math.min(unitsNeeded, 2));
  for (const d of accepting) await answer(id, d, 'ACCEPTED');
  if (donors[accepting.length]) await answer(id, donors[accepting.length], 'DECLINED');
  if (fate === 'fulfilled') {
    for (const d of accepting) {
      await confirmDonation({ db, caller: ADMIN, data: { requestId: id, matchId: `${id}_${d}`, donatedOn: isoDaysAgo(Math.max(0, daysAgo - 1)) }, log: quiet });
    }
  }
}

// Timings. The handlers stamp reviewedAt/notifiedAt/respondedAt with the server's clock — today —
// but the requests are backdated, so left alone the dashboard would read "7,560 minutes to first
// accept" and, with no FCM token on any seeded donor, "0% delivered". Put each one where live
// traffic would: reviewed 10–45 minutes after posting, alerts out a minute later (one in thirty
// failing, as a real send occasionally does), answers 3–25 minutes after that.
const jitter = (seed, lo, hi) => lo + (((seed * 2654435761) >>> 0) % (hi - lo + 1));
const minutes = (ts, m) => Timestamp.fromMillis(ts.toMillis() + m * 60_000);
let n = 0;
for (const req of (await db.collection('requests').get()).docs) {
  if (!req.get('reviewedAt')) continue;
  const reviewedAt = minutes(req.get('createdAt'), jitter(++n, 10, 45));
  await req.ref.update({ reviewedAt });
  const batch = db.batch();
  for (const m of (await db.collection('matches').where('requestId', '==', req.id).get()).docs) {
    const notifiedAt = ++n % 30 === 0 ? null : minutes(reviewedAt, 1);
    const answered = m.get('response') && notifiedAt;
    batch.update(m.ref, { notifiedAt, ...(answered ? { respondedAt: minutes(notifiedAt, jitter(n, 3, 25)) } : {}) });
  }
  await batch.commit();
}

const open = await db.collection('requests').where('status', '==', 'OPEN').get();
const alerts = (await db.collection('matches').count().get()).data().count;
console.log(`showcase: ${DONORS.length} donors, ${REQUESTS.length} requests (${Object.entries(tally).map(([k, v]) => `${v} ${k}`).join(', ')})`);
console.log(`          ${open.size} open on the board, ${alerts} donor alerts${me ? `, --me ${me} included` : ''}`);
process.exit(0);
