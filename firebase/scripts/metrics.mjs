// LifeLink KH — the five PRD success metrics, straight out of Firestore (ADR 0009, phase 6).
// The port of scripts/metrics.sql: DEC-004 cut per-milestone event instrumentation and
// promised these numbers would come from the data at demo time instead. Targets are
// docs/po/prd.md section 1 ("Success Metrics").
//
//   npm run metrics                             # the emulator, project lifelinkkh
//   npm run metrics -- --project lifelinkkh     # the REAL project (GOOGLE_APPLICATION_CREDENTIALS)
//
// Read the `sample` column before quoting any percentage out loud. Three requests where two were
// accepted inside an hour is 67%, and it means nothing. The honest sentence at a defense is "the
// query is real, the pilot data is not yet".
//
// Reads every request, match and donation once. Fine for a pilot; not for a national rollout.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectFlag = process.argv.indexOf('--project');
const real = projectFlag > -1;
const projectId = real ? process.argv[projectFlag + 1] : 'lifelinkkh';
if (!real) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
if (real && process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(`FIRESTORE_EMULATOR_HOST is set, so "${projectId}" would silently mean the emulator. Unset it.`);
  process.exit(1);
}
initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
const db = getFirestore();

const [donors, requests, matches, donations] = await Promise.all(
  ['donors', 'requests', 'matches', 'donations'].map((c) => db.collection(c).get()),
);
const ms = (t) => (t ? t.toMillis() : null);
const MONTH = 30 * 24 * 3600_000;
const pct = (a, b) => (b === 0 ? null : `${((100 * a) / b).toFixed(1)}%`);

// 1. Donors. Every district is a Phnom Penh khan, so a donor row IS a Phnom Penh donor.
const donorTimes = donors.docs.map((d) => ms(d.get('createdAt'))).filter((t) => t != null).sort((a, b) => a - b);
const firstSeen = donorTimes[0] ?? null;
const firstMonth = firstSeen == null ? 0 : donorTimes.filter((t) => t < firstSeen + MONTH).length;

// 2 and 3. First acceptance per live request. CANCELLED and EXPIRED are excluded: the metric asks
// how often a live need reaches a donor, and a withdrawn request was never waiting for one.
// REJECTED is excluded for the same reason (DEC-015): the admin judged it not a real need. PENDING
// stays in — a real need still waiting for review is exactly the delay this metric should show.
const firstAccepted = new Map();
for (const m of matches.docs) {
  if (m.get('response') !== 'ACCEPTED') continue;
  const at = ms(m.get('respondedAt'));
  const id = m.get('requestId');
  if (at != null && (!firstAccepted.has(id) || at < firstAccepted.get(id))) firstAccepted.set(id, at);
}
const live = requests.docs.filter((r) => !['CANCELLED', 'EXPIRED', 'REJECTED'].includes(r.get('status')));
const excluded = requests.size - live.length;
const waits = live
  .filter((r) => firstAccepted.has(r.id) && ms(r.get('createdAt')) != null)
  .map((r) => (firstAccepted.get(r.id) - ms(r.get('createdAt'))) / 60_000)
  .sort((a, b) => a - b);
const withinHour = waits.filter((w) => w <= 60).length;
const median = waits.length === 0 ? null
  : waits.length % 2 ? waits[(waits.length - 1) / 2]
  : (waits[waits.length / 2 - 1] + waits[waits.length / 2]) / 2;

// 6. DEC-015: how long a request waits for the admin. Not a PRD target — the operational cost of
// reviewing every request, which metric 2 already pays for (it is measured from createdAt).
const reviews = requests.docs
  .filter((r) => r.get('reviewedAt') && r.get('createdAt'))
  .map((r) => (ms(r.get('reviewedAt')) - ms(r.get('createdAt'))) / 60_000)
  .sort((a, b) => a - b);
const reviewMedian = reviews.length === 0 ? null
  : reviews.length % 2 ? reviews[(reviews.length - 1) / 2]
  : (reviews[reviews.length / 2 - 1] + reviews[reviews.length / 2]) / 2;
const waiting = requests.docs.filter((r) => r.get('status') === 'PENDING').length;

// 4. Only confirmDonation writes donations, and it always sets confirmedBy — so every row is verified.
const verified = donations.docs.filter((d) => d.get('confirmedBy')).length;

// 5. A match exists for every candidate; notifiedAt only where FCM accepted the send.
const notified = matches.docs.filter((m) => m.get('notifiedAt')).length;

console.table([
  { metric: 'Registered donors (Phnom Penh)', target: '>= 200 in first month',
    actual: `${firstMonth} in first month · ${donors.size} all time`, sample: `${donors.size} donors`,
    note: firstSeen ? `pilot clock starts ${new Date(firstSeen).toISOString().slice(0, 10)}` : 'no donors yet' },
  { metric: 'Requests accepted within 60 min', target: '>= 70%',
    actual: pct(withinHour, live.length) ?? '—', sample: `${withinHour} of ${live.length} requests`,
    note: `${waits.length} accepted at any point · ${excluded} cancelled/expired/rejected excluded` },
  { metric: 'Median time to first acceptance', target: '< 30 minutes',
    actual: median == null ? '—' : `${median.toFixed(1)} min`, sample: `${waits.length} accepted requests`,
    note: 'accepted requests only' },
  { metric: 'Hospital-verified donations', target: '>= 50 in the pilot',
    actual: String(verified), sample: `${verified} of ${donations.size} donations`,
    note: 'confirmed by the portal admin (DEC-014)' },
  { metric: 'Push send-success rate', target: '>= 95%',
    actual: pct(notified, matches.size) ?? '—', sample: `${notified} of ${matches.size} matches`,
    note: 'FCM accepted the send — not proof the device showed it' },
  { metric: 'Median time to review (DEC-015)', target: '— (operational)',
    actual: reviewMedian == null ? '—' : `${reviewMedian.toFixed(1)} min`, sample: `${reviews.length} reviewed requests`,
    note: `${waiting} waiting for review now` },
]);
process.exit(0);
