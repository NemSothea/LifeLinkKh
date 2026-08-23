---
id: FR-AUTH-004-additional-sign-in-providers
title: Facebook and Telegram sign-in for donors
area: AUTH
status: requested
priority: Should Have
owner: PO
brief_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Problem
Google Sign-In is the only way in. ADR 0002 named Telegram as the fallback "if Google Sign-In proves
unacceptable for donor sign-up," and left that as an open question rather than a build item. Facebook
was never evaluated at all. Sothea (PO) wants both added for donors — no specific sign-up failure
reported yet, but Facebook is common in Cambodia and worth covering.

## Desired outcome
A donor who does not want to use a Google account can sign up with Facebook or through a Telegram
bot instead, and reach the same `DONOR`/`REQUESTER` account shape everything else in the app already
expects — this adds identity-proof options, it does not change what an account is.

## Why
Coverage, not urgency — see "why not now" below. Deferred explicitly to protect M7 (Play Store
release, due the week of 2026-08-24 per `CLAUDE.md`), not because it lacks merit.

### Why not now
Two unrelated pieces of work hiding under one request:

- **Facebook Login** needs a Meta Developer App and, depending on the permissions requested, Meta's
  own App Review — a timeline this team does not control, from days to weeks. Starting it risks
  blocking M7 on an external party.
- **Telegram** is not OAuth here — Telegram has no "Sign in with Telegram" for this shape of app.
  Per ADR 0002 it means a **bot-driven OTP**: generate a code, send it via the bot, verify what the
  donor types back. That is the full code-generation / expiry / rate-limiting / brute-force path ADR
  0002 chose Google Sign-In specifically to avoid — free, but not smaller.

Decided 2026-08-23 (Sothea): build neither until after M7 ships.

## Scope
**In (post-M7):**
- Facebook: Meta Developer App + review kicked off; a `FacebookTokenVerifier` mirroring
  `GoogleTokenVerifier`'s shape; a second sign-in button.
- Telegram: bot registration; server-side OTP generation, expiry, resend cooldown, and
  rate-limiting (`FR-AUTH-002`'s retired scope, reintroduced for this one path only); a phone or
  Telegram-handle entry step.
- A TM-AUTH-001-style threat model per new provider — S1/S2 (client-asserted identity, audience/
  issuer checks) do not automatically carry over from Google's.

**Out:**
- Any of the above before M7 ships.
- Extending either provider to `HOSPITAL`/`ADMIN` sign-in — donors only, per the request.

## Acceptance criteria
- [ ] Not scheduled. Revisit after M7 and re-open this document with real acceptance criteria once
      a milestone is assigned.
