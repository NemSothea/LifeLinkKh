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

**Blocked on one open brief** in `../briefs/roadmap.md`:
- **Max notified count** — FR-05 calls it configurable but gives no default. Too few and the request
  goes unanswered; too many and donors learn to ignore alerts.

Must be resolved before M4 build.

Two blockers were resolved on 2026-08-07:
- **Location precision** — [ADR 0003](../../tech-lead/adr/0003-donor-location-precision.md).
  Rank on coarse coordinates the API never returns; show district and a distance rounded to 0.5 km.
  Donors with no coordinates still match and sort `NULLS LAST`.
- **Compatibility rule** — [ADR 0004](../../tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md).
  A seeded 27-row `blood_compatibility` table, joined in the matching query, not branching code.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-05 and are not duplicated here.

- [ ] <to be filled after prototyping>
