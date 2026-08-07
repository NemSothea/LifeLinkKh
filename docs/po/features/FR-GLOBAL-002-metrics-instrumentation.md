---
id: FR-GLOBAL-002-metrics-instrumentation
title: Success-metric event capture
area: GLOBAL
status: deferred
priority: Must Have
owner: PO
brief_ref: ../prd.md — section 1, success metrics
---

> **DEFERRED 2026-08-07 by the scope cut (DEC-004).** Not cancelled, not built. See
> [`docs/scope.md`](../../scope.md) for what was cut and why, and treat this FR as documented
> future work for the project defence.
>
> **Why this one:** Event capture across M3-M5 plus a dashboard. Replaced by running SQL COUNT queries against the live pilot data at demo time - same numbers for the defence, none of the instrumentation.

## Problem
`prd.md` section 1 commits to five numbers, and the product cannot compute a single one of them. There
is no record of when a request was created versus when the first donor accepted, so the 30-minute
median is unknowable. Nothing captures whether a push was actually delivered, so the 95% delivery
target is unmeasurable. The 60-minute acceptance rate needs both timestamps and neither exists as a
tracked event.

FR-11 promises an admin can view these metrics. It cannot, because nothing writes them down.

## Desired outcome
The events the promised metrics are computed from are recorded as they happen — request created, donors
notified, push delivered or failed, first acceptance, donation confirmed. The section 1 numbers become
a query rather than a guess.

## Why
This is the difference between a project that claims impact at its defence and one that can show it.
The success metrics are the stated basis for judging whether LifeLink KH worked; a pilot that ends with
no evidence has no answer to the only question that matters.

It is also a hard dependency of `FR-PORTAL-002`. Instrumentation must be in place *before* the
milestones it measures, not bolted on at the end — events not captured during M3 to M5 are gone. Push
delivery receipts in particular can only come from FCM at the moment of sending, which means the work
lands with `FR-NOTIFY-001`, not after it.

Priority **proposed** as Must Have. Every other Must Have delivers user value; this one is the only
proof any of them did.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
