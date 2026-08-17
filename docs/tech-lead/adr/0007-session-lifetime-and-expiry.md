---
id: 0007-session-lifetime-and-expiry
title: Session JWT lives one hour; expiry is repaired by silent re-authentication, not a refresh token
status: accepted
date: 2026-08-17
deciders: Tech Lead
---

## Context

`docs/fullstack/specs/features/auth-google-sign-in.md` § "Our JWT" left two things open on purpose
and refused to settle them inside a build spec: **how long our session JWT lives**, and **what
happens to a signed-in donor when it expires**. `application.yml` shipped `JWT_LIFETIME:PT1H` with a
comment saying the value is a starting point, not a settled one. The M3 backend has merged around
that hole; the Flutter client has not been written yet, so the client half of the contract is still
free.

The two obvious answers each break something:

- **Short lifetime, no repair path** — the donor is silently signed out. That violates
  `FR-AUTH-003`'s "session persists across app restarts", and worse, it violates the PRD line that an
  emergency alert is never blocked by a login screen. A donor who opens a push notification at 03:00
  and lands on a sign-in screen is a failed match.
- **Long lifetime, no revocation** — a stolen token stays valid for as long as it lives. We have no
  server-side revocation list, so lifetime *is* the blast radius. There is nothing else to shorten.

The asymmetry that decides this: the client already holds a long-lived credential. Firebase Auth
keeps the Google refresh token in platform storage and `getIdToken(forceRefresh: true)` mints a fresh
Google ID token without any user interaction. A second refresh-token system of our own would
duplicate a mechanism that is already there, already tested by Google, and already a dependency
because FCM needs the Firebase SDK regardless.

## Decision

**1. Lifetime is one hour.** `JWT_LIFETIME` keeps its `PT1H` default and that default is now the
decision, not a placeholder. One hour is short enough that a leaked token is a bounded incident and
long enough that re-authentication is rare in a session.

**2. Expiry is repaired by silent re-authentication.** When any API call returns **401**, the Flutter
client calls `getIdToken(forceRefresh: true)` on the Firebase SDK, re-calls `POST /auth/google` with
the fresh Google ID token, stores the new session JWT, and **retries the original request exactly
once**. The user sees a slightly slower request and nothing else.

Rules the client must hold to, because each one is a way this goes wrong:

- **One retry, never a loop.** A second 401 after a successful re-auth is a real failure, not a stale
  token. Surface it.
- **`POST /auth/google` itself is never retried on 401.** That is the terminal case: the Google
  credential is gone (access revoked, account removed, refresh token invalidated). Clear stored
  session state and route to sign-in.
- **Concurrent 401s produce one re-auth, not one per in-flight request.** A cold app start firing
  three requests at once must not send three sign-ins; the second and third await the first.
- **The stored JWT lives in platform secure storage** (Keychain / Android Keystore), not
  `SharedPreferences`. It is a bearer credential — anything that can read it can act as the donor.
- **The client does not pre-emptively inspect `exp`.** 401 is the trigger. Reading expiry
  client-side means trusting a clock we do not control and adds a second code path that can disagree
  with the server's.

**3. No refresh-token table, no rotation, no new endpoint.** Nothing is added to the schema and
nothing is added to the API surface for session repair.

**4. No server-side revocation.** Sign-out is client-side disposal of the JWT plus clearing the
device's FCM token server-side. There is no deny-list, and a token already issued stays valid until
its `exp`. Accepted, with the bound stated in the open sense: the maximum window between a
compromise being known and it ceasing to matter is **one hour**.

**5. Sign-out needs an endpoint that does not exist.** `FcmTokenRequest.fcmToken` is `@NotBlank`, so
today there is no way to clear a token — a signed-out device would keep receiving urgent-request
pushes, which is a privacy leak (`I2`) and a wrong-donor alert at once. **`DELETE /auth/fcm-token`**
is owed, clearing the caller's row only, on the same authorization rule as the POST. Backend/DB work,
before M3 sign-off.

## Consequences

`FR-AUTH-003`'s persistence criterion is satisfied by the Firebase SDK's storage rather than by a
long session of ours: the app restarts, finds no valid JWT or a rejected one, silently re-authenticates,
and the donor never sees a login screen. The persistence guarantee is therefore only as good as the
Firebase SDK's own — if a user revokes the app's Google access, they get a sign-in screen, correctly.

The cost is that the client's HTTP layer is no longer trivial. A Dio interceptor with a single-flight
re-auth and a one-shot retry is real, easy-to-get-wrong code, and it must be unit-tested at the M3
mobile build: 401-then-success, 401-then-401, concurrent 401s collapsing to one sign-in, and
`/auth/google` returning 401 landing on the sign-in route. QA should treat the concurrency case as a
non-negotiable — it is the one that only shows up on a cold start with a real network.

The one-hour window is a stated, accepted risk, not an oversight. If pilot use shows a need for real
revocation, the cheap escalation is a `users.token_valid_after` timestamp compared against `iat` —
one column, no table, and it stays stateless-ish. Not now: it buys nothing at pilot scale and adds a
DB read to every authenticated request.

Nothing here changes the backend as merged. `JwtService` already issues exactly `sub`, `role`, `iat`,
`exp` and already answers 401 without saying why, which is what makes the client rule above safe to
write. Two documentation follow-ups are owed to Backend/DB: the `application.yml` comment above
`lifetime:` still calls the value unsettled, and the build spec's "Open, and deliberately not
decided here" paragraph should now point here.

## Alternatives considered

- **Our own refresh token, stored in a table, rotated on use.** The textbook answer, and it is
  strictly more secure — rotation detects replay, and a refresh row can be deleted, which gives real
  revocation. Rejected because it is a second credential system, a migration, an endpoint, a rotation
  bug class, and a family of tests, all to improve on a mechanism we are already forced to ship for
  FCM. At pilot scale it is architecture for a threat model we do not have.
- **A long-lived JWT (30 days) with no refresh at all.** Simplest possible client. Rejected: with no
  revocation, the blast radius of one leaked token becomes a month, and `TM-AUTH-001` lists the JWT
  as an asset precisely because it is bearer-only.
- **Sliding expiry — every response carries a renewed token.** No refresh table and no client
  re-auth logic. Rejected because it makes every endpoint part of the auth surface, an idle session
  never ends, and a stolen token renews itself indefinitely, which is the long-lifetime problem with
  extra steps.
- **Pre-emptive client-side refresh on an `exp` timer.** Fewer 401s. Rejected as the *primary*
  mechanism: it depends on device clock accuracy and it does not remove the need for the 401 path,
  so it is a second implementation of the same rule. May be added later as an optimisation on top,
  never as a replacement.
