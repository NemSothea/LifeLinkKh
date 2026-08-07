---
id: FR-AUTH-001-phone-otp-auth
title: Phone authentication via OTP
area: AUTH
status: superseded
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-01
superseded_by: FR-AUTH-003-google-sign-in
superseded_date: 2026-08-07
---

> **SUPERSEDED 2026-08-07 by [FR-AUTH-003](FR-AUTH-003-google-sign-in.md).**
> Auth moved from phone OTP to Google Sign-In: SMS costs money per message on the one path every
> user must cross, and OTP put code generation, expiry, brute-force defence and resend limiting into
> our own code. Rationale and rejected alternatives in
> [ADR 0002](../../tech-lead/adr/0002-auth-google-sign-in.md).
> Kept for history — do not build against this FR. The Problem statement below still holds; only the
> mechanism changed.

## Problem
A donor in an emergency cannot be reached unless they have an account, but asking a Cambodian
volunteer to invent and remember a password creates a barrier at exactly the wrong moment. There is
also no way to know an account belongs to a reachable human — and the entire product depends on
being able to phone that person when blood is needed.

## Desired outcome
Anyone can create an account and sign in with only their phone number and a code sent to it. The
account is provably tied to a working Cambodian number, and the app holds a session afterwards
without asking again.

## Why
Every other feature depends on identity. Matching, notifications, donation history, and the privacy
rule that hides donor contact until acceptance all need a known user. Nothing ships before this.

Open question, not blocking: hospital and admin sign-in may not use the donor mechanism at all — see
the portal sign-in question in `docs/fullstack/specs/foundation/frontend-nextjs.md`. That question
moved to `FR-AUTH-004` when `FR-AUTH-003` was allocated to Google Sign-In.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/AUTH-otp-signin/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-01 and are not duplicated here. Finalize this section after
the prototype settles the flow.

- [ ] <to be filled after prototyping>
