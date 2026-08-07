---
id: FR-MATCH-002-zero-match-fallback
title: No-donors-found handling
area: MATCH
status: deferred
priority: Should Have
owner: PO
brief_ref: ../briefs/roadmap.md — zero-match fallback (open brief)
---

> **DEFERRED 2026-08-07 by the scope cut (DEC-004).** Not cancelled, not built. See
> [`docs/scope.md`](../../scope.md) for what was cut and why, and treat this FR as documented
> future work for the project defence.
>
> **Why this one:** Real mitigation for low donor density, but it needs radius widening and retry logic. During the pilot a zero-match is handled by telling the requester none were found.

## Problem
Early in a pilot, most requests will match nobody — there simply are not enough registered donors in
range yet. As specified, the requester gets silence: no donors alerted, no message, no indication the
app did anything. A family in an emergency staring at a screen that says nothing will go back to
Facebook and never return.

## Desired outcome
When nothing matches, the requester is told so honestly and immediately, the search widens rather
than stopping, and the hospital is brought in — because hospital staff have options a family does
not.

## Why
`prd.md` section 7 already describes this — the requester "is told none found now; system widens
radius or retries; hospital notified" — but FR-05's criteria stop at ranking matched donors. Nothing
covers the empty result, which during the pilot is the *most likely* result.

This is also the direct mitigation for the top risk in `docs/risks.md`: low donor density early.
The feature that handles zero matches gracefully is what keeps the product credible while the donor
base is still being built.

**Blocked on the zero-match-fallback brief** in `../briefs/roadmap.md`. Undecided: how far the radius
widens, how often it retries, and when it gives up.

Priority **proposed** as Should Have — arguably Must Have during the pilot, since it is the common
path, not the edge case. Worth revisiting when the brief is decided.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/MATCH-no-donors-found/>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
