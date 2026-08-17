---
id: 0003-donor-location-precision
title: Donor location precision — how much of a donor's location we store
status: accepted
date: 2026-08-07
deciders: Tech Lead (also holding PO and Security)
unblocks: V1__init.sql donor_profiles location columns; FR-MATCH-001 distance ranking
---

> **ACCEPTED 2026-08-07** as proposed, all three questions answered yes / 0.5 km / yes.
> Decided by Nem Sothea as Tech Lead. **Not an independent sign-off** — the same person holds PO and
> Security, so QA is the only outside gate. Moeun Nithvaraman was primary PO on this date and did not
> sign this; if the PO disagrees, it is a schema change, and after `V1__init.sql` merges that costs a
> second migration.
>
> Roster note (2026-08-17): PO moved to Sourn SAVOURN in the role rotation. Any re-review of this
> decision needs Sourn's signature, not Moeun's.

## Context

FR-MATCH-001 ranks matched donors by distance. At the time of this decision `donor_profiles` had **no
location columns at all** — deliberately, per `backend-spring.md` "Blocked schema decisions". Two
shapes were on the table:

- **Exact coordinates** — accurate ranking, but a continuously updated precise home location for a
  person whose blood type we also store. Together that is a health record with a map pin on it.
- **District centroid** — Phnom Penh has 14 districts; every donor in one collapses to a single point.
  Safe, and useless for ranking: a donor 800 m away and one 6 km away sort identically.

Neither is acceptable on its own. The framing was a false choice.

## Decision

Store both, at different precisions, and never return the precise one.

| Column | Type | Purpose |
|---|---|---|
| `district_code` | `VARCHAR(16) NOT NULL` | display, coarse filtering, the only location ever shown to another user |
| `latitude` | `NUMERIC(8,5) NULL` | distance ranking only |
| `longitude` | `NUMERIC(8,5) NULL` | distance ranking only |

Three constraints make this different from "just store coordinates":

1. **`NUMERIC(8,5)` — about 1 m resolution, deliberately not the `NUMERIC(9,6)` used for hospitals.**
   Hospital locations are public facts. A donor's is not. Sub-metre precision on a person's home
   address has no matching value and is strictly extra exposure.
2. **Coordinates never leave the backend.** No API response contains `latitude`/`longitude` for a
   donor — not to the portal, not to the requester, not to admin. Distance is returned pre-computed
   and **rounded to 0.5 km**; location is described by district name. Two donors 300 m apart are
   indistinguishable to a viewer, but still rank correctly internally.
3. **Coordinates are nullable and the app works without them.** A donor who declines the GPS
   permission still registers, still receives alerts for their district, and simply ranks after
   donors who can be ranked by distance. If declining GPS meant not being findable, the app would
   coerce consent.

Deletion follows PRD §6 account deletion — coordinates go with the profile row, no separate
retention.

## Consequences

Ranking accuracy is preserved. Exposure is bounded to "which of 14 districts", which is roughly what
a donor would tell a stranger on the phone anyway.

The cost is real and lands on Fullstack: every donor-facing DTO becomes an explicit allow-list, and
one careless entity serialisation leaks the coordinates. That is the same failure mode as
`TM-AUTH-001` finding I1 (donor contact before acceptance), so it should be one QA test case covering
both: *no donor endpoint ever returns latitude, longitude, or an unrounded distance.*

Also: no spatial index at M2. Distance ranking over a pilot-sized pool (1,000 donors, PRD §5) is fine
as a computed ordering; PostGIS or a geography column is an M4 optimisation if measurements say so,
not an M2 dependency.

## Alternatives considered

- **District centroid only** — rejected. Makes FR-MATCH-001's distance ranking decorative, and the
  PRD promises "nearby".
- **Exact coordinates, exposed** — rejected. Publishes home locations tied to health data.
- **Client-side distance** — rejected. Requires shipping every candidate donor's coordinates to a
  device, which is the exposure this proposal exists to prevent.

## Decided

| Question | Answer |
|---|---|
| Is district-level exposure of a donor's location acceptable? | **Yes** — district name is the finest location any other user sees |
| How coarsely is displayed distance rounded? | **0.5 km**, so repeated requests cannot triangulate a home address |
| May a donor register with no coordinates? | **Yes** — they receive district alerts and rank after distance-ranked donors. Declining GPS must never mean being unfindable |

`donor_profiles` location columns are unblocked; `V1__init.sql` can be written. Still open for M4 and
**not** covered by this ADR: the max-notified-donor count (FR-MATCH-001's second blocker).
