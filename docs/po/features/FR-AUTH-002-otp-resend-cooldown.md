---
id: FR-AUTH-002-otp-resend-cooldown
title: OTP resend with cooldown
area: AUTH
status: retired
priority: Should Have
owner: PO
brief_ref: ../prd.md — section 7, error / edge cases
retired_date: 2026-08-07
retired_reason: no OTP to resend — auth moved to Google Sign-In (FR-AUTH-003)
---

> **RETIRED 2026-08-07.** This FR existed only to make phone OTP safe and affordable. Auth moved to
> Google Sign-In ([FR-AUTH-003](FR-AUTH-003-google-sign-in.md), [ADR 0002](../../tech-lead/adr/0002-auth-google-sign-in.md)),
> so there is no code to resend, no SMS budget to drain, and no cooldown to design.
> Never approved, never built. Kept for history.

## Problem
SMS in Cambodia is not reliably instant. A donor who never receives the code has no way forward and
abandons registration. Without a cooldown the opposite failure appears: a user taps resend
repeatedly, each tap costs money, and an attacker can drain the SMS budget or flood a stranger's
phone.

## Desired outcome
A user who did not get the code can request another one after a short, visible wait, and knows how
long that wait is. Repeated requests within the window are refused cheaply, before an SMS is sent.

## Why
`prd.md` section 7 requires this — "allow resend after a short cooldown" — but FR-01's criteria only
cover rejecting a wrong or expired code, never getting a replacement. Registration is where donors
are won or lost, and this is also the only control standing between the SMS budget and the
deliverability risk named in `prd.md` section 8.

Priority **proposed** as Should Have: FR-01 technically works without it, but a pilot with real
donors will not.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/AUTH-otp-signin/>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
