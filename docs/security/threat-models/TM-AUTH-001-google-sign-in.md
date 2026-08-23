---
id: TM-AUTH-001
feature: FR-AUTH-003-google-sign-in
date: 2026-08-07
author: Security (Tech Lead overlay)
adr_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Assets

| Asset | Why it matters |
|---|---|
| Donor PII — phone, blood type, location | Blood type is health data (`prd.md` §6). Phone + blood type + location together identify a person and their medical status. |
| User accounts | Owning an account means receiving emergency alerts and being able to accept requests on someone else's behalf. |
| Backend JWT signing key | Forging a JWT bypasses authentication entirely for every user at once. |
| Firebase project config (`google-services.json`, project ID) | Not a secret in itself, but the audience value the backend must pin. |
| FCM registration tokens | Let an attacker push arbitrary notifications to a specific donor's device. |
| Role assignment (`users.role`) | `HOSPITAL` and `ADMIN` see requester contact details and moderate content. |

## Trust boundaries

```
[Flutter app / Next.js portal]   UNTRUSTED — user controls the device and every byte it sends
        │  HTTPS: Google ID token
        ▼
[Spring Boot API]                trusted, but must treat every inbound claim as hostile
        │  HTTPS: JWKS fetch
        ▼
[Google token infrastructure]    trusted third party
        │
[PostgreSQL]                     trusted, reached only from the API
```

The decisive boundary is the first one. Google Sign-In moves the identity proof off our
infrastructure, which is why it is cheaper — but the *result* of that proof arrives over the network
from a client we do not control. Everything below follows from that.

## Threats (STRIDE)

### S1 — Client asserts its own identity (Spoofing) — **critical**
The client posts a user ID, Firebase `uid`, or email alongside (or instead of) the ID token, and the
backend uses it. Any user then authenticates as any other user by changing one field. Total account
takeover of every donor, with no credential needed.

### S2 — ID token minted for a different Firebase project (Spoofing) — **high**
Google signs ID tokens for every Firebase project, so signature validity alone proves nothing about
*which* app the token was issued for. An attacker creates their own free Firebase project, signs in
there, and presents that token to us. If `aud` is not pinned to our project ID it verifies
cryptographically and grants access.

### S3 — Token replay (Spoofing) — **medium**
A Google ID token stays valid for roughly an hour. A token captured from logs, a crash report, an
analytics payload, or a proxy can be exchanged for a session within that window.

### T1 — Algorithm confusion / unsigned token (Tampering) — **high**
A token with `"alg": "none"`, or an RS256 token verified as HS256 using the public key as an HMAC
secret. Both are library-configuration failures, not exotic attacks, and both yield full forgery.

### E1 — Client-chosen role (Elevation of privilege) — **critical**
`prd.md` §2.1 says donor/requester are self-selected while hospital and admin accounts are
provisioned by an admin. If the sign-up request carries `role` and the backend stores it verbatim, a
donor self-promotes to `ADMIN` or `HOSPITAL` on first sign-in — gaining requester contact details and
moderation powers. This is a product rule that only exists if the code enforces it.

### I1 — Donor contact exposed before acceptance (Information disclosure) — **high**
`prd.md` §5 and §6 require donor contact to appear only after that donor accepts. Any endpoint
returning a donor list — matching results, admin views, request detail — leaks it if the DTO is built
from the entity rather than from an explicit field set.

### I2 — Tokens or PII in logs (Information disclosure) — **medium**
ID tokens, backend JWTs, and phone numbers written to application logs, error responses, or FCM
failure handlers. Logs are the least-protected copy of the data.

### R1 — No authentication audit trail (Repudiation) — **low**
Nothing records who signed in when, so an account compromise cannot be reconstructed.

### D1 — Sign-in flood (Denial of service) — **low**
Unlimited sign-in attempts force JWKS fetches and signature verifications. Cheap to abuse, and the
free-tier Firebase quota is a shared resource.

## Mitigations

| ID | Mitigation | Where |
|---|---|---|
| S1 | Identity comes **only** from the verified token's `sub` claim. No endpoint accepts a user ID, `uid`, or email from the client. `users.firebase_uid` is written from `sub`, never from a request body. | M3 backend auth module |
| S2 | Verify `aud` == our Firebase project ID **and** `iss` == `https://securetoken.google.com/<project-id>`. Both, not either. | M3 |
| S1/S2/T1 | Use Firebase Admin SDK `verifyIdToken()` rather than a hand-rolled JWT parse. It pins RS256, fetches and caches Google's JWKS, honours key rotation, and checks `exp`/`iat`. Hand-rolled verification is where T1 comes from. | M3 |
| S3 | TLS everywhere. Exchange the ID token once for a short-lived backend JWT and never accept the ID token again on other endpoints. Backend JWT lifetime short, refresh handled server-side. | M3 |
| E1 | Server-side allow-list: a self-service sign-up may only produce `DONOR` or `REQUESTER`. `HOSPITAL` and `ADMIN` are assignable only by an existing `ADMIN`. Reject, do not silently downgrade — silent downgrade hides the attempt. | M3; "assignable only by an existing ADMIN" half implemented at M6 as `POST /admin/staff` — [`FR-PORTAL-003`](../../po/features/FR-PORTAL-003-staff-provisioning.md) — replacing `V8__portal_access.sql`'s hand-run insert for every account after the first `ADMIN` |
| I1 | Donor DTOs are explicit allow-lists, never entity serialisation. Contact fields populated only when `request_matches.response = 'ACCEPTED'` for the caller's own request. QA gets a test case per FR-REQUEST-002. | M3 / M4 |
| I2 | No token, phone number, or blood type in any log line or error response. Applies to the FCM failure path too. | M3, and `security-checklist.md` |
| R1 | Log auth events — internal user UUID, event, timestamp, outcome. UUID only, no phone, no email. | M3 |
| D1 | Rate-limit the sign-in endpoint per IP. Cache JWKS (the Admin SDK does this). | M3 |

## Residual risk

- **Donor phone numbers are unverified.** Not a confidentiality problem — a trust problem. A donor
  can register with a wrong or fake number and appear matchable while being unreachable. Accepted
  deliberately in ADR 0002; the mitigation is to coordinate through FCM push in-app rather than by
  phone call. Unresolved until `FR-REQUEST-002` reflects it.
- **Google account compromise equals app account compromise.** Inherent to delegated identity, and
  the trade accepted in ADR 0002. Google's own MFA is the control; we add none.
- **Users without a Google account cannot register.** Availability gap, not a security one. Fallback
  is Telegram OTP (ADR 0002).
- **No admin provisioning flow exists yet**, so the first `ADMIN` must be seeded by migration or by
  hand. That seeding step is itself an unreviewed privileged path — worth its own review when written.
