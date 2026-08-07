---
id: FR-NOTIFY-001-request-push-alert
title: Push alert for a matched request
area: NOTIFY
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-06
---

## Problem
Matching the right donors is worthless if they do not find out. A donor is not sitting in the app
waiting — they are at work, asleep, or driving. A blood emergency measured in minutes cannot rely on
someone opening an app of their own accord.

## Desired outcome
A matched donor's phone alerts them within seconds of the request being created, and tapping that
alert opens the request itself, ready to accept.

## Why
This is the single feature that justifies building a mobile app rather than a website. `CLAUDE.md`
section 1 says exactly that: a website cannot push a time-critical alert to a donor's phone.
`prd.md` section 5 requires under 10 seconds from request to first notification.

**Moved to M4 by DEC-002** (`../../decisions.md`). FR-04's acceptance criteria say that on request
creation "matching + notification runs automatically", and request creation is M4 — but `CLAUDE.md`
section 4 originally scheduled FCM in M5, which would have closed M4 with FR-04's own criteria unmet.
This FR now lands in M4, and **FCM token registration moves earlier still, into M3** with
`FR-DONOR-001`, so M4 adds a send path to tokens that already exist rather than building the whole
integration under pressure. `FR-NOTIFY-002`'s reminder push stays in M5.

Never cut this FR to relieve M4 — see the cut order in `../../risks.md`. Dropping it returns to the
unmet-criteria problem DEC-002 exists to avoid.

**Scope correction.** FR-06's third acceptance criterion in `prd.md` covers reminder notifications
when a donor becomes eligible again. That belongs to `FR-NOTIFY-002`, not here. This FR is the urgent
request alert only.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/NOTIFY-donor-alert/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-06, excluding the eligibility-reminder criterion, which is
`FR-NOTIFY-002`.

- [ ] <to be filled after prototyping>
