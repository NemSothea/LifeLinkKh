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
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const HOSPITAL = 'calmette';
const OTHER_HOSPITAL = 'khmer-soviet';
const DISTRICT = '1201';

let env;

const anon = () => env.unauthenticatedContext().firestore();
const as = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();
// v1 has no hospital staff. A HOSPITAL claim left on some token must grant nothing.
const hospitalClaim = (hospitalId = HOSPITAL) => as('staff-1', { role: 'HOSPITAL', hospitalId });
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
  status: 'PENDING',
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
    // seed/admin.mjs writes this record alongside the claim; admin() needs both.
    await setDoc(doc(db, 'admins/admin-1'), { displayName: 'Soborey', username: 'soborey' });
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
    await assertFails(getDoc(doc(hospitalClaim(), 'users/u1')));
    await assertSucceeds(getDoc(doc(admin(), 'users/u1')));
  });

  test('a client cannot give itself a staff role — roles are claims, not fields', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ role: 'ADMIN' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ role: 'HOSPITAL' })));
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), user({ hospitalId: HOSPITAL })));
  });

  // SEC-REVIEW-003 F-18: an update, not only a create, and a list query as a stranger.
  test('you cannot update someone else\'s user doc, or list user docs', async () => {
    await seed((db) => setDoc(doc(db, 'users/u1'), {
      language: 'en', role: 'DONOR', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    }));
    await assertFails(updateDoc(doc(as('u2'), 'users/u1'), { language: 'km', updatedAt: serverTimestamp() }));
    await assertFails(getDocs(collection(as('u2'), 'users')));
  });

  test('you cannot write someone else\'s user doc', async () => {
    await assertFails(setDoc(doc(as('u2'), 'users/u1'), user()));
  });
});

describe('users/{uid}/notifications — the bell', () => {
  const entry = (overrides = {}) => ({
    type: 'REQUEST_ALERT',
    requestId: 'r1',
    title: 'Urgent blood request',
    body: 'AB+ needed at Calmette Hospital',
    createdAt: Timestamp.now(),
    readAt: null,
    ...overrides,
  });
  const PATH = 'users/u1/notifications/REQUEST_ALERT_r1';

  beforeEach(() => seed((db) => setDoc(doc(db, PATH), entry())));

  test('the owner reads their own inbox, as a list and one by one', async () => {
    await assertSucceeds(getDoc(doc(as('u1'), PATH)));
    await assertSucceeds(getDocs(collection(as('u1'), 'users/u1/notifications')));
  });

  test('nobody else reads it — not another user, not an admin, not signed out', async () => {
    await assertFails(getDoc(doc(as('u2'), PATH)));
    await assertFails(getDocs(collection(as('u2'), 'users/u1/notifications')));
    await assertFails(getDoc(doc(admin(), PATH)));
    await assertFails(getDoc(doc(anon(), PATH)));
  });

  test('the owner marks it read with the server clock, and that is all', async () => {
    await assertFails(updateDoc(doc(as('u1'), PATH), { readAt: Timestamp.fromMillis(0) }));
    await assertFails(
      updateDoc(doc(as('u1'), PATH), { readAt: serverTimestamp(), body: 'changed' }),
    );
    await assertFails(updateDoc(doc(as('u2'), PATH), { readAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(as('u1'), PATH), { readAt: serverTimestamp() }));
    // Read stays read: no un-reading, no second stamp.
    await assertFails(updateDoc(doc(as('u1'), PATH), { readAt: null }));
    await assertFails(updateDoc(doc(as('u1'), PATH), { readAt: serverTimestamp() }));
  });

  test('no client files or deletes an entry — only the server does', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1/notifications/forged'), entry()));
    await assertFails(setDoc(doc(admin(), 'users/u1/notifications/forged'), entry()));
    await assertFails(deleteDoc(doc(as('u1'), PATH)));
  });
});

