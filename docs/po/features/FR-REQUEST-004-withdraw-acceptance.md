---
id: FR-REQUEST-004-withdraw-acceptance
title: Donor withdraws acceptance
area: REQUEST
status: deferred
priority: Should Have
owner: PO
brief_ref: ../briefs/roadmap.md — withdrawn acceptance (open brief)
---

> **DEFERRED 2026-08-07 by the scope cut (DEC-004).** Not cancelled, not built. See
> [`docs/scope.md`](../../scope.md) for what was cut and why, and treat this FR as documented
> future work for the project defence.
>
> **Why this one:** Withdrawal can be handled by phone between donor and requester during the pilot. Building the state transition, the re-notify path, and the UI is a week for an edge case.

## Problem
A donor accepts in good faith, then cannot go — traffic, work, a change of mind. Right now their
acceptance stands forever, so the family stops looking, believing help is on the way. A false
acceptance is worse than a decline: it stops the search.

## Desired outcome
A donor who has accepted can withdraw, and the requester and hospital are told immediately so they
resume looking. Withdrawing carries no penalty — the alternative is a donor who stays silent and
simply never arrives.

## Why
`prd.md` section 7 already describes this behaviour — "donor can withdraw acceptance; requester
notified" — but no FR owns it, and `docs/fullstack/specs/foundation/backend-spring.md` already carries
a `WITHDRAWN` response value with no requirement behind it. A column with no feature is a gap waiting
to be filled by a guess.

**Blocked on the withdrawn-acceptance brief** in `../briefs/roadmap.md`. The open question is whether
withdrawal is its own feature or folded into `FR-REQUEST-002`, and whether withdrawal re-triggers
matching to find a replacement.

Priority **proposed** as Should Have.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
