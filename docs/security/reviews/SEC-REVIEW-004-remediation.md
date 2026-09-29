---
id: SEC-REVIEW-004
feature: SEC-REVIEW-003 remediation (Firebase stack, portal functions, app)
date: 2026-09-29
verdict: pass-with-conditions
reviewer: Security (Tech Lead overlay)
standard: OWASP ASVS 5.0.0, Level 1 (../asvs-baseline.md)
follows: SEC-REVIEW-003-firebase-stack.md
---

## Scope reviewed

The fixes for the 21 findings of `SEC-REVIEW-003`, on `feat/firebase-backend` from `c0a916b` to
`add3292`. `SEC-REVIEW-003` is not edited; this file records what changed and what is left.

Evidence run on 2026-09-29, from this machine:

| Suite | Command | Result |
|---|---|---|
| Firestore rules | `firebase emulators:exec … "vitest run rules-tests"` | 55 passed; the 4 new tests fail against the previous rules |
| Portal functions | `firebase emulators:exec --only firestore,auth … vitest -c vitest.server.config.ts test/server` | 111 passed |
| Portal | `npm test` (frontend) | 74 passed |
| Portal build | `next build` (Next 15.5.26) | compiled |
| App | `flutter analyze`; `flutter test --exclude-tags golden` | no issues; 315 passed |
| Dev server | `curl` against `localhost:3000` | `constructor` / `toString` / `__proto__` → 404 `NOT_FOUND`; CSP, `X-Frame-Options`, `nosniff` present |

The emulator suites ran on their own ports (18081/19099) so the running demo data was not
touched.

## Findings — status

| # | Finding | Status | Commit |
|---|---|---|---|
| F-01 | Dispatch accepted `Object.prototype` names | **Fixed.** Own properties only (`functionNamed`); unit test | `c0a916b` |
| F-02 | `next` 15.5.23 critical advisory | **Fixed.** 15.5.26. Left: postcss (high, bundled in Next, fix is Next 16) and uuid (moderate, via firebase-admin, unused path) | `2a7f949` |
| F-03 | Production functions route returns HTML 500 | **Open — Tech Lead, on Vercel.** Not a code defect: the route answers JSON locally | — |
| F-04 | Donor could reset their cooldown | **Fixed.** `lastDonationDate` only moves later (1 day slack); `sex` fixed once given | `21f71d1` |
| F-05 | Sessions outlived logout and deletion | **Fixed** for the functions: `checkRevoked`, sign-out revokes refresh tokens, `createRequest` needs `users/{uid}`. Residual below | `a29f2e9` |
| F-06 | No CSP / anti-framing / nosniff | **Fixed.** `frame-ancestors 'none'`, `object-src 'none'`, `base-uri`, `form-action`, XFO, nosniff, Referrer- and Permissions-Policy. No script-src yet | `1f0f501` |
| F-07 | App data survived sign-out | **Fixed.** Drift tables, sync queue, Firestore cache, FCM token wiped on sign-out and deletion | `4c4d5e1` |
| F-08 | Brute force only per account | **Fixed.** 10 failures / 15 min per IP (hashed, in Firestore), on top of Firebase's lockout | `add3292` |
| F-09 | No dependency policy | **Fixed.** Critical 7 days, high 30 (`security-checklist.md`); `dependabot.yml` — active once on `main` | `add3292` |
| F-10 | Doc ids from input unchecked | **Fixed.** `^[A-Za-z0-9_-]{1,128}$` (`ids.js`) | `a29f2e9` |
| F-11 | Admin reads donor coordinates; board keyed by uid | **Fixed.** Portal masks donor fields; board rows keyed by `boardId`. ADR 0003 amended. `createdBy` on public requests kept, reason in the commit | `3cb34c2` |
| F-12 | `districtCode` / geohash length | **Fixed.** ≤ 16 / ≤ 10 | `21f71d1` |
| F-13 | Cookie without `__Host-` | **Fixed** in production | `a29f2e9` |
| F-14 | No breached-password check; 8-char minimum | **Fixed.** 12 characters; top 3000 of that length refused, portal and seed | `1f0f501` |
| F-15 | App accepted `http://` in release | **Fixed.** https only unless `kDebugMode` | `4c4d5e1` |
| F-16 | Default admin username | **Fixed.** Required against the real project | `1f0f501` |
| F-17 | Donor name in `?confirmed=` | **Fixed.** 60-second cookie scoped to the portal page | `1f0f501` |
| F-18 | Missing rules tests | **Fixed.** Update and list as a stranger | `21f71d1` |
| F-19 | Contact readable after close | **Fixed.** Only while OPEN or FULFILLED | `21f71d1` |
| F-20 | Release `debugPrint`; FCM token kept on device | **Fixed** | `4c4d5e1` |
| F-21 | No body cap; bodiless 405; no charset | **Fixed.** 413 over 16 KB; error shape for every method; charset | `a29f2e9` |

## Residual risk, accepted

- **Firestore REST reads after sign-out.** Revocation is not checked by the Security Rules, so a
  copied admin ID token can still *read* until it expires (≤ 1 hour). Writes through the
  functions are refused at once, and removing `admins/{uid}` ends reads at once too. ASVS 7.4.1
  stays Partial. The full fix is Firebase session cookies (`createSessionCookie` /
  `verifySessionCookie(…, true)`), which changes how the portal reads Firestore.
- **CSP without `script-src`.** Needs per-request nonces for Next's inline scripts plus an
  allowance for Google Identity Services. Framing, plugins and form hijack are closed.
- **postcss 8.4.31 inside Next.** Processes only our own CSS at build time. Revisit with Next 16.
- **Admin token outside the portal** can read a donor's coordinates (ADR 0003 amendment).

## Verdict & conditions

**Pass with conditions.** ASVS 5.0.0 Level 1: 49 pass, 3 partial, 0 fail, 18 not applicable
(`../asvs-baseline.md`). None of it is live until the conditions below are met:

1. **Deploy the rules** — the F-04, F-12, F-19 fixes are in `firebase/firestore.rules`, and the
   real project still runs the old ones: `cd firebase && npx firebase deploy --only firestore --project lifelinkkh`.
2. **Push and let Vercel deploy**, then fix **F-03**: `GET /api/functions/createRequest` must
   answer a JSON 405. Admins sign in once more afterwards (the cookie name changed, F-13).
3. **Check on a phone** that sign-out → sign-in works (F-07 terminates Firestore on sign-out).
4. **Release a new APK** for F-07/F-15/F-20 to reach users.
5. Still open from `SEC-REVIEW-003`: a Tech Lead ruling, in an ADR, on ADR 0005's Level 2
   trigger.