describe('donors', () => {
  test('you register your own profile, without GPS (ADR 0003)', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'donors/u1'), donor()));
  });

  test('with GPS all three coordinate fields are set', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.581, lng: 104.917, geohash: 'w649gkj' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.581, lng: 104.917, geohash: null })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ lat: 95, lng: 104.9, geohash: 'w649gkj' })));
  });

  test('a profile for someone else is refused', async () => {
    await assertFails(setDoc(doc(as('u2'), 'donors/u1'), donor()));
  });

  // SEC-REVIEW-003 F-18.
  test('an update of someone else\'s profile is refused, and nobody lists profiles', async () => {
    await seed((db) => setDoc(doc(db, 'donors/u1'), donor({ createdAt: Timestamp.now() })));
    await assertFails(updateDoc(doc(as('u2'), 'donors/u1'), { isAvailable: false, updatedAt: serverTimestamp() }));
    await assertFails(getDocs(collection(as('u2'), 'donors')));
    await assertFails(getDocs(collection(anon(), 'donors')));
  });

  // SEC-REVIEW-003 F-12, tightened by SEC-REVIEW-005 M-04: a ~150 m cell is what matching needs;
  // the old 10-character (~1 m) geohash is refused too. A district code is short.
  test('a geohash finer than seven characters, or an overlong district code, is refused', async () => {
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.581, lng: 104.917, geohash: 'w649gkjv' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'),
      donor({ lat: 11.5806, lng: 104.9165, geohash: 'w649gkjvgs' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ districtCode: 'x'.repeat(17) })));
  });

  test('values the database used to CHECK are still refused', async () => {
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ bloodType: 'C+' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ districtCode: '9999' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ fullName: '   ' })));
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ isEligible: true })));
  });

  // DEC-019: sex sets the donation interval. Optional; only M, F or null.
  test('sex may be M, F, null, or absent — nothing else', async () => {
    await assertSucceeds(setDoc(doc(as('u1'), 'donors/u1'), donor({ sex: 'M' })));
    await assertSucceeds(setDoc(doc(as('u2'), 'donors/u2'), donor({ sex: 'F' })));
    await assertSucceeds(setDoc(doc(as('u3'), 'donors/u3'), donor({ sex: null })));
    await assertSucceeds(setDoc(doc(as('u4'), 'donors/u4'), donor()));
    await assertFails(setDoc(doc(as('u5'), 'donors/u5'), donor({ sex: 'X' })));
    await assertFails(setDoc(doc(as('u5'), 'donors/u5'), donor({ sex: 1 })));
  });

  test('a last-donation date in the future is refused', async () => {
    const future = Timestamp.fromMillis(Date.now() + 7 * 86_400_000);
    await assertFails(setDoc(doc(as('u1'), 'donors/u1'), donor({ lastDonationDate: future })));
  });

  // SEC-REVIEW-003 F-04: matching reads lastDonationDate and sex, so the donor cannot reset them.
  describe('the cooldown a confirmed donation set', () => {
    const DAY = 86_400_000;
    const lastDonation = Timestamp.fromMillis(Date.now() - 30 * DAY);
    const stored = (overrides = {}) => donor({
      lastDonationDate: lastDonation, sex: 'F', createdAt: Timestamp.fromMillis(Date.now() - 90 * DAY),
      ...overrides,
    });
    const edit = () => seed((db) => setDoc(doc(db, 'donors/u1'), stored()));

    test('an edit that keeps both goes through', async () => {
      await edit();
      await assertSucceeds(updateDoc(doc(as('u1'), 'donors/u1'), { isAvailable: false, updatedAt: serverTimestamp() }));
    });

    test('the last donation cannot be cleared or moved earlier', async () => {
      await edit();
      await assertFails(updateDoc(doc(as('u1'), 'donors/u1'), { lastDonationDate: null, updatedAt: serverTimestamp() }));
      await assertFails(updateDoc(doc(as('u1'), 'donors/u1'), {
        lastDonationDate: Timestamp.fromMillis(lastDonation.toMillis() - 40 * DAY), updatedAt: serverTimestamp(),
      }));
    });

    test('it may move later, and a few hours earlier (a phone\'s midnight is not Phnom Penh\'s)', async () => {
      await edit();
      await assertSucceeds(updateDoc(doc(as('u1'), 'donors/u1'), {
        lastDonationDate: Timestamp.fromMillis(lastDonation.toMillis() - 7 * 3_600_000), updatedAt: serverTimestamp(),
      }));
      await assertSucceeds(updateDoc(doc(as('u1'), 'donors/u1'), {
        lastDonationDate: Timestamp.fromMillis(Date.now() - DAY), updatedAt: serverTimestamp(),
      }));
    });

    test('sex, once given, stays — F to M would shorten the interval', async () => {
      await edit();
      await assertFails(updateDoc(doc(as('u1'), 'donors/u1'), { sex: 'M', updatedAt: serverTimestamp() }));
      await assertFails(updateDoc(doc(as('u1'), 'donors/u1'), { sex: null, updatedAt: serverTimestamp() }));
    });

    test('a profile with no sex yet may give one', async () => {
      await seed((db) => setDoc(doc(db, 'donors/u1'), stored({ sex: null })));
      await assertSucceeds(updateDoc(doc(as('u1'), 'donors/u1'), { sex: 'M', updatedAt: serverTimestamp() }));
    });
  });

  test('nobody but the donor and an admin reads a profile — not staff, not a requester', async () => {
    await seed((db) => setDoc(doc(db, 'donors/u1'), donor()));
    await assertSucceeds(getDoc(doc(as('u1'), 'donors/u1')));
    await assertFails(getDoc(doc(as('u2'), 'donors/u1')));
    await assertFails(getDoc(doc(hospitalClaim(), 'donors/u1')));
    await assertFails(getDoc(doc(anon(), 'donors/u1')));
    await assertSucceeds(getDoc(doc(admin(), 'donors/u1')));
  });
});

