---
id: SEC-REVIEW-003
feature: ADR-0009 + ADR-0010 (Firebase stack, portal functions) — all shipped FRs
date: 2026-09-29
verdict: fail
reviewer: Security (Tech Lead overlay)
standard: OWASP ASVS 5.0.0, Level 1 (../asvs-baseline.md)
---

## Scope reviewed

The first security review of the stack as it runs today. `SEC-REVIEW-001`/`002` reviewed Spring
Boot sign-in, which ADR 0009 removed. Reviewed at commit `a393714` on `feat/firebase-backend`:

- **Rules:** `firebase/firestore.rules`, `firebase/rules-tests/firestore.rules.test.js`
- **Functions:** `frontend/src/server/*`, `frontend/src/app/api/functions/[name]/route.ts`
- **Portal:** `frontend/src/app/[locale]/sign-in/*`, `frontend/src/lib/api/{session,portal-auth}.ts`,
  `next.config.ts`, `vercel.json`, dependencies (`npm audit --omit=dev`)
- **App:** `mobile/lib/` auth, sign-out, account deletion, local storage, network config, links
- **Production, from outside:** `curl` against `https://lifelinkkh.vercel.app` (headers, `.git`,
  the functions route)

Method: each ASVS 5.0.0 Level 1 requirement (70) checked against code with a `file:line`; the
two most severe findings reproduced by hand. Nothing was fixed in this review.

**Out of scope:** the uncommitted DEC-019 `reports/` collection in the working tree (not yet
committed; review it when it lands). The Firebase console configuration (Auth providers,
authorised domains, API-key restrictions) was not inspected.

## Findings

Severity is the harm if exploited today, not the effort to fix. Evidence is `file:line` at `a393714`.

### High

**F-01 · Function dispatch accepts `Object.prototype` names, unauthenticated.**
`frontend/src/server/invoke.ts:23` looks the name up as `FUNCTIONS[name]` on a plain object
(`functions.js:27`). `POST /api/functions/constructor` passes the `!handler` check and calls
`Object(ctx)`, which returns the context — `db`, `auth`, `messaging` and the Admin app that holds
the service-account credential. Today the only thing keeping it out of the response is that the
context is circular and `NextResponse.json` throws (`route.ts:48`, outside any `try`): a 500.
`toString` returns `200 {"result":"[object Undefined]"}`. No token is needed.
Reproduced locally 2026-09-29: `constructor` → 500, `toString` → 200, `hasOwnProperty` → 500.
ASVS 1.3.2, 4.1.1. **Fix:** `Object.hasOwn(FUNCTIONS, name)` before the lookup (or a `Map`), plus a
unit test that `constructor`, `toString` and `__proto__` answer `NOT_FOUND`.

**F-02 · `next` 15.5.23 has a critical advisory.** `frontend/package.json:21`. `npm audit --omit=dev`:
1 critical (`next`, GHSA-2xp9-vwfh-vxw4, Image Optimization RCE, fixed in 15.5.24), 2 high
(`postcss`, `sharp`), 2 moderate (`uuid` via `firebase-admin`). ASVS 15.2.1. **Fix:** `next` →
15.5.26 (patch release), `npm audit fix`, re-run the portal tests and the build.

**F-03 · The functions route is broken in production.** On `lifelinkkh.vercel.app`, every request
to `/api/functions/*` — including `GET`, which the code answers with a JSON 405 before touching
Firebase — returns Next's HTML 500 page with `Access-Control-Allow-Origin: *`. Locally the same
route returns the JSON protocol (401, 400). The production deployment is not serving the code at
`2f77e93` the way the dev server does. Effect: in production the app cannot post a request, answer
an alert or delete an account, and the one deletion path Google Play requires is down. Not an
exploit, but an availability and 4.1.1/3.4.2 failure. **Fix (Tech Lead):** read the Vercel runtime
log for `/api/functions/createRequest`; check `FIREBASE_SERVICE_ACCOUNT` is set on Production and
the project root is `frontend`; redeploy and expect `GET` → JSON 405.

