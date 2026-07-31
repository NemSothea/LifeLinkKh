---
id: FR-MATCH-001-donor-matching
title: Donor matching by compatibility and distance
area: MATCH
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-05
---

## Problem
A Facebook post reaches whoever happens to scroll past — mostly people with the wrong blood type, in
the wrong city, or who donated last month. The people who could actually help never see it. Reach
without targeting is not reach.

## Desired outcome
When a request is created, the system finds the donors who could genuinely answer it — ABO/Rh
compatible, currently eligible, marked available — and ranks them by how close they are. Only those
donors are alerted, and only as many as is sensible.

## Why
This is the feature that replaces hope with a query, and the reason a mobile app is justified at all.
Everything in `prd.md` section 1 — the 30-minute median, the 70% acceptance rate — depends on the
right donors being reached first.

Compatibility is not exact-type matching. `prd.md` section 9 is explicit: an O− donor can help
almost anyone, an AB+ patient can receive from anyone. Matching on exact type alone would discard
most of the available supply.

**Blocked on two open briefs** in `../briefs/roadmap.md`:
- **Location precision** — exact coordinates or district centroid. Distance ranking cannot be
  specified until this is decided, and it is simultaneously a privacy decision.
- **Max notified count** — FR-05 calls it configurable but gives no default. Too few and the request
  goes unanswered; too many and donors learn to ignore alerts.

Both must be resolved before M4 build.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-05 and are not duplicated here.

- [ ] <to be filled after prototyping>
