---
id: SPEC-AUTH-GOOGLE-SIGN-IN
owner: Fullstack
status: draft — awaiting Tech Lead + Security sign-off (R5 applies)
milestone: M3
fr_ref: ../../../po/features/FR-AUTH-003-google-sign-in.md
adr_ref: ../../../tech-lead/adr/0002-auth-google-sign-in.md
threat_model: ../../../security/threat-models/TM-AUTH-001-google-sign-in.md
contract: ../../api-contract/mobile/contract.md
---

# M3 Build Spec — Google Sign-In, session JWT, FCM token registration

Covers two endpoints and the security posture change that comes with them:

| Method | Path | Auth | FR |
|---|---|---|---|
| POST | `/auth/google` | none | `FR-AUTH-003` |
| POST | `/auth/fcm-token` | JWT | `FR-NOTIFY-001` (registration half, pulled into M3 by DEC-002) |

`GET`/`PUT /donors/me` are the other half of M3 and live in
[`donor-profile.md`](donor-profile.md).

This spec does not restate the threat model. Every control below carries its `TM-AUTH-001` threat ID;
that document is the reason, this one is the implementation.

## What changes about the system as a whole

M2 shipped `SecurityConfig` with `anyRequest().permitAll()` and a comment saying M3 replaces it
wholesale. That replacement is the largest single change here, and it is the one most likely to be
got subtly wrong, because a mistake fails open and every test still passes.

**Deny by default.** The new chain permits exactly three things and authenticates everything else:

| Permitted without auth | Why |
|---|---|
| `GET /health` | Liveness. Unauthenticated by design (foundation spec) |
| `POST /auth/google` | The endpoint that mints the credential |
| OPTIONS preflight | CORS, below |

Anything else — including any endpoint added later by someone who forgets this file — requires a
valid backend JWT. Written as `anyRequest().authenticated()`, never as an enumerated deny-list. A
new endpoint must be *deliberately* opened, not accidentally left open.

Also in this change:

- `SessionCreationPolicy.STATELESS`. No `JSESSIONID`, no server-side session. The JWT is the session.
- CSRF stays disabled — correct for a stateless bearer-token API, and now correct for a documented
  reason rather than by inheritance.
- **CORS as an explicit allow-list** (ASVS baseline, API row). The Next.js portal origin only. Never
  `*`. `*` is incompatible with credentials anyway, so a wildcard here would be both a finding and a
  bug.

## `POST /auth/google`

### Flow

1. Client sends `{ idToken, role? }`. `role` is `DONOR` or `REQUESTER`, honoured **only** when this
   `sub` has no existing user row.
2. Verify the token with the **Firebase Admin SDK `verifyIdToken()`** — not a hand-rolled JWT parse.
3. Look up `users` by `firebase_uid == sub`. Create on miss, load on hit.
4. Issue our own JWT. Respond `AuthResponse` per the contract.

### Verification — the part that must not be improvised

Use `FirebaseAuth.getInstance().verifyIdToken(idToken)`. It pins RS256, fetches and caches Google's
JWKS, honours key rotation, and checks `exp` and `iat`. Hand-rolling any of that is where threat
**T1** (algorithm confusion, `alg: none`) comes from — the Admin SDK exists precisely so we do not
write that code.

The SDK does **not** relieve us of two checks:

- **`aud` == our Firebase project ID** — the SDK checks this against the credential it was
  initialised with, so the control is really "initialise it with the right project and fail loudly if
  the project ID is unset". A missing project ID must abort startup, not default to something.
- **`iss` == `https://securetoken.google.com/<project-id>`** — assert it explicitly.

Both, not either (**S2**). A genuine, correctly-signed Google token minted for a *different* Firebase
project verifies cryptographically and must still be rejected. This is the failure mode that looks
like success.

### Identity comes only from `sub` (S1)

`users.firebase_uid` is written from the verified token's `sub` claim and from nowhere else. No
endpoint in this build accepts a user ID, `uid`, `firebaseUid`, or email in a request body — not
here, not on `/donors/me`, not anywhere. The DTOs must make this structurally impossible rather than
merely unused: **there is no such field to bind**, so no future controller can accidentally start
trusting it.

