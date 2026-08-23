---
id: FR-AUTH-004-additional-sign-in-providers
title: Facebook and Telegram sign-in for donors
area: AUTH
status: accepted
priority: Must Have
owner: PO
brief_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Problem
Google Sign-In is the only way in. ADR 0002 named Telegram as the fallback "if Google Sign-In proves
unacceptable for donor sign-up," and left that as an open question rather than a build item. Facebook
was never evaluated at all. Google-only is a real sign-up barrier for this donor population — Facebook
and Telegram both see more everyday use in Cambodia than Google does.

## Desired outcome
A donor who does not want to use a Google account can sign up with Facebook or through a Telegram
bot instead, and reach the same `DONOR`/`REQUESTER` account shape everything else in the app already
expects — this adds identity-proof options, it does not change what an account is.

## Why
Coverage that matters now, not a nice-to-have — see `changelog.md` 2026-08-23. First written and
deferred to post-M7 the same day, then reversed: the reach argument (most of the target donor
population signs in with Facebook or Telegram day to day) outweighs the M7 scheduling risk, which
still exists and is managed by splitting the work below rather than by waiting it out.

### The M7 conflict, and how it's split
Two unrelated pieces of work hiding under one request, neither of which is small:

- **Facebook Login** needs a Meta Developer App and, depending on the permissions requested, Meta's
  own App Review — a timeline this team does not control, from days to weeks.
- **Telegram** is not OAuth here — Telegram has no "Sign in with Telegram" for this shape of app.
  Per ADR 0002 it means a **bot-driven OTP**: generate a code, send it via the bot, verify what the
  donor types back. That is the full code-generation / expiry / rate-limiting / brute-force path ADR
  0002 chose Google Sign-In specifically to avoid — free, but not smaller.

So the work is sequenced, not raced against M7:

1. **Now, account-level, no code, Sothea's own action:** register the Meta Developer App and submit
   for App Review; create the Telegram bot via @BotFather. Starting the external clock costs nothing
   and blocks nothing.
2. **After step 1 has something to integrate against:** the actual client/backend work below,
   sequenced around M7 rather than squeezed in before it.

## Scope
**In:**
- Facebook: `FacebookTokenVerifier` mirroring `GoogleTokenVerifier`'s shape; a second sign-in
  button.
- Telegram: server-side OTP generation, expiry, resend cooldown, and rate-limiting (`FR-AUTH-002`'s
  retired scope, reintroduced for this one path only); a phone or Telegram-handle entry step.
- A TM-AUTH-001-style threat model per new provider — S1/S2 (client-asserted identity, audience/
  issuer checks) do not automatically carry over from Google's.

**Out:**
- Extending either provider to `HOSPITAL`/`ADMIN` sign-in — donors only, per the request.
- Any code landing in a way that jeopardizes M7 (Play Store release) — if the two conflict, M7 wins
  and this slips, not the reverse.

## Acceptance criteria
- [ ] Meta Developer App created and submitted for App Review (Sothea).
- [ ] Telegram bot created via @BotFather (Sothea).
- [ ] `FacebookTokenVerifier` verifies signature, `aud`, and token validity server-side — no
      client-supplied identity accepted (TM-AUTH-001 S1, mirrored for this provider).
- [ ] Telegram OTP path has expiry, a resend cooldown, and rate-limiting before it ships — not
      after (this is exactly the surface `FR-AUTH-002` existed for).
- [ ] Both providers produce only `DONOR`/`REQUESTER` accounts, same allow-list rule as Google
      (TM-AUTH-001 E1).
