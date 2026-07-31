---
id: FR-REQUEST-001-create-urgent-request
title: Create urgent blood request
area: REQUEST
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-04
---

## Problem
Today a family needing blood writes a Facebook post and hopes. There is no structured way to say
what is needed, where, and how urgently — so nothing downstream can act on it automatically.

## Desired outcome
A frightened family member, or hospital staff on their behalf, can post a specific need in under a
minute: blood type, units, hospital, urgency. Posting it is enough — matching and alerting happen on
their own. The requester can cancel it or mark it fulfilled.

## Why
This is the demand side and the trigger for the entire matching chain. `prd.md` section 1 targets a
median under 30 minutes from request creation to first acceptance; that clock starts here.

The one-minute goal is a real design constraint, not a nice-to-have. The person filling this form is
frightened and possibly in a hospital corridor. Anything optional should be absent.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/REQUEST-create-urgent/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-04 and are not duplicated here. Note that FR-04 defines a
status `expired` whose rule does not exist yet — that is `FR-REQUEST-005`, not this FR.

- [ ] <to be filled after prototyping>
