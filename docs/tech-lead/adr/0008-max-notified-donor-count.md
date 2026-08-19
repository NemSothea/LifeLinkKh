---
id: 0008-max-notified-donor-count
title: A request notifies at most 25 donors, and only notified donors get a match row
status: accepted
date: 2026-08-19
deciders: Tech Lead
unblocks: FR-MATCH-001 (the last open brief before the M4 build), FR-NOTIFY-001
---

> **ACCEPTED 2026-08-19** as proposed, all four decisions unamended. Decided by Nem Sothea as Tech
> Lead. **Not an independent sign-off** — the same person holds Security and co-PO, so QA is the only
> gate outside. Three amendments were raised and declined at accept time: logging candidate count per
> request, showing the requester a units-needed vs accepted gap, and giving the O− fatigue
> consequence a post-M7 owner. None blocks the M4 build; each is a change request if it returns.

## Context

`FR-MATCH-001` is marked **blocked** on one open brief in `docs/po/briefs/roadmap.md`: FR-05 promises
a "configurable max notified count" and never gives a number. The other two matching blockers closed
on 2026-08-07 — location precision by [ADR 0003](0003-donor-location-precision.md), compatibility by
[ADR 0004](0004-abo-rh-compatibility-lookup-table.md). This is the last one, and nothing in M4 can be
built without it: the matching query needs a `LIMIT`, and `FR-NOTIFY-001` needs to know how many FCM
sends a single request can trigger.

The brief states the tension correctly — notification fatigue against fill rate — and the two failure
modes are not symmetric:

- **Too few notified.** The request goes unanswered. `prd.md` §1 asks that **≥ 70%** of urgent
  requests get at least one acceptance within 60 minutes, with a **median under 30 minutes**. A cap
  that misses that number fails the headline metric of the whole product.
- **Too many notified.** Donors learn that most alerts are not for them and stop reading any of them.
  That failure is slower, invisible in the first weeks, and unrecoverable inside a 15-week course —
  there is no second chance to re-earn a donor's attention.

Two facts bound the arithmetic. `prd.md` §1 targets **≥ 200 registered donors** in the first pilot
month; §5 sizes the system for 1,000. And the pilot has **no retry path**: `FR-MATCH-002`
(zero-match fallback with radius widening) and `FR-REQUEST-005` (expiry and re-notify) are both
deferred in `docs/scope.md`. Whoever is notified on the first pass is everyone who will ever be
notified for that request.

## Decision

**1. The cap is 25, and it is a flat number.**

`lifelink.matching.max-notified`, default `25`, overridable by the `MATCHING_MAX_NOTIFIED`
environment variable like every other tunable in `application.yml`.

The number comes from the metric, read pessimistically. If a single notified donor accepts with
probability `p`, then `P(at least one acceptance) = 1 - (1-p)^N`, and clearing the PRD's 70% bar
needs `N ≥ ln(0.30) / ln(1-p)`:

| Assumed per-donor acceptance rate | Donors needed for 70% |
|---|---|
| 15% | 8 |
| 10% | 12 |
| **5%** | **24** |

We have no measured acceptance rate — a Cambodian voluntary donor's response to a 03:00 push is
exactly the thing this pilot exists to find out. So the cap is set at the pessimistic end (5%,
rounded up to 25) rather than the plausible one. Under-notifying fails the headline metric; the
25th-ranked donor is still a compatible, eligible, available person within the radius, and the cost
of alerting them is one push.

**2. `units_needed` does not change the cap.** A three-unit request notifies 25 donors, the same as a
one-unit request. This is deliberate and it is a known gap: with a 5% acceptance rate, 25 notified
donors yield roughly one acceptance, not three. It is accepted because the PRD's acceptance criterion
is "at least one donor acceptance", every measured metric counts requests and not units, and the
pilot's answer to a partially-filled request is the same as its answer to an unfilled one — the
hospital telephones, exactly as it does today. Scaling the cap by units would add a knob that no
metric reads.

**3. Only notified donors get a `request_matches` row.** Candidates ranked 26th and below are not
written. `V1__init.sql` states the reasoning already — *"the match is the thing that has state
(notified, answered)"* — and a donor who was never contacted has no state. Writing every candidate
would make `request_matches` a query log, inflate every count QA and the defence SQL run against it,
and quietly leak a donor's availability into a table they never participated in.

**4. Ranking is deterministic.** Order by distance ascending with `NULLS LAST` per ADR 0003, then by
`donor_profiles.id` to break ties. Two donors at the same rounded distance must not swap places
between runs, or the same request re-run in a demo notifies a different 25 and nobody can explain why.

## Consequences

**The cap is a measurement, not a belief.** The pilot produces the acceptance rate directly:
`COUNT(*) FILTER (WHERE response = 'ACCEPTED') / COUNT(*) FILTER (WHERE notified_at IS NOT NULL)`
over `request_matches`. That is the same SQL-at-demo-time approach `docs/scope.md` adopted when
`FR-GLOBAL-002` was withdrawn. If the real rate lands near 15%, 25 is roughly three times what is
needed and the value should drop — which is one environment variable, no redeploy of code.

**O− donors will carry the fatigue.** They are compatible with every recipient type, so they are
candidates for every request in the pilot; a donor with a rare-but-universal type gets alerted far
more than a cap of 25 suggests. The cap does not fix this and no per-donor rate limit is in M4's
scope. QA should watch decline rates by blood type during the pilot — a rising O− decline rate is the
early signal, and it arrives long before donors uninstall.

**FCM cost is bounded and small.** Worst case per request is 25 sends. At pilot volume this is
nowhere near any FCM quota; the `≥ 95%` delivery metric in `prd.md` §1 is measured over notified
donors, so a smaller denominator does not flatter it.

**A request with fewer than 25 candidates notifies all of them.** The cap is a ceiling, never a
target — there is no padding with less-compatible or ineligible donors to reach 25.

## Alternatives considered

- **10, the "obvious small number".** Clears 70% only if the real acceptance rate is at least 12%.
  Betting the product's headline metric on an unmeasured optimism, with no retry path to recover
  from being wrong, for a saving of 15 push notifications.
- **Notify everyone in radius, no cap.** Directly contradicts FR-05, and in a 200-donor pool an O+
  request would alert most of the pool for a single unit of blood. Fastest possible route to donors
  muting the app.
- **Scale by `units_needed` (25 × units, ceiling 50).** Rejected under decision 3's reasoning — see
  above. Revisit only if the pilot shows multi-unit requests are common and are going unfilled.
- **Tier by urgency (CRITICAL notifies more).** Attractive and premature. It needs a measured
  baseline to tier *from*, and `urgency` currently drives nothing else in the system. Post-pilot.
