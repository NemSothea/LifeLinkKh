# OWASP ASVS Baseline

**Standard:** OWASP Application Security Verification Standard, **version 5.0** `[uncertain — confirm
the current release and its chapter numbering at owasp.org before citing this externally]`.
**Chosen level: Level 1.** Requirement IDs are deliberately not quoted below: the exact numbering in
the current release is not verified here, and a wrong ID is worse than no ID. Controls are stated in
plain words and traced to our own artefacts instead. Attach real IDs when someone verifies them
against the published document.

## Why Level 1, not 2 or 3

Level 1 is the baseline every application should meet. Level 2 assumes an application handling
significant sensitive data, and its additional demands — formal key management, hardened session
lifecycle, cryptographic review, verified logging infrastructure — cost weeks and earn zero course
marks.

The honest counter-argument, recorded rather than hidden: this app stores phone numbers, blood type
and location, which **is** sensitive personal data, and a real deployment would owe Level 2. Level 1
is defensible *only* because the pilot runs on team-created test accounts with no member of the
public involved (`../scope.md`). **If the pilot widens beyond the team, Level 2 and
`FR-SECURITY-001` (account and data deletion) come back into scope before any real donor signs up.**

## Controls in scope, mapped to our 8 FRs

| Area | Control | Where it must hold | Traced to |
|---|---|---|---|
| Authentication | The Google ID token is verified server-side — signature, `aud`, `iss`, expiry. A client-supplied user identifier is never trusted. | `FR-AUTH-003`, M3 | `TM-AUTH-001` S1, ADR 0002 |
| Authentication | Sign-in is rate-limited; a replayed token is rejected. | `FR-AUTH-003`, M3 | `security-checklist.md` |
| Session | Our own token is signed, short-lived, and logout invalidates it. No long-lived credential on the device. | M3 | `SEC-REVIEW-001` |
| Authorization | Every endpoint enforces its role server-side. Self-service sign-up can produce only `DONOR` or `REQUESTER` — rejected, never silently downgraded. A donor may read and write only their own profile. | all FRs, M3 | `TM-AUTH-001` E1 |
| Input validation | Server-side validation on every request body. Business rules (56-day cooldown, ABO/Rh compatibility, units > 0, urgency and status values) are enforced in the backend, not only in a client. | `FR-DONOR-002`, `FR-REQUEST-001`, `FR-MATCH-001` | DB CHECK constraints in `V1__init.sql` |
| Data protection | No response ever contains donor `latitude`, `longitude`, or an unrounded distance. Location is a district; distance is rounded to 0.5 km. | every donor-facing endpoint | ADR 0003 |
| Data protection | Donor contact details are released only after that donor accepts a request. | `FR-REQUEST-002` | `prd.md` §6 |
| Data protection | All traffic over TLS. Donor coordinates are dropped with the profile row — no separate retention. | all | ADR 0003 |
| Error handling | One error shape. No stack trace, exception name, SQL fragment or server detail in a response body. | all | `common/error/` |
| Logging | No phone number, coordinate, or blood type in any log line. Provider failures are logged without PII. | all | `security-checklist.md` |
| Configuration | No secret, key or connection string in git. Everything via environment variables. Firebase and FCM credentials are injected, never committed. | all | `application.yml` (already compliant) |
| Configuration | The permissive M2 `SecurityConfig` MUST NOT reach any deployed environment; M3 replaces it wholesale. | `backend/config/SecurityConfig.java` | foundation spec |
| API | CORS is an explicit allow-list, never `*`. | M3 | — |

## Out of scope, with reasons

| Area | Why not |
|---|---|
| File upload and handling | The app has no upload. No donor photo, no document, no attachment. |
| Own cryptography | We implement none. Identity proof is Firebase's; transport is TLS. Any crypto we appear to need is a signal to re-read this line. |
| Full OAuth / OIDC hardening | Delegated to Firebase Google Sign-In. Our only obligation is verifying the returned token correctly — covered above. |
| WebSocket and real-time channel security | No such channel. Push is FCM. |
| Business-logic anti-automation beyond sign-in rate limiting | Pilot scale, closed account set. |
| Deletion and retention verification | `FR-SECURITY-001` is deferred (`../scope.md`) — and that deferral is a privacy obligation, not a scheduling win. Blocks any public pilot. |

## Current gaps against this baseline

Every one of these is M3 work; none is a defect today, because M2 has no authentication by design.

1. `SecurityConfig` permits everything — no authentication, no RBAC.
2. No token verification, no rate limiting, no CORS configuration exists yet.
3. No response DTOs exist yet, so the ADR 0003 coordinate ban is currently unenforced by code —
   only by the absence of endpoints. The first donor endpoint written must carry the test from
   `../qa/test-strategy.md` §"Non-negotiable security tests".
4. `SEC-REVIEW-002` against the M3 implementation is required and not yet scheduled.

## How this is verified

Not by reading this file. Each control above maps to a test in
[`../qa/test-strategy.md`](../qa/test-strategy.md), and the four in its "Non-negotiable security
tests" section are the ones whose failure is a privacy breach rather than a bug.
