---
id: FR-REQUEST-005-request-expiry
title: Request expiry rule
area: REQUEST
status: requested
priority: Should Have
owner: PO
brief_ref: ../briefs/roadmap.md — request expiry rule (open brief)
---

## Problem
Requests never end. A need from three weeks ago — long since met, or the patient long since
discharged — still sits open, still counts as unfulfilled, and still appears to hospital staff as
something to act on. Donors who look at old requests cannot tell which are real.

## Desired outcome
An open request that nobody fulfils closes itself after a defined period, and the requester and
hospital know it happened. Anyone looking at the list is looking at live needs only.

## Why
FR-04's acceptance criteria already declare a status `expired`, but define no rule that sets it. The
initial schema in `docs/fullstack/specs/foundation/backend-spring.md` therefore ships `EXPIRED` as a
value nothing can ever assign — a dead status is a promise the product does not keep.

It also corrupts the metrics. `prd.md` section 1 measures the share of requests receiving an
acceptance; requests that should have expired sit in the denominator forever and drag that number
down permanently.

**Blocked on the request-expiry brief** in `../briefs/roadmap.md`. Undecided: how long an open
request lives, whether urgency level changes that, and who is notified on expiry. Resolve before M4 —
it shapes the `BloodRequest` state machine and a later Flyway migration.

Priority **proposed** as Should Have.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
