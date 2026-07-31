---
id: FR-DONATION-001-donation-history
title: Donation history
area: DONATION
status: accepted
priority: Should Have
owner: PO
brief_ref: ../prd.md — FR-08
---

## Problem
A donor gives blood and the app forgets. They cannot see what they have done, nobody has confirmed it
happened, and — worst — the system has no idea when they last donated, so the 56-day cooldown is
computed from a date nobody maintains.

## Desired outcome
Every completed donation is recorded with its date and hospital, confirmed by hospital staff, and
linked to the request it answered where there was one. The donor sees their own record. Completing a
donation updates the date that eligibility depends on.

## Why
Two reasons, one emotional and one mechanical.

`prd.md` FR-08's own user story is about a donor feeling their impact — a volunteer giving blood for
free deserves to see the count, and that feeling is the retention mechanism for the whole product.

Mechanically, this is the only trustworthy source for the 56-day cooldown. `FR-DONOR-002` computes
eligibility from the last donation date, and hospital confirmation is what makes that date real rather
than self-reported.

Depends on the walk-in-donation question in `../briefs/roadmap.md`: whether a donation with no linked
request counts toward the cooldown, and who records it.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/DONATION-history/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-08 and are not duplicated here.

- [ ] <to be filled after prototyping>