Display name comes from the token's `name` claim. Email is received and deliberately not stored — we
have no use for it, and storing it makes it a breach asset.

### Role allow-list (E1)

`role` accepts `DONOR` or `REQUESTER`. `HOSPITAL` or `ADMIN` → **422**, rejected outright.

**Not** downgraded to `DONOR`. A silent downgrade turns a privilege-escalation attempt into a
successful signup and destroys the only signal that someone tried. The rejection is also what makes
the attempt visible in the auth log.

On an existing user, `role` in the body is ignored entirely — not validated, not compared, ignored.
Role changes are not a self-service operation in this build.

### Our JWT

| Property | Value | Why |
|---|---|---|
| Signing | HS256, secret from an environment variable | No key distribution problem at this scale; the secret is the asset `TM-AUTH-001` lists |
| Subject | internal `users.id` UUID | Not the Google `sub`. Our tokens address our identity space |
| Claims | `sub`, `role`, `iat`, `exp` | Nothing else. No phone, no email, no name — a JWT is readable by anyone holding it |
| Lifetime | short — pin the exact value with Tech Lead at sign-off | ASVS baseline: "signed, short-lived" |

**Open, and deliberately not decided here:** the exact lifetime, and what happens when it expires.
A short lifetime with no refresh path means a donor is silently signed out — unacceptable against
`FR-AUTH-003`'s "session persists across app restarts" and the PRD's "an emergency alert is never
blocked by a login screen". A long lifetime with no revocation means a stolen token stays valid.

The cheapest resolution that satisfies both: the Flutter client holds the Google refresh token via
the Firebase SDK (which it already does) and silently re-calls `/auth/google` when our JWT expires.
No refresh-token table, no rotation logic, no new endpoint. **This is a proposal for Tech Lead, not a
decision.** Whatever is chosen must be written into ADR 0002 or a new ADR before the code merges,
because "how does the session end" is exactly the kind of thing that gets decided by accident.

Sign-out (`FR-AUTH-003` criterion) is client-side token disposal plus clearing the FCM token
server-side. With short-lived stateless JWTs there is no server-side revocation list, and adding one
is not justified at pilot scale — but this is the trade being made, and it belongs in the same ADR.

### Rate limiting (D1)

Per-IP limit on `/auth/google`, returning **429** with the standard error envelope. The endpoint is
unauthenticated and does network I/O to Google on every call, so it is the one place a flood costs us
real resources.

In-memory (Bucket4j or equivalent) is sufficient — single instance, pilot scale. A distributed limiter
would be architecture for a deployment we do not have.

### Auth logging (R1, I2)

Log every sign-in attempt: internal user UUID, event, timestamp, outcome.

**Never** the ID token, the JWT, the raw `sub`, an email, a phone number, or a blood type — in any
log line, at any level, including the exception path. The most likely leak is not a deliberate
`log.info(token)` but a stack trace or a `toString()` on a DTO, so the DTOs carry no sensitive fields
and the global handler never logs a request body.

On a *failed* verification there is no internal user ID to log. Log the outcome and the reason class
(`EXPIRED`, `WRONG_AUDIENCE`, `MALFORMED`) — never the token that failed.

## `POST /auth/fcm-token`

`{ fcmToken }` → **204**. Authenticated. Writes `users.fcm_token` for the caller and nobody else —
the target user is the JWT subject, never a body field.

Called by the client after sign-in and again whenever the Firebase SDK rotates the token, which it
does on its own schedule. The endpoint is therefore idempotent by nature: same token twice is a
no-op write, not an error.

The column is `TEXT NULL`; the M2 comment already reads "registered at M3" (`SEC-REVIEW-001` F4).
Nothing schema-side changes here.

An FCM token is a capability — whoever holds it can push notifications to that device
(`TM-AUTH-001` assets). It is never returned by any endpoint, never logged, and cleared on sign-out.

