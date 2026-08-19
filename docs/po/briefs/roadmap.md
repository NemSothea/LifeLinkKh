# Brief Roadmap

Which briefs get written when, and what each must resolve before its FR can be finalized.

Milestone dates are **not** repeated here — root `CLAUDE.md` section 4 owns the M1..M7 table.
This file only says *what PO thinking is due by which milestone*.

## Next brief number (per area)

Bump when you claim one.

| Area | Next |
|---|---|
| AUTH | 001 |
| DONOR | 001 |
| REQUEST | 001 |
| MATCH | 001 |
| DONATION | 001 |
| NOTIFY | 001 |
| PORTAL | 001 |
| GLOBAL | 001 |
| SECURITY | 001 |
| MOBILE | 001 |

## Registry

| ID | Title | Area | Milestone | Status | FR |
|---|---|---|---|---|---|
| _(none yet)_ | | | | | |

## Backlog — briefs due before their milestone builds

FR-01..FR-12 in [`../prd.md`](../prd.md) are already scoped, so they do **not** need briefs.
These are the gaps that do — each one is an unresolved product decision that blocks or
weakens an FR.

### Due before M4 (urgent request + matching) — all three closed 2026-08-19

**Nothing here blocks the M4 build any more.**

- ~~**Request expiry rule**~~ — **closed as deferred.** `FR-REQUEST-005` is cut in `../../scope.md`.
  `status = 'EXPIRED'` stays the dead value `V1__init.sql` already documents; open requests are
  closed manually. The `BloodRequest` state machine is OPEN → FULFILLED | CANCELLED and nothing sets
  EXPIRED. If the FR ever returns, it returns with a timer decision first.
- ~~**Zero-match fallback**~~ — **closed as deferred.** `FR-MATCH-002` is cut in `../../scope.md`.
  The 10 km radius does not widen and matching does not retry; a zero-match is reported to the
  requester as "no donors found". Matching logic is unblocked on that basis.
- ~~**Max-notified count**~~ — **resolved.**
  [ADR 0008](../../tech-lead/adr/0008-max-notified-donor-count.md) — **25**, flat, configurable via
  `MATCHING_MAX_NOTIFIED`. `units_needed` deliberately does not scale it. Only notified donors get a
  `request_matches` row, and ranking is deterministic (distance `NULLS LAST`, then donor id).

### Due before M5 (history + cooldown + push)

- **Withdrawn acceptance** — PRD flow says a donor "can withdraw acceptance", but no FR
  covers it. Either promote to an FR or fold into `FR-07`.
- **Donation without a request** — `FR-08` links a donation to a request optionally. Needs a
  decision on whether walk-in donations count toward the 56-day cooldown and who records them.

### Due before M6 (GPS, i18n, portal polish)

- **Availability toggle as its own behaviour** — currently buried in `FR-02` acceptance
  criteria. Needs its own thinking if it grows (auto-unavailable after N declines? scheduled
  unavailability?). Drop the brief if it stays a plain boolean.
- **Location precision vs. privacy** — PRD section 6 calls precise location sensitive but
  matching ranks by distance. Needs a decision on stored precision (exact lat/lng vs.
  district centroid) before `geolocator` work lands. Coordinate with `docs/security/`.

### Post-pilot (no milestone yet)

Out-of-scope items from `../prd.md` section 2.2 that will need briefs if they return:
in-app chat, hospital blood inventory, national health-system integration, iOS release,
automated donor verification.

## Cadence

- A brief must be `promoted` or `dropped` **before** its milestone's build week starts —
  a brief still `open` when coding begins means the FR gets built on a guess.
- Review this backlog at each milestone boundary; move anything newly urgent up.
- New product ideas arrive as briefs here first, never as a direct FR.
