---
id: FR-MATCH-001-donor-matching
title: Donor matching by compatibility and distance
area: MATCH
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-05
---

## Problem
A Facebook post reaches whoever happens to scroll past — mostly people with the wrong blood type, in
the wrong city, or who donated last month. The people who could actually help never see it. Reach
without targeting is not reach.

## Desired outcome
When a request is created, the system finds the donors who could genuinely answer it — ABO/Rh
compatible, currently eligible, marked available — and ranks them by how close they are. Only those
donors are alerted, and only as many as is sensible.

## Why
This is the feature that replaces hope with a query, and the reason a mobile app is justified at all.
Everything in `prd.md` section 1 — the 30-minute median, the 70% acceptance rate — depends on the
right donors being reached first.

Compatibility is not exact-type matching. `prd.md` section 9 is explicit: an O− donor can help
almost anyone, an AB+ patient can receive from anyone. Matching on exact type alone would discard
most of the available supply.

**No longer blocked.** All three blockers are resolved — the M4 build can start.

Resolved 2026-08-19:
- **Max notified count** — [ADR 0008](../../tech-lead/adr/0008-max-notified-donor-count.md).
  **25**, flat, configurable via `MATCHING_MAX_NOTIFIED`. Set at the pessimistic end of the
  acceptance-rate range so the PRD's 70%-within-60-minutes target survives an unmeasured donor
  population. `units_needed` does not scale it. Only notified donors get a `request_matches` row.
  Ranking is deterministic: distance ascending `NULLS LAST`, then `donor_profiles.id`.

Resolved on 2026-08-07:
- **Location precision** — [ADR 0003](../../tech-lead/adr/0003-donor-location-precision.md).
  Rank on coarse coordinates the API never returns; show district and a distance rounded to 0.5 km.
  Donors with no coordinates still match and sort `NULLS LAST`.
- **Compatibility rule** — [ADR 0004](../../tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md).
  A seeded 27-row `blood_compatibility` table, joined in the matching query, not branching code.

## Scope

**In:**
- Matching runs automatically on request creation — never a separate call the client can forget.
- Candidate filter, all four conditions, `AND`-ed: ABO/Rh compatible with `patient_blood_type` via
  the seeded `blood_compatibility` join (ADR 0004); `is_available = true`; eligible under the 56-day
  cooldown (`FR-DONOR-002` computation half); within the 10 km radius when coordinates exist.
- Ranking by distance ascending, `NULLS LAST`, tie-broken by `donor_profiles.id` (ADR 0003, ADR 0008).
- Top 25 candidates are written to `request_matches` and handed to `FR-NOTIFY-001` (ADR 0008).
- A donor with no coordinates still matches and sorts last — declining GPS must never cost a match.

**Out:**
- Widening the radius or retrying on zero matches — `FR-MATCH-002`, deferred in `../../scope.md`.
- Re-matching an already-created request. Matching runs once, at creation.
- Scaling the cap by `units_needed`, or by `urgency` — both declined in ADR 0008.
- Returning `latitude`/`longitude`, or an unrounded distance, in any response (ADR 0003).

## Acceptance criteria
Criteria live in `../prd.md` under FR-05 and are not duplicated here.

- [ ] An incompatible donor is never matched — verified against all 8 recipient types, not just one.
- [ ] An ineligible donor (donated < 56 days ago) is never matched, even if available and nearby.
- [ ] An unavailable donor (`is_available = false`) is never matched.
- [ ] With 30 qualifying candidates, exactly 25 `request_matches` rows exist; the 26th-ranked donor
      has no row at all.
- [ ] With fewer than 25 qualifying candidates, every one of them is matched — the cap never pads.
- [ ] The same request matched twice produces the same 25 donors in the same order.
- [ ] A donor with `latitude`/`longitude` NULL is matched and sorts after every ranked donor.
- [ ] No response body from any endpoint in this FR contains `latitude`, `longitude`, or a distance
      that is not rounded to 0.5 km (shared test case with `TM-AUTH-001` finding I1, per ADR 0003).
