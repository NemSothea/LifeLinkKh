// ADR 0009: a rule without a test is treated as absent. One describe per collection, and each
// privacy rule the Spring Boot API enforced has a test named after the class that enforced it.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const HOSPITAL = 'calmette';
const OTHER_HOSPITAL = 'khmer-soviet';
const DISTRICT = '1201';

let env;

const anon = () => env.unauthenticatedContext().firestore();
const as = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();
const staff = (hospitalId = HOSPITAL) => as('staff-1', { role: 'HOSPITAL', hospitalId });
const admin = () => as('admin-1', { role: 'ADMIN' });

/** Writes with rules off — the Admin SDK's view, used to arrange each test. */
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const donor = (overrides = {}) => ({
  fullName: 'Sok Dara',
  bloodType: 'A+',
  districtCode: DISTRICT,
  lastDonationDate: null,
  isAvailable: true,
  lat: null,
  lng: null,
  geohash: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const newRequest = (createdBy, overrides = {}) => ({
  createdBy,
  hospitalId: HOSPITAL,
  patientBloodType: 'AB+',
  unitsNeeded: 2,
  urgency: 'CRITICAL',
  status: 'OPEN',
  alertedCount: 0,
  acceptedCount: 0,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const contact = { contactName: 'Chea Srey', contactPhone: '+85512345678' };

/** An open request by `requester`, with its contact, and a match for `donorUid`. */
async function seedRequestWithMatch(requester, donorUid, { status = 'OPEN', response = null } = {}) {
  await seed(async (db) => {
    await setDoc(doc(db, 'requests/r1'), { ...newRequest(requester), status });
    await setDoc(doc(db, 'requests/r1/private/contact'), contact);
    await setDoc(doc(db, `matches/r1_${donorUid}`), {
      requestId: 'r1',
      donorUid,
      requesterUid: requester,
      hospitalId: HOSPITAL,
      distanceKm: 2.5,
      notifiedAt: Timestamp.now(),
      response,
      respondedAt: null,
    });
  });
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lifelink',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, `districts/${DISTRICT}`), { nameEn: 'Doun Penh', nameKm: 'ដូនពេញ' });
    await setDoc(doc(db, `hospitals/${HOSPITAL}`), { name: 'Calmette Hospital', districtCode: DISTRICT });
    await setDoc(doc(db, `hospitals/${OTHER_HOSPITAL}`), { name: 'Khmer-Soviet Friendship Hospital', districtCode: DISTRICT });
  });
});

describe('reference data', () => {
  test('anyone reads hospitals and districts, signed out included', async () => {
    await assertSucceeds(getDoc(doc(anon(), `hospitals/${HOSPITAL}`)));
    await assertSucceeds(getDoc(doc(anon(), `districts/${DISTRICT}`)));
  });

  test('nobody writes them from a client, not even an admin', async () => {
    await assertFails(setDoc(doc(admin(), 'hospitals/new'), { name: 'X' }));
    await assertFails(setDoc(doc(as('u1'), `districts/${DISTRICT}`), { nameEn: 'X' }));
  });
});

describe('users', () => {
  const user = (overrides = {}) => ({
    displayName: 'Sok Dara',
    language: 'km',
    role: 'DONOR',
    fcmToken: null,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('you create and read your own user doc', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'users/u1'), user()));
    await assertSucceeds(getDoc(doc(as('u1'), 'users/u1')));
  });

  test('another user cannot read it — the FCM token addresses a push to you', async () => {
    await seed((db) => setDoc(doc(db, 'users/u1'), user({ fcmToken: 'token' })));
    await assertFails(getDoc(doc(as('u2'), 'users/u1')));
    await assertFails(getDoc(doc(staff(), 'users/u1')));
    await assertSucceeds(getDoc(doc(admin(), 'users/u1')));
  });

  test('a client cannot give itself a staff role — roles are claims, not fields', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ role: 'ADMIN' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ role: 'HOSPITAL' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ hospitalId: HOSPITAL })));
  });

  test('you cannot write someone else\'s user doc', async () => {
    await assertFails(setDoc(doc(as('u2'), 'users/u1'), user()));
  });
});

