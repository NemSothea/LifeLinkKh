---
id: FR-PORTAL-002-admin-dashboard
title: Admin dashboard (web)
area: PORTAL
status: deferred
priority: Should Have
owner: PO
brief_ref: ../prd.md — FR-11
---

> **DEFERRED 2026-08-07 by the scope cut (DEC-004).** Not cancelled, not built. See
> [`docs/scope.md`](../../scope.md) for what was cut and why, and treat this FR as documented
> future work for the project defence.
>
> **Why this one:** A second web surface with charts. FR-PORTAL-001's request list already satisfies the Next.js requirement.

## Problem
Nobody can onboard a hospital, disable a compromised account, remove an abusive request, or say
whether the platform is working. Every one of those is a manual database edit today, which means it
does not happen.

## Desired outcome
An operator can create and disable hospital and staff accounts, remove abusive requests or users, and
see whether the product is meeting the numbers it promised.

## Why
Hospitals cannot self-register — `prd.md` section 2 has their accounts provisioned by an admin — so
without this feature the portal has no users at all. Moderation is also the second half of the
false-request mitigation in `prd.md` section 8, alongside hospital confirmation.

**Hard dependency.** FR-11 requires the admin to view the success metrics from `prd.md` section 1, but
no feature currently records the events those metrics are computed from. That is
`FR-GLOBAL-002-metrics-instrumentation`, and this FR's metrics half cannot be built before it. Without
that, this becomes an account-management screen with an empty dashboard.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/web/PORTAL-admin-dashboard/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-11 and are not duplicated here.

- [ ] <to be filled after prototyping>
