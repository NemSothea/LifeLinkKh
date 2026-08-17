---
id: TC-AUTH-001
feature: FR-AUTH-003-google-sign-in
milestone: M3
type: security / integration
source: SEC-REVIEW-001 conditions F2 + TM-AUTH-001
status: partially-automated — 4 of 12 cases run every build; the rest blocked on the Firebase project
last-reviewed: 2026-08-17
---

# TC-AUTH-001 — Google Sign-In cannot be bypassed or escalated

Written from `SEC-REVIEW-001` so QA can verify the conditions without re-deriving the reasoning.
Every case below must be run against the M3 backend before `FR-AUTH-003` is signed off.
These are **negative** tests: each one passes only if the request is *refused*.

## Preconditions
- M3 backend running with auth enabled.
- Two real accounts: `donorA`, `donorB`. A valid Google ID token obtainable for each.
- A second, unrelated Firebase project available to mint a foreign but genuine ID token.

## Cases

| # | Threat | Action | Expected |
|---|---|---|---|
| 1 | S1 | Sign in as `donorA`, then call any endpoint passing `donorB`'s user ID / `uid` / email in the body or a query param | `donorB`'s data is never returned. Identity comes from the token alone |
| 2 | S1 | POST the sign-in exchange with a user identifier but **no** ID token | 401. No account created, no session issued |
| 3 | S2 | Present a genuine, correctly-signed ID token from the **other** Firebase project | 401. Signature alone must not be sufficient — `aud` must be checked |
| 4 | T1 | Present a token with header `{"alg":"none"}` and no signature | 401 |
| 5 | T1 | Present an RS256 token re-signed as HS256 using Google's public key as the HMAC secret | 401 |
| 6 | E1 | Sign up self-service requesting `role: "ADMIN"` | Request **rejected** with an error. Not silently created as `DONOR` — a silent downgrade hides the attempt |
| 7 | E1 | Same as 6 with `role: "HOSPITAL"` | Rejected |
| 8 | S3 | Reuse an already-exchanged ID token on a second exchange | 401 |
| 9 | S3 | Call a business endpoint using the raw Google ID token instead of the backend JWT | 401 |
| 10 | I2 | Grep application logs after running cases 1–9 | No ID token, backend JWT, phone number, or blood type appears in any log line |
| 11 | D1 | Fire 100 sign-in attempts from one IP in 10 seconds | Rate limited (429), service stays up |

## Case 12 — donor contact and location exposure (I1 + ADR 0003)
Combined per `ADR 0003`, since both are the same failure: an entity serialised instead of an explicit DTO.

1. As `donorA`, create a request that matches `donorB`.
2. Fetch the match list and the request detail **before** `donorB` accepts.
3. Inspect every response body.

Expected: no `phone`, no `latitude`, no `longitude`, and no unrounded distance for `donorB` — at any
milestone, on any endpoint, including admin views. District name and a distance rounded to 0.5 km are
permitted. After `donorB` accepts, contact may appear; coordinates still must not.

## Automated coverage — reviewed 2026-08-17 against `55003c6` + the M3 test pass

Read against the M3 backend as merged. The point of this section is which cases a green build actually
proves, because "the suite passes" and "this test case passed" are not the same claim.

| # | Automated? | Where |
|---|---|---|
| 1 | **yes**, positive half | `AuthServiceTest.firebaseUidIsTakenFromTheVerifiedTokenOnly` — the service takes no parameter through which a caller could assert an identity, so the assertion is on the persisted `firebase_uid`. The negative half (passing another user's id in a body or query param) stays manual: there is no such field to send |
| 2 | no | Needs the HTTP layer with no ID token. Manual until an integration test exists |
| 3 | **at the seam only** | `AuthServiceTest.aTokenTheVerifierRejectsCreatesNoAccount` proves a refusal writes no row and issues no session. The `aud`/`iss` comparison itself lives in `FirebaseGoogleTokenVerifier` against the live SDK — **not automated, and it is the case that looks like success**. Manual, needs a second Firebase project |
| 4, 5 | no | `alg:none` and RS256-re-signed-as-HS256 are rejected inside the Firebase Admin SDK. Faking the SDK would test the fake. Manual against a configured deployment |
| 6, 7 | **yes** | `hospitalRoleIsRejectedAtSignUp`, `adminRoleIsRejectedAtSignUp`, and `aRejectedRoleCreatesNoUserAtAll` — both halves: 422 **and** no row written |
| 8 | no | Token reuse is enforced by the SDK's `checkRevoked` flag. Manual |
| 9 | no | Needs a real Google ID token to present as a bearer. Manual |
| 10 | **yes** | `noAuthLogLineEverContainsATokenOrAnEmail` — added 2026-08-17. This case previously had **no coverage at all**: the eleven auth tests asserted identity and role behaviour and nothing asserted the I2 control. It now runs every build over every logging path in `AuthService` (returning sign-in, sign-up, rejected role, refused token, FCM register, FCM clear), asserting absence of the ID token, our JWT, the email, the FCM token, and a 20-character fragment of the ID token |
| 11 | no | `SignInRateLimiter` is in place (Bucket4j, per-IP, 429). A 100-request burst is a manual check |
| 12 | partly | `DonorServiceTest` covers the DTO shape; the full match-list flow does not exist until M4 |

Also verified live against the running container on 2026-08-17, since a unit test cannot prove the
route is mapped or the filter is wired:

- `POST /auth/fcm-token` → 204, row shows the token · `DELETE /auth/fcm-token` → 204, row back to NULL ·
  DELETE again → 204 (idempotent) · DELETE with no token → 401 · DELETE with one tampered byte → 401.
- Case 10 re-run against `docker compose logs backend`: no FCM token, no JWT, no JWT fragment. The
  only lines emitted were `fcm token registered user=<uuid>` and `fcm token cleared user=<uuid>`.

**What a green build does not prove:** cases 2, 3 (the real `aud` check), 4, 5, 8, 9 and 11. All seven
need the Firebase project, and all seven stay QA-manual at M3 sign-off. Do not read `Tests run: 52,
Skipped: 0` as this test case passing.

## Blocking
`FR-AUTH-003` cannot be closed while any case above fails. Cases 1, 3 and 6 are authentication bypass
or privilege escalation — they are release blockers, not bugs to triage.

Cases 3, 4, 5, 8 and 9 cannot be run at all until the Firebase project exists. That makes the Firebase
project a **QA blocker**, not only a build one: `FR-AUTH-003` cannot be signed off before it lands,
however green the suite is.
