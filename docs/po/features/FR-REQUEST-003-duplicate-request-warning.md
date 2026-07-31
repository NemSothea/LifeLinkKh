---
id: FR-REQUEST-003-duplicate-request-warning
title: Warn on duplicate open request
area: REQUEST
status: requested
priority: Should Have
owner: PO
brief_ref: ../prd.md — section 7, error / edge cases
---

## Problem
A panicking family will post the same need twice — the first post seemed to do nothing, so they try
again. Each duplicate re-alerts the same donors for the same patient. Donors read two identical
pushes, assume the app is broken or spamming them, and start ignoring alerts. The 95% delivery rate
in `prd.md` section 1 becomes meaningless if donors have learned to swipe alerts away.

## Desired outcome
Before a second identical open request is created, the requester is shown the one they already have
and offered it instead. Creating a genuine second request stays possible — the warning informs, it
does not block.

## Why
`prd.md` section 7 requires it: "system warns if an identical open request exists." Nothing in FR-04
does this.

The cost of getting it wrong is asymmetric and permanent. Notification fatigue is not recoverable
inside a 13-week pilot — once a donor stops trusting alerts, no later feature wins them back. Cheap
to build, expensive to omit.

Priority **proposed** as Should Have.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