## Package layout

Inside the existing `kh.lifelink.api` domain-module structure (foundation spec):

```
auth/
  AuthController.java        POST /auth/google, POST /auth/fcm-token
  AuthService.java           verify → find-or-create → issue
  GoogleTokenVerifier.java   Firebase Admin SDK wrapper; the only class that touches it
  JwtService.java            issue + parse our JWT
  JwtAuthFilter.java         OncePerRequestFilter → SecurityContext
  dto/                       AuthRequest, AuthResponse, FcmTokenRequest
config/
  SecurityConfig.java        replaced wholesale
  FirebaseConfig.java        Admin SDK init; fails startup if project ID is unset
```

`GoogleTokenVerifier` is a thin seam on purpose: it is the one place Firebase is mocked in tests, and
the one place to change if ADR 0002's rejected Telegram fallback is ever revisited.

## New dependencies

| Dependency | For |
|---|---|
| `com.google.firebase:firebase-admin` | `verifyIdToken()` — S1/S2/T1 |
| `io.jsonwebtoken:jjwt` (api/impl/jackson) | Our own JWT |
| `com.bucket4j:bucket4j-core` | Sign-in rate limit — D1 |

All three are new to `pom.xml`. Firebase Admin is a large transitive tree; check what it pulls before
merging.

## Configuration

| Env var | Purpose | Absent → |
|---|---|---|
| `FIREBASE_PROJECT_ID` | The `aud`/`iss` value to pin | **Startup fails** |
| `GOOGLE_APPLICATION_CREDENTIALS` | Admin SDK service account | **Startup fails** |
| `JWT_SECRET` | HS256 signing key | **Startup fails** |
| `CORS_ALLOWED_ORIGINS` | Portal origin allow-list | **Startup fails** |

All four fail startup when unset. None gets a development default. A default here is a control that
silently disables itself in the one environment where it matters — and `.env` is gitignored, so a
missing variable is a normal, expected condition to hit.

The service-account JSON is never committed. `.gitignore` and `docs/tech-lead/local-development.md`
both need a line for it.

## Tests

Testcontainers is already wired and, as of `d1f5efd`, actually runs (`BUG-BUILD-003`). `Skipped: 0`
remains the gate — a skipped auth test is worth less than no test, because it reads as coverage.

Non-negotiable, from `docs/qa/test-strategy.md` § Non-negotiable security tests:

1. A request body carrying `userId`/`firebaseUid`/`email` does not influence the resulting identity
   (S1). Assert on the persisted row, not on the response.
2. A token whose `aud` is a different Firebase project is **rejected** (S2) — the one that looks like
   success.
3. `role: "ADMIN"` and `role: "HOSPITAL"` each return 422 and create **no** user row (E1). Assert both
   halves; a rejection that still writes a row is the same bug wearing a hat.
4. A `HOSPITAL` attempt is not silently stored as `DONOR`.
5. `POST /auth/fcm-token` writes the caller's row only — a second authenticated user's token is
   untouched.
6. No log line emitted during any of the above contains the ID token, the JWT, or an email (I2).

Test 2 needs a token signed for another project. Mock `GoogleTokenVerifier` — do not attempt a real
second Firebase project for a test.

## Blocked on, before this can be built

1. **The Firebase project does not exist yet.** Register the Android app and add the **debug SHA-1
   fingerprint**, then produce the service-account JSON. `docs/scope.md` flags this as external lead
   time that blocks M3, and Google Sign-In fails *silently* without the fingerprint. Tech Lead's, and
   nothing here can be verified end-to-end until it exists. Unit tests against a mocked verifier can
   proceed in parallel.
2. **JWT lifetime and expiry behaviour** — the open question above. Needs an ADR line before merge.

## Sign-off required

R5 applies: this touches authentication, identity, and PII. Definition of Done step 1 needs PO
(done — `FR-AUTH-003` finalized 2026-08-17), **Tech Lead**, and **Security**. `SEC-REVIEW-002`
against the implementation is already listed as required and unscheduled.