describe('donors', () => {
  test('you register your own profile, without GPS (ADR 0003)', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'donors/u1'), donor()));
  });

  test('with GPS all three coordinate fields are set', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.5806, lng: 104.9165, geohash: 'w3gv' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.5806, lng: 104.9165, geohash: null })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ lat: 95, lng: 104.9, geohash: 'w3gv' })));
  });

  test('a profile for someone else is refused', async () => {
    await assertFails(setDoc(doc(as('u2'), 'donors/u1'), donor()));
  });

  test('values the database used to CHECK are still refused', async () => {
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ bloodType: 'C+' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ districtCode: '9999' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ fullName: '   ' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ isEligible: true })));
  });

  test('a last-donation date in the future is refused', async () => {
    const future = Timestamp.fromMillis(Date.now() + 7 * 86_400_000);
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ lastDonationDate: future })));
  });

  test('nobody but the donor and an admin reads a profile — not staff, not a requester', async () => {
    await seed((db) => setDoc(doc(db, 'donors/u1'), donor()));
    await assertSucceeds(getDoc(doc(as('u1'), 'donors/u1')));
    await assertFails(getDoc(doc(as('u2'), 'donors/u1')));
    await assertFails(getDoc(doc(staff(), 'donors/u1')));
    await assertFails(getDoc(doc(anon(), 'donors/u1')));
    await assertSucceeds(getDoc(doc(admin(), 'donors/u1')));
  });
});

describe('requests', () => {
  test('a signed-in user posts a request with its contact in one batch', async () => {
    const db = as('req-1');
    const batch = writeBatch(db);
    batch.set(doc(db, 'requests/r1'), newRequest('req-1'));
    batch.set(doc(db, 'requests/r1/private/contact'), contact);
    await assertSucceeds(batch.commit());
  });

  test('signed out cannot post', async () => {
    await assertFails(setDoc(doc(anon(), 'requests/r1'), newRequest('req-1')));
  });

  test('you cannot post as someone else', async () => {
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('someone-else')));
  });

  test('a new request starts OPEN with zero counts — counts belong to the Function', async () => {
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { status: 'FULFILLED' })));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { alertedCount: 25 })));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { acceptedCount: 1 })));
  });

  test('invalid values are refused', async () => {
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { unitsNeeded: 0 })));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { urgency: 'SOON' })));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { hospitalId: 'nowhere' })));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1', { patientBloodType: 'AB' })));
  });

  test('the contact must be a Cambodian mobile, normalized to +855', async () => {
    for (const bad of ['012345678', '+85513345678', '+8551234567', '+855181234567 ', '+1 555 0100']) {
      const db = as('req-1');
      const batch = writeBatch(db);
      batch.set(doc(db, 'requests/r1'), newRequest('req-1'));
      batch.set(doc(db, 'requests/r1/private/contact'), { ...contact, contactPhone: bad });
      await assertFails(batch.commit());
    }
    const db = as('req-1');
    const batch = writeBatch(db);
    batch.set(doc(db, 'requests/r1'), newRequest('req-1'));
    batch.set(doc(db, 'requests/r1/private/contact'), { ...contact, contactPhone: '+855181234567' });
    await assertSucceeds(batch.commit());
  });

  test('you cannot attach a contact to someone else\'s request', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    await assertFails(setDoc(doc(as('intruder'), 'requests/r1/private/contact'), contact));
  });

  test('the public board reads requests signed out (DEC-009)', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    await assertSucceeds(getDoc(doc(anon(), 'requests/r1')));
    await assertSucceeds(getDoc(doc(anon(), 'requests/r1/acceptedDonors/d1')));
  });

  test('the creator cancels an open request and changes nothing else', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    const db = as('req-1');
    await assertFails(updateDoc(doc(db, 'requests/r1'), { status: 'CANCELLED', updatedAt: serverTimestamp(), unitsNeeded: 9 }));
    await assertFails(updateDoc(doc(db, 'requests/r1'), { status: 'FULFILLED', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, 'requests/r1'), { status: 'CANCELLED', updatedAt: serverTimestamp() }));
  });

  test('nobody else cancels it, and a closed request stays closed', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1', { status: 'FULFILLED' })));
    await assertFails(updateDoc(doc(as('req-1'), 'requests/r1'), { status: 'CANCELLED', updatedAt: serverTimestamp() }));
    await seed((db) => setDoc(doc(db, 'requests/r2'), newRequest('req-1')));
    await assertFails(updateDoc(doc(as('other'), 'requests/r2'), { status: 'CANCELLED', updatedAt: serverTimestamp() }));
  });

  test('the board\'s accepted-donor list is written by the Function only', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    await assertFails(setDoc(doc(as('d1'), 'requests/r1/acceptedDonors/d1'), { displayName: 'Me' }));
  });
});

