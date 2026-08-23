---
id: 0002-auth-google-sign-in
title: Authentication via Google Sign-In, not phone OTP
status: accepted
date: 2026-08-07
deciders: Tech Lead + PO
supersedes: 0001-stack-and-architecture (auth clause only)
---

## Context

ADR 0001 chose phone OTP → JWT. Phone OTP requires an SMS provider, and every SMS costs money:

- Firebase Phone Auth has a free verification tier, then charges per verification, and requires the
  Blaze plan with a payment method on file.
- Local Cambodian aggregators (Smart / Cellcard / Metfone) are cheapest per message but generally
  require a registered business and a contract — impractical for a student team.
- Twilio-class providers need no paperwork but are the most expensive per message to Cambodia.

Exact rates were not confirmed and move over time, so no figure is recorded here. The relevant fact
is structural: OTP means a paid, contract-bound dependency plus recurring per-message cost, on the
one code path every single user must pass through before the product does anything.

OTP is also the most security-sensitive surface in the app. Done correctly it needs send
rate-limiting, expiry enforcement, brute-force protection over a 6-digit space, and a resend cooldown
(which is why `FR-AUTH-002` existed at all). All of that is our code to write, test, and get right.

## Decision

Authenticate with **Google Sign-In** via Firebase Auth. The client obtains a Google ID token; the
backend verifies that token's signature and audience and issues its own JWT. Session handling, JWT
claims, and RBAC (donor / requester / hospital / admin) are unchanged from ADR 0001 — only the
identity-proof step changes.

Phone number becomes an ordinary **unverified profile field**, not the credential.

Rejected alternatives:

- **Telegram bot OTP** — free and a good cultural fit for Cambodia; kept as the fallback if Google
  Sign-In proves unacceptable for donor sign-up. Rejected as primary because it still means writing
  the full OTP verification and rate-limiting path.
- **Email OTP** — free tiers are sufficient, but many target donors have no email address in regular
  use.
- **Phone + password** — free, but *more* work than OTP: password hashing, a reset flow, and that
  reset flow needs a verified channel, which is exactly what removing OTP takes away.

## Consequences

Cost and effort both drop. Google Sign-In is not merely cheaper than OTP, it is **less code**: no
code generation, no expiry window, no send rate-limiting, no brute-force defence, no resend cooldown.
`FR-AUTH-002` is retired outright. The Firebase SDK is already a dependency for FCM push at M3, so
nothing new is added to the build.

**The real cost is the loss of a verified phone number**, and it is not cosmetic. The product's core
loop assumes that when a donor accepts an urgent request, someone can reach them. An unverified
number means an unreachable donor at the one moment that matters.

Mitigation, in order:

1. **Coordinate through FCM push in-app, not phone calls.** FCM is already being built at M3 and is
   a verified delivery channel — the token is bound to an installed app instance. This is the primary
   answer and it must be reflected in FR-REQUEST-002's accept flow.
2. **Verify phone numbers lazily** — only when a donor first accepts a request, if the coordination
   flow still needs a callable number. Volume at that point is a tiny fraction of total signups, so
   even paid SMS would cost very little. Not scheduled; revisit at M4.

Backend must verify Google ID tokens server-side (signature, `aud`, `iss`, expiry) and must never
trust a client-supplied user identifier. A client that can assert its own identity is an
authentication bypass, so this is an R5 change and runs the R6 gate.

Two items remain open and are tracked as FR scope, not here: whether hospital and admin portal
sign-in uses Google at all (`FR-AUTH-003`), and whether donors without a Google account are locked
out — the Telegram fallback above is the answer if that turns out to be common.

**Addendum, 2026-08-23.** PO requested both the Telegram fallback and Facebook Login be added for
donors — see [`FR-AUTH-004`](../../po/features/FR-AUTH-004-additional-sign-in-providers.md).
Deferred to after M7: Facebook's own App Review timeline is outside the team's control, and
Telegram here still means the bot-driven OTP path this ADR chose Google Sign-In to avoid, not a
one-button addition.

## Note on where decisions are recorded

DEC-001..003 lived in `docs/pm/decisions.md`. The PM role was dropped on 2026-08-07 and that directory
removed; the register was relocated to [`docs/decisions.md`](../../decisions.md), since a decision
register belongs to the project rather than to a role. From that date, hard-to-reverse **technical**
choices are ADRs in `docs/tech-lead/adr/` and are indexed from that register.