### Medium

**F-04 · A donor can erase their own cooldown.** `firebase/firestore.rules:67-68, 79-80` let a
donor set `lastDonationDate` to null or any earlier date, and change `sex` F→M (120 → 90 days),
after `confirmDonation` has written them. Matching reads both (`frontend/src/server/matching.js:111-112`),
so an ineligible donor is alerted. ASVS 2.3.1. **Fix:** once set, `lastDonationDate` may only move
later (or only the server writes it); `sex` fixed once set; a rules test for each.

**F-05 · Sessions outlive logout and deletion.** Portal `signOutAction` only deletes the cookie
(`frontend/src/app/[locale]/sign-in/actions.ts:117-125`); `invoke.ts:55` calls
`verifyIdToken(token)` without `checkRevoked`. A copied token keeps working up to 1 hour — including
after `deleteAccount` (`delete-account.js:96`), where `createRequest` would still write a request
under the deleted uid. ASVS 7.4.1, 7.4.2. **Fix:** `verifyIdToken(token, true)`;
`revokeRefreshTokens(uid)` on portal sign-out; `createRequest` refuses a caller with no `users/{uid}`.

**F-06 · No CSP, anti-framing or `nosniff` header.** `frontend/next.config.ts:4-20`, `vercel.json`.
The sign-in page can be framed. ASVS 3.2.1. **Fix:** `headers()` in `next.config.ts` with
`Content-Security-Policy` (`frame-ancestors 'none'`, script-src allowing `accounts.google.com`),
`X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`.

**F-07 · App data survives sign-out and account deletion.** `mobile/lib/src/features/auth/application/auth_service.dart:136-146`,
`account/application/account_deletion_service.dart:100-110`, `core/database/app_database.dart:56-58`.
Drift tables (`requestMatchRows`, `pendingSync`) and the Firestore offline cache stay. On a shared
phone the next user inherits answers, cached requester contact phones, and a write queue that
could replay under the new account. ASVS 14.3.1. **Fix:** clear both tables, then
`FirebaseFirestore.instance.terminate()` + `clearPersistence()`, on both paths.

**F-08 · Brute-force and anti-automation are not designed, only inherited.** Portal password sign-in
relies on Firebase's per-account lockout (`sign-in/actions.ts:82`, `portal-auth.ts:36-38`); nothing
slows spraying one password across usernames. Only `createRequest` is rate-limited
(`create-request.js:49-63`, 5 per 10 min). None of it is documented. ASVS 6.1.1, 6.3.1. **Fix:**
set `PORTAL_PASSWORD_SIGN_IN=off` in production (Google only, `sign-in-options.ts:6-8`) — that
removes the password surface — and write the limits into `security-checklist.md`.

**F-09 · No dependency update policy.** No document sets remediation time frames; F-02 is what that
looks like. ASVS 15.1.1. **Fix:** one paragraph in `security-checklist.md`: critical ≤ 7 days,
high ≤ 30 days; `npm audit --omit=dev` and `flutter pub outdated` at every milestone; Dependabot
on `frontend/` and `firebase/`.

### Low

- **F-10** Doc ids from input unchecked for `/` (`respond-to-match.js:34`, `create-request.js:43`,
  `review-request.js:40`, `confirm-donation.js:63-64`). `matchId: "a/b"` → generic 500. 1.2.4.
  Fix: reject ids not matching `^[A-Za-z0-9_-]{1,128}$`.
- **F-11** Data minimisation (15.3.1): admin reads donor `lat`/`lng`/`geohash` (`firestore.rules:76`,
  test `:199` asserts it), which ADR 0003 forbids; `acceptedDonors` is public and keyed by donor uid
  (`:123`, `respond-to-match.js:120-126`); public requests carry `createdBy` (`create-request.js:68`).
  Fix: drop `|| isAdmin()` from donor reads or amend ADR 0003; random ids for `acceptedDonors`.