describe('requests', () => {
  // ADR 0010: posting is the portal's createRequest. No client writes a request, however
  // well-formed — the shape check, the rate limit and the hospital stamp all live there.
  test('no client posts a request, not even a valid one in a batch with its contact', async () => {
    const db = as('req-1');
    const batch = writeBatch(db);
    batch.set(doc(db, 'requests/r1'), newRequest('req-1'));
    batch.set(doc(db, 'requests/r1/private/contact'), contact);
    await assertFails(batch.commit());
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1'), newRequest('req-1')));
    await assertFails(setDoc(doc(admin(), 'requests/r1'), newRequest('admin-1')));
    await assertFails(setDoc(doc(anon(), 'requests/r1'), newRequest('req-1')));
  });

  test('no client writes a contact — not the creator, not an intruder', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    await assertFails(setDoc(doc(as('req-1'), 'requests/r1/private/contact'), contact));
    await assertFails(setDoc(doc(as('intruder'), 'requests/r1/private/contact'), contact));
  });

  test('the public board reads requests signed out (DEC-009)', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1', { status: 'OPEN' })));
    await assertSucceeds(getDoc(doc(anon(), 'requests/r1')));
    await assertSucceeds(getDoc(doc(anon(), 'requests/r1/acceptedDonors/d1')));
  });

  test('the creator cancels an open request and changes nothing else', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1', { status: 'OPEN' })));
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

  test('a pending or rejected request is not on the public board — only its creator and the admin see it (DEC-015)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'requests/r1'), newRequest('req-1'));
      await setDoc(doc(db, 'requests/r2'), newRequest('req-1', { status: 'REJECTED' }));
    });
    for (const id of ['r1', 'r2']) {
      await assertFails(getDoc(doc(anon(), `requests/${id}`)));
      await assertFails(getDoc(doc(as('d1'), `requests/${id}`)));
      await assertSucceeds(getDoc(doc(as('req-1'), `requests/${id}`)));
      await assertSucceeds(getDoc(doc(admin(), `requests/${id}`)));
    }
  });

  test('the board\'s query asks for OPEN, so the rules can answer it signed out', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1', { status: 'OPEN' })));
    await assertSucceeds(getDocs(query(collection(anon(), 'requests'), where('status', '==', 'OPEN'))));
    await assertFails(getDocs(collection(anon(), 'requests')));
    await assertSucceeds(getDocs(query(collection(as('req-1'), 'requests'), where('createdBy', '==', 'req-1'))));
    await assertSucceeds(getDocs(query(collection(admin(), 'requests'), where('status', '==', 'PENDING'))));
  });

  test('the creator cancels a pending request, but cannot approve or reject it', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1')));
    const db = as('req-1');
    await assertFails(updateDoc(doc(db, 'requests/r1'), { status: 'OPEN', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'requests/r1'), { status: 'REJECTED', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(admin(), 'requests/r1'), { status: 'OPEN', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, 'requests/r1'), { status: 'CANCELLED', updatedAt: serverTimestamp() }));
  });

  test('a rejected request stays rejected', async () => {
    await seed((db) => setDoc(doc(db, 'requests/r1'), newRequest('req-1', { status: 'REJECTED' })));
    await assertFails(updateDoc(doc(as('req-1'), 'requests/r1'), { status: 'CANCELLED', updatedAt: serverTimestamp() }));
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

  // SEC-REVIEW-003 F-19.
  test('an accepted donor keeps it while the request is open or just filled, not after it closes', async () => {
    for (const [status, readable] of [['FULFILLED', true], ['CANCELLED', false], ['EXPIRED', false]]) {
      await env.clearFirestore();
      await seedRequestWithMatch('req-1', 'd1', { status, response: 'ACCEPTED' });
      const read = getDoc(doc(as('d1'), 'requests/r1/private/contact'));
      await (readable ? assertSucceeds(read) : assertFails(read));
      await assertSucceeds(getDoc(doc(as('req-1'), 'requests/r1/private/contact')));
    }
  });

  test('staff, strangers and the signed-out board do not', async () => {
    await seedRequestWithMatch('req-1', 'd1', { response: 'ACCEPTED' });
    await assertFails(getDoc(doc(hospitalClaim(), 'requests/r1/private/contact')));
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

  test('a HOSPITAL claim reads no match — v1 has no hospital staff', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(getDoc(doc(hospitalClaim(HOSPITAL), 'matches/r1_d1')));
    await assertSucceeds(getDoc(doc(admin(), 'matches/r1_d1')));
    await assertFails(getDoc(doc(as('staff-no-claim', { hospitalId: HOSPITAL }), 'matches/r1_d1')));
  });

  // ADR 0010: the answer is the portal's respondToMatch, which enforces one answer, only
  // ACCEPTED or DECLINED, only by the match's donor, only while the request is OPEN. The rule
  // that did that is gone, so every client update is refused — including a correct one.
  test('no client answers a match, not even its donor with a correct answer', async () => {
    await seedRequestWithMatch('req-1', 'd1');
    await assertFails(updateDoc(doc(as('d1'), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('d2'), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(admin(), 'matches/r1_d1'),
      { response: 'ACCEPTED', respondedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(as('d1'), 'matches/r1_d1')));
  });
});

describe('donations', () => {
  beforeEach(() => seed((db) => setDoc(doc(db, 'donations/x1'), {
    donorUid: 'd1', hospitalId: HOSPITAL, requestId: 'r1', donatedOn: Timestamp.now(), confirmedBy: 'staff-1',
  })));

  test('the donor and an admin read it', async () => {
    await assertSucceeds(getDoc(doc(as('d1'), 'donations/x1')));
    await assertSucceeds(getDoc(doc(admin(), 'donations/x1')));
  });

  test('another donor and another hospital do not', async () => {
    await assertFails(getDoc(doc(as('d2'), 'donations/x1')));
    await assertFails(getDoc(doc(hospitalClaim(HOSPITAL), 'donations/x1')));
  });

  test('no client records a donation — not even the donor or an admin', async () => {
    const donation = { donorUid: 'd1', hospitalId: HOSPITAL, donatedOn: Timestamp.now() };
    await assertFails(setDoc(doc(as('d1'), 'donations/x2'), donation));
    await assertFails(setDoc(doc(admin(), 'donations/x2'), donation));
  });
});

describe('admins', () => {
  test('an admin reads their own record, and nobody else reads any', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'admins/admin-1')));
    await assertFails(getDocs(collection(admin(), 'admins')));
    await assertFails(getDoc(doc(as('d1'), 'admins/admin-1')));
    await assertFails(getDoc(doc(anon(), 'admins/admin-1')));
  });

  test('no client writes it — a record is how a claim becomes access', async () => {
    await assertFails(setDoc(doc(as('d1'), 'admins/d1'), { displayName: 'Me' }));
    await assertFails(setDoc(doc(admin(), 'admins/d1'), { displayName: 'Friend' }));
  });

  test('an ADMIN claim with no record is no access: a revoke takes effect before the token expires', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users/d1'), { language: 'en', role: 'DONOR' });
      await setDoc(doc(db, 'donations/x1'), {
        donorUid: 'd1', hospitalId: HOSPITAL, requestId: 'r1', donatedOn: Timestamp.now(), confirmedBy: 'admin-1',
      });
    });
    await assertSucceeds(getDoc(doc(admin(), 'users/d1')));
    await seed((db) => deleteDoc(doc(db, 'admins/admin-1')));
    await assertFails(getDoc(doc(admin(), 'users/d1')));
    await assertFails(getDoc(doc(admin(), 'donations/x1')));
  });

  test('a record with no claim is no access either', async () => {
    await seed((db) => setDoc(doc(db, 'users/d1'), { language: 'en', role: 'DONOR' }));
    await assertFails(getDoc(doc(as('admin-1'), 'users/d1')));
  });

  test('the portal\'s query: an admin lists one request\'s donations', async () => {
    await seed((db) => setDoc(doc(db, 'donations/x1'), {
      donorUid: 'd1', hospitalId: HOSPITAL, requestId: 'r1', donatedOn: Timestamp.now(), confirmedBy: 'admin-1',
    }));
    await assertSucceeds(getDocs(query(collection(admin(), 'donations'), where('requestId', '==', 'r1'))));
    await assertFails(getDocs(query(collection(hospitalClaim(), 'donations'), where('requestId', '==', 'r1'))));
  });
});