describe('requester contact — RequestViews.requesterContact', () => {
  test('the creator reads it', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertSucceeds(getDoc(doc(as('req-1'), 'requests/r1/private/contact')));
  });

  test('a matched donor who has not answered does not', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(getDoc(doc(as('d1'), 'requests/r1/private/contact')));
  });

  test('a donor who declined does not', async () => {
    await seedRequestWithMatch('req-1', 'd1', { response: 'DECLINED' });
    await assertFails(getDoc(doc(as('d1'), 'requests/r1/private/contact')));
  });

  test('a donor who accepted does', async () => {
    await seedRequestWithMatch('req-1', 'd1', { response: 'ACCEPTED' });
    await assertSucceeds(getDoc(doc(as('d1'), 'requests/r1/private/contact')));
  });

  test('staff, strangers and the signed-out board do not', async () => {
    await seedRequestWithMatch('req-1', 'd1', { response: 'ACCEPTED' });
    await assertFails(getDoc(doc(staff(), 'requests/r1/private/contact')));
    await assertFails(getDoc(doc(as('stranger'), 'requests/r1/private/contact')));
    await assertFails(getDoc(doc(anon(), 'requests/r1/private/contact')));
  });

  test('nobody edits it after posting', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(updateDoc(doc(as('req-1'), 'requests/r1/private/contact'), { contactPhone: '+85599123456' }));
  });
});

describe('matches — MatchService.respond', () => {
  test('only the Function creates a match (ADR 0008: only notified donors get one)', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    await assertFails(setDoc(doc(as('d1'), 'matches/r1_d1'), {
      requestId: 'r1', donorUid: 'd1', requesterUid: 'req-1', hospitalId: HOSPITAL, response: null,
    }));
  });

  test('the donor reads their own match; another donor does not', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertSucceeds(getDoc(doc(as('d1'), 'matches/r1_d1')));
    await assertFails(getDoc(doc(as('d2'), 'matches/r1_d1')));
    await assertFails(getDoc(doc(anon(), 'matches/r1_d1')));
  });

  test('staff read matches at their own hospital only', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertSucceeds(getDoc(doc(staff(HOSPITAL), 'matches/r1_d1')));
    await assertFails(getDoc(doc(staff(OTHER_HOSPITAL), 'matches/r1_d1')));
    await assertFails(getDoc(doc(as('staff-no-claim', { hospitalId: HOSPITAL }), 'matches/r1_d1')));
  });

  test('the donor accepts or declines, once', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    const ref = doc(as('d1'), 'matches/r1_d1');
    await assertSucceeds(updateDoc(ref, { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
    // ALREADY_RESPONDED: one answer, never overwritten.
    await assertFails(updateDoc(ref, { response: 'DECLINED', respondedAt: serverTimestamp() }));
  });

  test('UNKNOWN_RESPONSE and WITHDRAWN are refused', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    const ref = doc(as('d1'), 'matches/r1_d1');
    await assertFails(updateDoc(ref, { response: 'MAYBE', respondedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { response: 'WITHDRAWN', respondedAt: serverTimestamp() }));
  });

  test('the donor cannot touch anything but the answer', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(updateDoc(doc(as('d1'), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp(), distanceKm: 0 }));
  });

  test('NOT_YOUR_MATCH: another donor cannot answer it', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(updateDoc(doc(as('d2'), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
  });

  test('a cancelled request takes no answers', async () => {
    await seedRequestWithMatch('req-1', 'd1', { status: 'CANCELLED' });
    await assertFails(updateDoc(doc(as('d1'), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
  });
});

describe('donations', () => {
  beforeEach(() => seed((db) => setDoc(doc(db, 'donations/x1'), {
    donorUid: 'd1', hospitalId: HOSPITAL, requestId: 'r1', donatedOn: Timestamp.now(), confirmedBy: 'staff-1',
  })));

  test('the donor, their hospital\'s staff and an admin read it', async () => {
    await assertSucceeds(getDoc(doc(as('d1'), 'donations/x1')));
    await assertSucceeds(getDoc(doc(staff(HOSPITAL), 'donations/x1')));
    await assertSucceeds(getDoc(doc(admin(), 'donations/x1')));
  });

  test('another donor and another hospital do not', async () => {
    await assertFails(getDoc(doc(as('d2'), 'donations/x1')));
    await assertFails(getDoc(doc(staff(OTHER_HOSPITAL), 'donations/x1')));
  });

  test('no client records a donation — not even the donor or staff', async () => {
    const donation = { donorUid: 'd1', hospitalId: HOSPITAL, donatedOn: Timestamp.now() };
    await assertFails(setDoc(doc(as('d1'), 'donations/x2'), donation));
    await assertFails(setDoc(doc(staff(), 'donations/x2'), donation));
  });
});
