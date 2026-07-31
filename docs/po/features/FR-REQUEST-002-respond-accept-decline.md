---
id: FR-REQUEST-002-respond-accept-decline
title: Respond to a request — accept or decline
area: REQUEST
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-07
---

## Problem
An alerted donor has no way to say "I am coming", and the family has no way to know whether anyone
is. Both sides sit in silence during the exact minutes that matter. Meanwhile the donor cannot reach
the hospital because they were never told which one, and the family cannot reach the donor because
handing out a stranger's phone number to everyone alerted would be indefensible.

## Desired outcome
A donor accepts or declines from the request itself. Accepting reveals the hospital and contact
details to that donor and puts them on a list the requester and hospital can see, with a phone
number they can call. Declining costs nothing and closes the loop quietly.

## Why
Acceptance is the product's actual unit of success — `prd.md` section 1 measures 70% of requests
accepted within 60 minutes and a median under 30 minutes. Without this feature there is nothing to
measure.

It is also where the privacy model is enforced. `prd.md` section 6 permits donor contact to be
exposed only once that donor accepts. That rule lives in this feature; getting it wrong exposes phone
numbers of everyone who was merely notified.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/NOTIFY-donor-alert/ and
../prototypes/mobile/REQUEST-responders-list/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-07 and are not duplicated here.

- [ ] <to be filled after prototyping>