describe('config/app — the release channel for the sideloaded APK', () => {
  test('anyone reads it, signed in or not — the update check runs before sign-in', async () => {
    await seed((db) => setDoc(doc(db, 'config/app'), { minVersionCode: 1, latestVersionCode: 2 }));
    await assertSucceeds(getDoc(doc(anon(), 'config/app')));
    await assertSucceeds(getDoc(doc(as('d1'), 'config/app')));
  });

  test('nobody writes it — not a user, not the admin; a forged minVersionCode would lock everyone out', async () => {
    await assertFails(setDoc(doc(as('d1'), 'config/app'), { minVersionCode: 999 }));
    await assertFails(setDoc(doc(admin(), 'config/app'), { minVersionCode: 999 }));
    await assertFails(setDoc(doc(anon(), 'config/other'), { x: 1 }));
  });
});

describe('reports (DEC-019)', () => {
  const report = (uid, extra = {}) => ({
    requestId: 'r1',
    reporterUid: uid,
    reason: 'MONEY',
    note: 'Asked me for $50',
    createdAt: serverTimestamp(),
    ...extra,
  });

  test('an alerted donor reports the request once; only the admin reads it', async () => {
    await seedRequestWithMatch('family', 'd1');
    await assertSucceeds(setDoc(doc(as('d1'), 'reports/r1_d1'), report('d1')));
    // A second report is an update of the same id, and is refused.
    await assertFails(setDoc(doc(as('d1'), 'reports/r1_d1'), report('d1', { reason: 'FAKE' })));
    await assertFails(getDoc(doc(as('d1'), 'reports/r1_d1')));
    await assertFails(getDoc(doc(as('family'), 'reports/r1_d1')));
    await assertSucceeds(getDoc(doc(admin(), 'reports/r1_d1')));
  });

  test('nobody reports a request they were not alerted to, or as someone else', async () => {
    await seedRequestWithMatch('family', 'd1');
    await assertFails(setDoc(doc(as('d2'), 'reports/r1_d2'), report('d2')));
    await assertFails(setDoc(doc(as('d2'), 'reports/r1_d1'), report('d1')));
    await assertFails(setDoc(doc(anon(), 'reports/r1_d1'), report('d1')));
  });

  test('only the known reasons, and a note of at most 500 characters', async () => {
    await seedRequestWithMatch('family', 'd1');
    await assertFails(setDoc(doc(as('d1'), 'reports/r1_d1'), report('d1', { reason: 'SPAM' })));
    await assertFails(setDoc(doc(as('d1'), 'reports/r1_d1'), report('d1', { note: 'x'.repeat(501) })));
    await assertSucceeds(setDoc(doc(as('d1'), 'reports/r1_d1'), report('d1', { note: null })));
  });
});

