---
id: FR-AUTH-003-google-sign-in
title: Authentication via Google Sign-In
area: AUTH
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-01
supersedes: FR-AUTH-001-phone-otp-auth
adr_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Problem
A donor in an emergency cannot be reached unless they have an account, but asking a Cambodian
volunteer to invent and remember a password creates a barrier at exactly the wrong moment. The
previous answer — a code sent by SMS — solved the barrier but introduced a paid dependency on the one
path every user must cross, and put the app's most attackable surface (code generation, expiry,
brute-force, resend abuse) into our own code.

## Desired outcome
Anyone can create an account and sign in with one tap using the Google account already on their
Android phone. The app holds a session afterwards without asking again. No password, no code to read
and retype, no SMS.

## Why
Every other feature depends on identity. Matching, notifications, donation history, and the privacy
rule that hides donor contact until acceptance all need a known user. Nothing ships before this.

Google Sign-In is chosen over phone OTP because it is both free and *less* work — Firebase performs
the identity proof, so there is no code to generate, expire, rate-limit, or protect from brute force.
Full rationale and rejected alternatives in [ADR 0002](../../tech-lead/adr/0002-auth-google-sign-in.md).

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/AUTH-google-signin/>

**Out:**
- Phone-number verification. Phone becomes an unverified profile field (see FR-DONOR-001).
- Hospital and admin portal sign-in, which may not use Google at all — that is `FR-AUTH-004`, not a
  change to this FR. See the portal sign-in question in
  `docs/fullstack/specs/foundation/frontend-nextjs.md`.

## Acceptance criteria
Criteria live in `../prd.md` under FR-01 and are not duplicated here. Finalize this section after
the prototype settles the flow.

- [ ] <to be filled after prototyping>

### Criteria added by security review (do not defer to prototyping)
`SEC-REVIEW-001` finding F2 — these are controls, not UX, so they are stated here rather than waiting
on a wireframe. See [`TM-AUTH-001`](../../security/threat-models/TM-AUTH-001-google-sign-in.md).

- [ ] Identity is taken **only** from the verified ID token's `sub` claim. No endpoint accepts a user
      ID, `uid`, or email from the client (threat S1 — account takeover).
- [ ] Token verification checks signature, `aud` == our Firebase project ID, `iss`, and expiry. All
      four (threat S2 — a token minted for someone else's Firebase project verifies otherwise).
- [ ] Self-service sign-up can only produce `DONOR` or `REQUESTER`; a request for `HOSPITAL` or
      `ADMIN` is rejected with an error, not downgraded (threat E1 — privilege escalation).

## Carried risk — must be closed elsewhere
Removing OTP removes the guarantee that a donor's phone number reaches a real human. The product's
core loop assumes an accepted request leads to contact. Mitigation is **coordinate via FCM push
in-app rather than by phone call**, which lands in `FR-REQUEST-002` (respond accept/decline) and
`FR-NOTIFY-001` (request push alert) — not here. If those flows still need a callable number, phone
verification returns as a lazy step at acceptance time only (ADR 0002, mitigation 2).

Do not close this FR as done while `FR-REQUEST-002`'s accept flow still assumes a verified phone.
