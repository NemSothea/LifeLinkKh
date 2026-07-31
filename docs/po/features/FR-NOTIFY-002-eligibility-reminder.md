---
id: FR-NOTIFY-002-eligibility-reminder
title: Eligibility reminder when cooldown ends
area: NOTIFY
status: accepted
priority: Should Have
owner: PO
brief_ref: ../prd.md — FR-09
---

## Problem
Fifty-six days is long enough to forget. A donor who gave once, meant to give again, and heard nothing
for two months quietly stops being a donor. The app knows the exact day they became eligible and says
nothing.

## Desired outcome
On the day a donor's cooldown ends, their phone tells them they can give again. Their status flips to
eligible on its own and they re-enter matching without doing anything.

## Why
Repeat donors are cheaper than new ones. `prd.md` section 1 targets 50 hospital-verified donations
from 200 donors in a single pilot semester — that arithmetic only works if people donate more than
once, and this is the only feature that asks them to.

It also closes the loop that `FR-DONOR-002` opens: computing eligibility silently helps the system,
but telling the donor is what produces another donation.

**Scope note.** `prd.md` FR-06's third acceptance criterion also describes this reminder. It is
assigned here, not to `FR-NOTIFY-001`, so the two features do not both claim it.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/NOTIFY-eligibility-reminder/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-09, plus FR-06's reminder criterion, and are not duplicated
here.

- [ ] <to be filled after prototyping>
