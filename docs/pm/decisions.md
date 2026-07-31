# Decisions (DEC)
next: 004

| ID | Decision | Date |
|----|----------|------|
| DEC-001 | 56-day eligibility computation moves from M5 to M4 | 2026-07-31 |
| DEC-002 | FCM request-alert push moves from M5 to M4; FCM token registration moves to M3 | 2026-07-31 |
| DEC-003 | Metrics event capture is a per-milestone delivery requirement, not a milestone item | 2026-07-31 |

---

## DEC-001 — Eligibility computation moves to M4

**Date:** 2026-07-31 · **Decided by:** PO + PM (both held by Nem Sothea)

### Context
`CLAUDE.md` section 4 scheduled the 56-day cooldown in M5. `FR-MATCH-001` is an M4 feature and its
`prd.md` FR-05 acceptance criteria state that only eligible donors are matched. M4 as scheduled could
not satisfy its own criteria.

### Decision
The **computation** of eligibility lands in M4 alongside matching. The donor-facing eligibility
display and the reminder push stay in M5 with donation history.

`CLAUDE.md` section 4 amended: M4 gains "56-day eligibility computation", M5 keeps history and the
eligibility reminder.

### Why this and not the alternative
Moving `FR-MATCH-001` to M5 instead would have pushed the product's central feature into the same
milestone as history and push, leaving M4 with request creation alone. Eligibility computation is a
date comparison against `donations.donated_on` — the cheap half of the feature. The expensive half is
the UI and the scheduled reminder, and neither is needed to filter a matching query.

### Consequence
M4 grows. `FR-DONOR-002` now spans two milestones: computation at M4, donor-visible status at M5. QA
should test the M4 half through matching results, not through a screen — there is no screen yet.

---

## DEC-002 — Request-alert push moves to M4, token registration to M3

**Date:** 2026-07-31 · **Decided by:** PO + PM (both held by Nem Sothea)

### Context
`CLAUDE.md` section 4 scheduled FCM push in M5, but `prd.md` FR-04's acceptance criteria say that on
request creation "matching + notification runs automatically" — and request creation is M4. M4 as
scheduled would have delivered matching that alerts nobody.

### Decision
The **request-alert push** (`FR-NOTIFY-001`) moves to M4. The **eligibility reminder push**
(`FR-NOTIFY-002`) stays in M5. FCM **token registration** moves earlier still, into M3 with
`FR-DONOR-001` — the `users.fcm_token` column already exists in the M2 initial schema.

`CLAUDE.md` section 4 amended accordingly on all three rows.

### Why this and not the alternative
The alternative was to let M4 ship matching with an in-app request list and defer push to M5. Rejected:
`FR-REQUEST-001` would then close M4 with one of its own acceptance criteria unmet, which forces QA to
either fail the milestone or waive a criterion to hit a date. `docs/pm/risks.md` already records that
QA sign-off is the only independent gate this project has, because PO, Tech Lead, and Security are all
one person. Waiving criteria for schedule is exactly how that last gate erodes. Better to move the work
than to soften the test.

Splitting token registration into M3 is what makes this affordable. Registering and storing tokens is
the part that touches donor onboarding; sending is comparatively small. M4 then adds a send path to
tokens that already exist rather than building the whole FCM integration under time pressure.

### Consequence
M4 now carries request creation, matching, eligibility computation, and push in two weeks. That is a
real schedule risk and is recorded as one in `docs/pm/risks.md`. M5 becomes lighter — history and the
reminder push only.

---

## DEC-003 — Metrics event capture is a per-milestone requirement

**Date:** 2026-07-31 · **Decided by:** PO + PM (both held by Nem Sothea)

### Context
`FR-GLOBAL-002-metrics-instrumentation` was registered against a single milestone (M5). That cannot
work: the events the `prd.md` section 1 metrics are computed from start occurring at M3 (registration)
and continue through M4 (request created, donors notified, push delivered, first acceptance) and M5
(donation confirmed). Events not captured when they happen are gone.

This item was not among the two conflicts delegated for decision. It is decided here because
**DEC-002** moves push into M4, which moves push-delivery receipts with it — leaving the metrics FR at
M5 would have created a third contradiction rather than resolving one.

### Decision
`FR-GLOBAL-002` is not a single-milestone deliverable. Event capture is a **delivery requirement on
every milestone from M3 to M5**: each feature records its own events as it lands. Only the read side —
aggregation and the admin-facing dashboard — sits at M6 with `FR-PORTAL-002`.

Registered in `docs/po/features/index.md` with milestone "M3–M5 (capture), M6 (dashboard)".

### Why
`prd.md` section 1's five metrics are the stated basis for judging whether this project worked. A pilot
that ends with no evidence has no answer at the defence. Retrofitting instrumentation at M5 recovers
nothing from M3 and M4.

### Consequence
Every milestone's Definition of Done from M3 onward must include "events for this feature are
recorded". `FR-GLOBAL-002` stays `status: requested` — this decision fixes its schedule, not its
approval.