- **F-12** `districtCode` has no length cap (`firestore.rules:65`); geohash accepted to 12 chars
  (`:53`, centimetres) against ADR 0003's ~1 m. 2.2.1. Fix: `size() <= 8` for both.
- **F-13** Session cookie `lifelink_portal_session` has no `__Host-` prefix (`sign-in/actions.ts:87`).
  3.3.1. Fix: rename to `__Host-lifelink_portal_session` in production.
- **F-14** No breached-password check; change-password minimum is 8 while the seed requires 12
  (`password/actions.ts:31`, `firebase/seed/admin.mjs:88`). 6.2.4. Fix: 12 minimum everywhere and a
  bundled top-10k list — or F-08's Google-only makes this moot.
- **F-15** App accepts `http://` for `PORTAL_URL` and web links in release (`core/config/env.dart:35-41`,
  `update/domain/app_config.dart:108`). 12.2.1. Fix: https only unless `kDebugMode`.
- **F-16** Seed's default admin username `soborey` (`firebase/seed/admin.mjs:72`). 6.3.2. Fix:
  require `PORTAL_ADMIN_USERNAME` against the real project.
- **F-17** Donor name in the `?confirmed=` redirect (`frontend/src/app/[locale]/portal/actions.ts:42`)
  lands in history and Vercel logs. 14.2.1. Fix: pass the match id, look the name up server-side.
- **F-18** No rules test for `update` of another uid's `users`/`donors` doc, nor stranger list
  queries on `donors`/`users`/`matches`/`donations`. Fix: add them to `rules-tests/`.
- **F-19** An accepted donor keeps reading the requester's contact after the request closes
  (`firestore.rules:89-92`). Fix: also require the request to be OPEN.
- **F-20** App `debugPrint`s uncaught errors in release (`core/error/crash_handling.dart:27`); FCM token
  not deleted on the device at sign-out (`notify/data/firestore_fcm_token_repository.dart:66`).
  Fix: `if (kDebugMode)`; `FirebaseMessaging.instance.deleteToken()` after the Firestore clear.
- **F-21** No request-body size cap (`route.ts:38`); PUT/DELETE get Next's default 405, not the error
  shape; JSON without `charset`. Fix: 413 over 16 KB; export the other methods; set the header.

### What holds

Authorization is the strong part. ADMIN needs the claim **and** an `admins/{uid}` record, and both
halves are tested (`rules-tests/…:391-407`). Every privileged write is `if false` in the rules and
done by the Admin SDK (`firestore.rules:103,117,132-135,142`). The requester-contact rule is
tested from six angles (`:286-316`). The server functions enforce the request lifecycle inside
transactions (approve twice, answer after close, confirm an unaccepted match — all refused). ID
tokens are verified with the Admin SDK (RS256, Google keys, `exp`). The service-account JSON is
`server-only`, never `NEXT_PUBLIC_`, never in git. HSTS is two years in production.

## Verdict & conditions

**Fail.** ASVS Level 1 is not met: 5 requirements fail and 17 are partial
(`../asvs-baseline.md`). Before the next production deploy, or any real donor:

1. **F-01** and **F-02** fixed, with the unit test for F-01. Both are small.
2. **F-03** — production functions answer the JSON protocol (`GET` → 405 JSON).
3. **F-04**, **F-05** fixed with tests; **F-08** by setting `PORTAL_PASSWORD_SIGN_IN=off`.
4. A Tech Lead ruling, recorded in an ADR, on ADR 0005's Level 2 trigger (see the baseline).

F-06, F-07 and F-09 before the first public APK. The Lows are backlog, tracked here.
A follow-up `SEC-REVIEW-004` re-checks the conditions; this file is not edited to say they pass.
