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
Finalized 2026-08-17 from [`AUTH-google-signin`](../prototypes/mobile/AUTH-google-signin/), which is
now frozen for the M3 build.

**In:**
- A welcome screen stating, before any account picker appears, what the app does with the account.
  One line. No skip, no guest mode — every downstream feature needs a known user.
- **Continue with Google** → the system account sheet (rendered by Play Services, not by us) →
  a role screen. Three taps from cold start to a usable account.
- Role selection as two cards, worded by intent ("I want to donate" / "I need blood for someone"),
  not by the database values `DONOR` / `REQUESTER`. `HOSPITAL` and `ADMIN` never appear.
- Account creation on first sign-in, from the verified ID token alone.
- A session that survives app restarts, and a sign-out that ends it.
- Cancelling the Google sheet returns to the welcome screen with no account and no error dialog.

**Out:**
- Role *change* after sign-up. The screen says "You can change this later" because that is the
  intended product, but the settings path that delivers it is not in M3 and has no FR yet. Do not
  read the wireframe caption as scope.
- Terms and privacy acceptance — deferred with `FR-SECURITY-001` (`docs/scope.md`), not an oversight.
- Showing the user's email back to them. Google gives it to us; there is no reason to display it.
- Phone-number verification. Phone becomes an unverified profile field (see FR-DONOR-001).
- Hospital and admin portal sign-in, which may not use Google at all — that is `FR-AUTH-004`, not a
  change to this FR. See the portal sign-in question in
  `docs/fullstack/specs/foundation/frontend-nextjs.md`.

## Acceptance criteria
The five product criteria live in `../prd.md` under FR-01 and are not duplicated here. What follows
is what the prototype settled and the PRD does not say — these are additional, not a replacement.

- [ ] Cold start to a usable account is **three taps**: Continue with Google → account → role.
- [ ] The welcome screen states what the account is used for *before* the picker opens, in Khmer and
      English (`FR-GLOBAL-001`).
- [ ] Role is chosen on the sign-in flow, not deferred to a settings screen — it decides which home
      screen the user lands on, so routing cannot complete without it.
- [ ] Cancelling the Google sheet leaves **no** partial account and shows **no** error dialog. A
      cancel is a choice, not a failure (`prd.md` §7).
- [ ] A returning user reaches their home screen without seeing the role screen again.

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
