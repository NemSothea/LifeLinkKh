# Security Checklist

> **Rewritten 2026-09-29 for the Firebase stack (ADR 0009, ADR 0010).** The first version was
> written for Spring Boot + PostgreSQL + our own JWT and a Telegram webhook. None of those exist
> any more: no `backend/`, no `SecurityConfig`, no JWT of our own, no Telegram sign-in (dropped
> with ADR 0009). Its reviews stay as history: `SEC-REVIEW-001`, `SEC-REVIEW-002`, `TM-AUTH-001`,
> `TM-AUTH-002`.
>
> The standard behind these boxes is [`asvs-baseline.md`](asvs-baseline.md) (ASVS 5.0.0 Level 1,
> ADR 0005). This file is the working list; a box is ticked only when the review that checked it
> is linked. Reviews: [`SEC-REVIEW-003`](reviews/SEC-REVIEW-003-firebase-stack.md) (**fail**, 21
> findings, numbers in brackets) and [`SEC-REVIEW-004`](reviews/SEC-REVIEW-004-remediation.md)
> (**pass with conditions**, 20 fixed). Code is ticked; what is not yet deployed is listed at
> the end of SEC-REVIEW-004.

## Identity and sessions (Firebase Auth)
- [x] Identity comes only from a verified Firebase ID token: `request.auth.uid` in the rules,
      Admin SDK `verifyIdToken` in the portal functions (`frontend/src/server/invoke.ts`). A
      client-supplied uid is never trusted.
- [x] ADMIN needs the custom claim **and** an `admins/{uid}` record no client can write. Tested.
- [x] Self-service sign-up can produce only `DONOR` or `REQUESTER`. Tested.
- [x] Revoked and deleted accounts are refused by the functions at once: `verifyIdToken(token,
      true)`, and portal sign-out revokes refresh tokens (F-05). Firestore REST reads with a
      copied token still work until it expires (≤ 1 h) — accepted in SEC-REVIEW-004.
- [x] Password sign-in has per-IP throttling — 10 failures per 15 minutes per IP, counted in
      Firestore (`signInThrottle`) — on top of Firebase's per-account lockout, and a password
      policy: 12 characters, not one of the 3000 most common of that length (F-08, F-14).
      `PORTAL_PASSWORD_SIGN_IN=off` (Google only) removes the surface entirely.
- [x] Session cookie is `__Host-` prefixed in production, `Secure`, `HttpOnly`, `SameSite=Lax`
      (F-13).

## Authorization (Firestore Security Rules)
- [x] Every personal document is readable and writable only by its owner (`uid()`), and admin.
- [x] Every write a client must not make is `if false` and done by the portal functions with the
      Admin SDK: request create, `private/contact`, match updates, donations.
- [x] No recursive `{document=**}` match; unmatched paths are denied.
- [x] A donor cannot rewrite `lastDonationDate` or `sex` to dodge the cooldown (F-04).
- [x] Rules tests cover `update` of another uid's doc and stranger list queries (F-18).

## Portal functions (`POST /api/functions/{name}`)
- [x] Only own-property names dispatch — `constructor`, `toString`, `__proto__` answer
      `NOT_FOUND` (F-01).
- [x] Every input is validated on the server: allow-lists, ranges, phone format, date format.
- [x] Lifecycle steps are enforced inside transactions: approve once, answer only while OPEN,
      confirm only an accepted match.
- [x] Doc ids from input match `^[A-Za-z0-9_-]{1,128}$`; body capped at 16 KB (F-10, F-21).
- [x] `createRequest` is rate-limited: 5 per creator per 10 minutes.
- [x] Rate limits, decided (F-08): `createRequest` above; `respondToMatch` needs a match of the
      caller's (one answer each, ever); `deleteAccount` needs a sign-in in the last 5 minutes;
      the admin functions need an admin. Password sign-in: per IP, above. Anything more is a
      Vercel firewall rule, not code.
- [x] One error shape; no stack trace or server detail in a response body.
- [ ] Production answers the JSON protocol — `GET` returns a JSON 405 (F-03).

## PII (phone, location, blood type)
- [x] No client other than the donor reads a donor's `lat`, `lng`, `geohash`; distances leave the
      server rounded to 0.5 km (ADR 0003).
- [x] The portal never asks for donor coordinates (field masks); ADR 0003 is amended for the rule
      that still allows an admin token to read them. Board rows are not keyed by uid (F-11).
- [x] The requester's contact (`requests/{id}/private/contact`) is readable only by the creator
      and donors who accepted. Tested.
- [x] That contact stops being readable once the request is cancelled or expires (F-19).
- [x] Account deletion removes or anonymises everything that names the person (DEC-016).
- [x] The app clears its local database, sync queue and Firestore cache on sign-out and
      deletion (F-07).
- [x] No PII in URLs (the donor name moved to a cookie, F-17).
- [x] No phone number, coordinate or blood type in a server log line.

## Secrets and configuration
- [x] No secret, service-account JSON, keystore or `key.properties` in git (`git ls-files`).
      `google-services.json` and `GoogleService-Info.plist` are not secrets.
- [x] `FIREBASE_SERVICE_ACCOUNT` lives only in Vercel env vars, read only in
      `frontend/src/server/firebase-admin.ts` (`server-only`), never `NEXT_PUBLIC_`.
- [ ] Rotate the service-account key if it is ever pasted anywhere but Vercel.
- [x] HSTS in production (2 years, Vercel default).
- [x] CSP with `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`
      (F-06). Not yet: a `script-src` (needs nonces).
- [x] The app accepts only `https://` for `PORTAL_URL` and web links outside debug builds (F-15).
- [ ] Release APK fails to build without `key.properties` instead of signing with the debug key.

## Dependencies
- [ ] No known critical or high advisory in production dependencies. Critical fixed (`next`
      15.5.26, F-02); one high left — postcss inside Next, fixed only in Next 16.
- [x] Update policy: critical fixed within 7 days, high within 30; `npm audit --omit=dev`
      (`frontend/`, `firebase/`) and `flutter pub outdated` at every milestone; Dependabot
      (`.github/dependabot.yml`, active once on `main`) (F-09).

## External services (Firebase Auth, FCM, Vercel)
- [x] FCM tokens are stored per user and nulled on sign-out and deletion.
- [x] The device token is also deleted on the phone (`FirebaseMessaging.deleteToken()`, F-20).
- [ ] Firebase console reviewed: only the Google (and Facebook) providers on, authorised domains
      limited to the portal, the web API key restricted. Not yet inspected.

> Any change touching the above runs the R6 gate: threat model (`threat-models/`) + review note
> (`reviews/`) before merge.
