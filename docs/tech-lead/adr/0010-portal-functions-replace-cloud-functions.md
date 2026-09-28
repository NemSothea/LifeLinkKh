---
id: 0010-portal-functions-replace-cloud-functions
title: The portal's server runs the functions; Cloud Functions and the Blaze plan go
status: accepted
date: 2026-09-29
deciders: Tech Lead
---
## Context

ADR 0009 put the server-side logic — matching, the pushes, the admin's approve and confirm, the
app's delete-account — in six Cloud Functions on `lifelinkkh`. Cloud Functions need the **Blaze**
(pay-as-you-go) plan, which needs a card on the project. Putting one there cost a $50 hold and a
day of the Tech Lead's time, and the team decided on 2026-09-27 that a free, non-profit class
project keeps no card on file at all ([`lifelink-cost-free-until-500`]). The free **Spark** plan
has Firestore, Auth and FCM, but no Functions.

The portal already runs on **Vercel's free Hobby plan**, in Singapore (`sin1`), as a Node server
that talks to Firestore. The six handlers were ~900 lines of plain Node with `firebase-admin`,
written as functions of `(db, messaging, caller, data)` so the tests could call them without
deploying — which means they can run anywhere Node runs.

Two things made Cloud Functions more than a place to run code: **Firestore triggers**
(`onRequestCreated`, `onRequestApproved`, `onMatchAnswered` ran after a client write, with nothing
for the client to call) and **`onCall`** (the caller's ID token verified before the handler ran).
Neither exists on a plain Node server; both had to be replaced, not just moved.

## Decision

The six handlers move, unchanged in what they do, into the portal: `frontend/src/server/`.
`firebase/functions/` is deleted. `lifelinkkh` goes to the Spark plan.

- **Address.** `POST /api/functions/{name}` on the portal, speaking the callable protocol the
  Cloud Functions spoke (`{data}` in with the Firebase ID token as the bearer, `{result}` out,
  `{error: {status, message, details}}` with the matching HTTP status). The app's
  `cloud_functions` plugin needs only a URL (`httpsCallableFromUrl`), so its authentication and
  error handling did not change. `PORTAL_URL` (`--dart-define`) is the address; the deployed
  portal by default, a local `next dev` for a demo.
- **Verification.** `invoke.ts` verifies the token with the Admin SDK before a handler runs — what
  `onCall` did. The portal's own Server Actions call `invoke` in-process with the admin's session
  cookie as the token; nothing goes over HTTP to itself.
- **Triggers become calls.** A client no longer writes, then waits for a trigger; it calls, and
  the handler writes:
  - `createRequest` replaces the app's own write of `requests/{id}` + `private/contact` and
    `onRequestCreated`. The shape check the rules made, the rate limit and the hospital stamp
    run **before** the write. Over the limit is now refused (`RATE_LIMITED`), not written and closed.
  - `respondToMatch` replaces the app's own update of `matches/{id}` and `onMatchAnswered`. The
    rule's conditions (the match's own donor, one answer, only while OPEN) are the handler's
    refusals (`ALREADY_RESPONDED`, `REQUEST_NOT_OPEN`); the same answer twice is a replay, not a
    refusal, because the offline queue can deliver it twice.
  - `reviewRequest` on APPROVE runs `handleRequestApproved` itself, where `onRequestApproved`
    used to fire on the PENDING → OPEN update. `matchedAt` is still claimed in a transaction, so
    a retried or racing approval alerts nobody twice. A matching failure after the status flipped
    is logged and reported (`alerted: null`), never thrown: the admin's decision stands.
- **The rules close what the handlers took over.** `requests` create, `private/contact` create
  and `matches` update are `if false` for every client. The rules tests assert the refusals.
- **The credential.** The portal now holds one: `FIREBASE_SERVICE_ACCOUNT` on Vercel, the
  service-account JSON as one environment variable, read only in `src/server/firebase-admin.ts`.
  Every page and Server Action still reads Firestore as the signed-in admin through `client.ts`
  with no credential; the Admin SDK is used by the handlers alone. Locally against the emulators
  no credential is needed.
- **Pushes.** `firebase-admin/messaging` from the portal's server, with the service account. On a
  `demo-` project, and on the emulators without a credential, every message is written to
  `_outbox` instead, as before.
- **Scripts that called the handlers** (`seed/demo.mjs`, `scripts/delete-account.mjs`) import
  them from `frontend/src/server/` — and import `firebase-admin` through `admin-sdk.js` there,
  so both sides share one copy (a `FieldValue` from a second copy is not serialisable by the first).
- **Tests.** `frontend/test/server/unit` (pure) and `frontend/test/server/emulator` (Firestore +
  Auth emulators), run by `npm run test:server` and `npm run test:server:emulator` from
  `frontend/`. CI's `firebase` job runs them, because it is the job with Java.

## Consequences

- **$0 with no card.** Firestore, Auth and FCM on Spark; the server on Vercel Hobby. The 500-user
  decision ([`lifelink-cost-free-until-500`]) is unchanged.
- **The portal is on the critical path of the app.** Before, a donor's Accept was a Firestore write
  that worked with the portal down. Now `createRequest`, `respondToMatch` and `deleteAccount` need
  the portal up. Vercel Hobby has no SLA; a cold start adds about a second to the first call. The
  offline-first queue covers a portal that is briefly unreachable for an answer (it is
  `NetworkFailure`, queued and retried), and a request that cannot be posted says so.
- **Vercel's limits apply to matching.** A Hobby function has 10 s (configurable to 60 s) and one
  region. Matching reads at most a few hundred donors and pushes at most 25; measured well under
  a second on the emulator. A city-wide donor base is the point at which this is revisited —
  together with the 500-user decision.
- **One credential on a third party.** The service-account key on Vercel can do anything to the
  project. It is set as an environment variable (never in the repo, never `NEXT_PUBLIC_`), the
  Vercel project is the Tech Lead's account only, and rotating it is a console action plus one
  variable change. ASVS-wise this is the same posture as the seed scripts already had on a
  developer machine.
- **The app cannot post or answer with an old portal.** The rules refuse the writes an APK built
  before this ADR makes. The sideloaded APK's update check (`config/app`, `minVersionCode`) is the
  tool for that: the first release after this ADR moves `--min`.
- **Tests moved, not lost.** Every handler test runs as before; the rules tests that asserted
  client writes now assert refusals; the app's repository tests fake the portal.
- ADR 0009 stands for everything else — Firestore, Auth, the data model, the rules, the portal's
  REST reads. `CLAUDE.md`'s "Firestore + Security Rules + Cloud Functions" reads "+ the portal's
  functions" from here on.

## Alternatives considered

- **Stay on Blaze with a $1 alert.** Rejected on 2026-09-27: the card is the problem, not the
  bill. A class project with a card on file is one loop away from a charge nobody meant.
- **GitHub Actions on a schedule as the "trigger".** Cron runs at best every 5 minutes and often
  late. An urgent-blood alert that arrives twenty minutes after the admin's click is not the
  product.
- **Firebase App Hosting.** Bills through Cloud Run and Cloud Build — a card again.
- **Keep the app's direct Firestore writes and have the portal poll for new ones.** Polling from a
  serverless host is a scheduled function, which Vercel Hobby limits to daily. Same problem as cron.
- **A separate Node service (Render, Fly, a VPS).** Another thing to run, secure and pay for; the
  portal is already a Node server in the right region with the team's attention on it.
