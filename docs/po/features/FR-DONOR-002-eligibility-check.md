---
id: FR-DONOR-002-eligibility-check
title: Eligibility check — cooldown between donations (90 days men, 120 women; DEC-019)
area: DONOR
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-03
---

> **Amended 2026-09-29 by DEC-019 (`../../decisions.md`).** The cooldown is no longer 56 days for
> everyone, which is the US rule. It is **90 days for men and 120 days for women**, from the
> donor's optional `sex` field; a donor who prefers not to say, or a profile saved before the field
> existed, gets 120. Cambodian blood centres reportedly ask for 3 and 4 months, and WHO's minimums are
> 12 and 16 weeks (`../research/2026-09-cambodia-donation-reality.md` §3). Implemented twice, with a
> boundary test each: `mobile/.../donor/domain/eligibility.dart` and `frontend/src/server/matching.js`.
> The criteria below keep their original wording; read "56 days" as "the donor's interval".

## Problem
A donor who gave blood three weeks ago cannot give again, but neither they nor the system knows that
without doing the arithmetic. Alerting an ineligible donor wastes an urgent notification, and a
donor who shows up and is turned away at the hospital is a donor who does not come back.

## Desired outcome
The system knows, without being asked, whether each donor may donate today. Ineligible donors are
silently left out of matching. A donor can see their own status and the exact date they become
eligible again.

## Why
This is the filter that makes every alert credible. FR-05 matching states plainly that only eligible
donors are matched, so matching cannot be correct until eligibility is computable.

**Split across two milestones by DEC-001** (`../../decisions.md`). `CLAUDE.md` section 4 originally
scheduled the 56-day cooldown in M5, but matching lands in M4 and depends on it. The **computation**
now sits in M4 with matching; the **donor-facing status display** stays in M5 with donation history.
QA should verify the M4 half through matching results, not through a screen — there is no screen until
M5.

Depends on the walk-in-donation question in `../briefs/roadmap.md`: whether a donation recorded
without a linked request counts toward the cooldown. The 56-day arithmetic is only as trustworthy as
the donation records feeding it.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/DONOR-eligibility-status/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-03 and are not duplicated here.

- [ ] <to be filled after prototyping>
