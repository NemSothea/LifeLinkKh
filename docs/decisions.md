# Decisions (DEC)
next: 009

> **Relocated 2026-08-07** from `docs/pm/decisions.md`. The PM role was dropped and `docs/pm/` was
> deleted, but a decision register is a project artefact, not a role's artefact — DEC-001..003 are
> cited by four FRs, `features/index.md`, and root `CLAUDE.md` section 4. It lives at the `docs/`
> root alongside `cheat-sheet.md` and `roles-and-flows.md`, which are also project-level.
>
> **From 2026-08-07, hard-to-reverse technical decisions go in `tech-lead/adr/` instead.** This
> register stays for the three below and for any future cross-role decision that is not architectural.
> Recent ADRs, indexed here so there is one place to look:
>
> | ID | Decision | Date |
> |----|----------|------|
> | [ADR 0002](tech-lead/adr/0002-auth-google-sign-in.md) | Auth via Google Sign-In, not phone OTP | 2026-08-07 |
> | [ADR 0003](tech-lead/adr/0003-donor-location-precision.md) | Donor location: district + coarse coordinates no API returns | 2026-08-07 |
> | [ADR 0004](tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md) | ABO/Rh compatibility as a seeded lookup table | 2026-08-07 |

| ID | Decision | Date |
|----|----------|------|
| DEC-001 | 56-day eligibility computation moves from M5 to M4 | 2026-07-31 |
| DEC-002 | FCM request-alert push moves from M5 to M4; FCM token registration moves to M3 | 2026-07-31 |
| DEC-003 | Metrics event capture is a per-milestone delivery requirement, not a milestone item | 2026-07-31 |
| DEC-004 | Scope cut to 8 buildable FRs; 8 deferred; M3/M4 given 3 weeks each | 2026-08-07 |
| DEC-005 | Seed all 14 Phnom Penh districts; `1213`/`1214` ship provisional rather than withheld | 2026-08-18 |
| DEC-006 | iOS build target added to M6, scope capped at device/simulator build, no App Store submission | 2026-08-27 |
| DEC-007 | M7 internal-testing backend reached via tunnel (ngrok/cloudflared) to a laptop, not a hosted deploy | 2026-08-29 |
| DEC-008 | New M8 (ungraded): a demo-script.md walkthrough for explaining the app to a first-time viewer | 2026-08-29 |

---

## DEC-001 — Eligibility computation moves to M4

**Date:** 2026-07-31 · **Decided by:** PO (held by Nem Sothea at the time; the PM role no longer exists)

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

**Date:** 2026-07-31 · **Decided by:** PO (held by Nem Sothea at the time; the PM role no longer exists)

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
either fail the milestone or waive a criterion to hit a date. `risks.md` already records that
QA sign-off is the only independent gate this project has, because PO, Tech Lead, and Security are all
one person. Waiving criteria for schedule is exactly how that last gate erodes. Better to move the work
than to soften the test.

Splitting token registration into M3 is what makes this affordable. Registering and storing tokens is
the part that touches donor onboarding; sending is comparatively small. M4 then adds a send path to
tokens that already exist rather than building the whole FCM integration under time pressure.

### Consequence
M4 now carries request creation, matching, eligibility computation, and push in two weeks. That is a
real schedule risk and is recorded as one in `risks.md`. M5 becomes lighter — history and the
reminder push only.

---

## DEC-003 — Metrics event capture is a per-milestone requirement

**Date:** 2026-07-31 · **Decided by:** PO (held by Nem Sothea at the time; the PM role no longer exists)

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


---

## DEC-004 — Scope cut to a buildable core

**Date:** 2026-08-07 · **Decided by:** Tech Lead (Nem Sothea)

### Context
The registry held 19 FRs across 7 milestones with a full multi-role governance process. This is a
13-week course case study delivered by students part-time. The plan did not fit the time available,
and a plan that does not fit does not produce a late product — it produces eight half-finished
features instead of eight working ones.

### Decision
Eight FRs form the build; eight are `deferred` with their documents kept; `FR-PORTAL-001` is trimmed to
a single open-requests page and GPS uses `geolocator` with no map widget. M3 and M4 get three weeks
each, funded by collapsing the old M5 and M6. Full rationale and the per-FR reasons:
[`scope.md`](scope.md).

### Why this and not the alternative
The cut was made against what the course grades — authentication, push notifications, GPS, a relational
database, a Play Store internal-testing release — not against how interesting each feature is. Every
deferred item is checked against that list and earns nothing on it.

Cutting evenly across all 19 FRs was rejected: it would have left every feature at 60%, and a demo of
eight partial flows cannot show the core loop working end to end. Better eight that work.

### Consequence
- **DEC-003 is withdrawn.** `FR-GLOBAL-002` metric instrumentation is deferred; the five PRD metrics
  come from SQL `COUNT` queries against pilot data at demo time. No milestone carries an event-capture
  delivery requirement any more.
- **`FR-SECURITY-001` (account and data deletion) is deferred, and this one is a privacy obligation
  rather than a feature.** Acceptable only because the pilot uses team-created test accounts. It must
  be built before any real donor uses the app, ahead of every other deferred item.
- `blood_requests.status = 'EXPIRED'` stays permanently unreachable in this build.
- The deferred set is the defence's "future work" section. A documented deliberate cut is a better
  answer than a burndown that flatlines in Week 12.

---

## DEC-005 — All 14 districts are seeded; two codes ship provisional

**Date:** 2026-08-18 · **Decided by:** PO (Sourn SAVOURN) with Tech Lead (Nem Sothea)

### Context
`V2__districts.sql` created the `districts` table, added the foreign key from
`donor_profiles.district_code`, and **deliberately seeded nothing** — because
[`REF-DISTRICTS-PP`](po/reference/phnom-penh-districts.md) said not to seed while any code was
unverified. That rule was right and it also blocked M3 outright: with no rows, the foreign key makes
`PUT /donors/me` answer 422 for every `districtCode`, so donor registration cannot work at all.

The verification was done on 2026-08-18 against the NCDD Phnom Penh gazetteer. It confirmed
`1201`–`1212` exactly, including the three post-2019 codes that were the main worry. It could not
confirm `1213` (Boeng Keng Kang) or `1214` (Kamboul), for a reason that is not going to resolve
itself: both khan were created by sub-decree 03 of 8 January 2019, after that gazetteer was published.
There is no official code to copy.

### Decision
Seed **all fourteen** in `V3__seed_districts.sql`. `1213` and `1214` are marked provisional in the
reference doc and in the migration comment.

### Why this and not the alternative
Seeding only the twelve confirmed rows was the obvious safe option, and it is worse. Boeng Keng Kang
is one of the densest parts of the city; a pilot where those donors have no district to pick either
loses them or files them under Chamkar Mon, which is silent bad data rather than a marked code.

The cost of being wrong is bounded and was already written down before this decision: nothing in the
matching logic parses `district_code` — it is compared, never decoded — and the dropdown shows the
name, not the number. A wrong code costs a two-row `UPDATE` plus the same update on any
`donor_profiles` rows carrying it. Waiting instead costs M3.

Holding the whole seed for two codes was also rejected on process grounds: the blocking rule exists to
prevent a data migration, and it was being read as preventing any seed at all.

### Consequence
- `PUT /donors/me` accepts district codes from this milestone on. The 422 in `V2`'s comment block no
  longer describes the system.
- The dropdown carries 14 options, sorted by Khmer name (`REF-DISTRICTS-PP` rule), with no "other"
  option — the pilot is Phnom Penh.
- If an official code for either khan surfaces, correcting it is a `V<n>` migration and a profile
  update, not a schema change. Whoever does it must update `donor_profiles` in the same migration.

---

## DEC-006 — iOS build target added, capped at device/simulator build

**Date:** 2026-08-27 · **Decided by:** Tech Lead (Nem Sothea)

### Context
The original stack choice (`CLAUDE.md` §2) picked Flutter specifically because it "builds a native
Android app directly, satisfying the course Play Store requirement cleanly" — iOS was never in scope,
the course only grades a Play Store internal-testing release. Flutter targets iOS by default with no
extra dependency, so the cost of adding it is not zero but is bounded.

### Decision
Add an iOS build target to M6, alongside the existing Android build. Scope capped at **build only**:
`flutter build ios` runs and the app launches on simulator/device. No code signing, no TestFlight, no
App Store submission, no Apple Developer account ($99/yr). M7's store release stays Play Store only.

### Why this and not the alternative
Full App Store submission was rejected: it needs a paid Apple Developer account, a Mac for signing,
and TestFlight setup — none budgeted, and M7 (Play Store internal testing) is already the course
deliverable at week 15, one day out from this decision. Build-only demonstrates cross-platform reach
at the defence without new cost or schedule risk.

### Consequence
- `CLAUDE.md` §2 and §4 (M6 row) amended.
- `mobile/ios/` (present untracked at time of this decision) is the Flutter-generated scaffold this
  build target uses — not a separate feature to build.
- No `docs/scope.md` FR entry needed: this is a build-target addition, not a new feature.

---

## DEC-007 — M7 internal-testing backend reached via tunnel, not a hosted deploy

**Date:** 2026-08-29 · **Decided by:** Tech Lead (Nem Sothea)

### Context
`docs/tech-lead/deploy-runbook.md` Step 5 named the gap: no production backend host is decided
anywhere in the repo, and `API_BASE_URL` is a compile-time `--dart-define` baked into the signed
AAB, so it must be settled before the first M7 build. Two options were laid out there — tunnel the
local backend, or deploy backend + Postgres to a free-tier host (Render/Railway/Fly.io).

### Decision
For M7, internal testers reach the backend through a **tunnel** (`ngrok` or `cloudflared`) pointed
at the backend running on a team laptop. No hosted deployment is built for this milestone.

### Why this and not the alternative
A hosted deploy is durable but is new, unbudgeted infrastructure work — a Docker-based deploy
pipeline, plus finding `.env`'s secrets (`JWT_SECRET`, `FIREBASE_PROJECT_ID`, the Firebase
service-account key) a real home outside a developer's machine. None of that is needed to satisfy
M7's actual bar, which is a signed AAB installable from Play Store's internal testing track, not a
production backend. The pilot is already team-only test accounts (`docs/scope.md`'s
`FR-SECURITY-001` note), so a laptop-dependent backend carries no user-facing cost this milestone
does not already accept elsewhere.

### Consequence
- The backend must be running, with the tunnel active, whenever a tester opens the app during the
  testing window. Restarting either changes the tunnel URL (free-tier `ngrok`) and requires a
  rebuild + re-upload of the AAB — `API_BASE_URL` cannot be changed after the fact.
- This is explicitly **not durable past M7**. Revisit before any real donor outside the team uses
  the app — the same trigger `docs/scope.md` already names for bringing `FR-SECURITY-001` back into
  scope.
- `docs/tech-lead/deploy-runbook.md` Step 5 updated to point here instead of listing both options as
  open.
- `docs/risks.md`'s "no production backend host decided" row updated: decided, not closed — the
  laptop-dependency it trades in is now the live risk.

---

## DEC-008 — New M8 (ungraded): a demo-script for explaining the app to a first-time viewer

**Date:** 2026-08-29 · **Decided by:** Tech Lead (Nem Sothea)

### Context
Two documents already exist for showing the app to someone: `docs/demo-runbook.md` (commands to
bring the stack up, mint a portal token, run the golden path) and `docs/po/prd.md` (the product
spec). Neither is written for the moment itself — standing in front of an instructor, classmate, or
pilot partner who has never seen the app and needs the *story*, not the command list: what problem
this solves, why it's a phone app and not a website, what to watch for at each step, and where the
demo's known gaps (`docs/demo-runbook.md` §6) come from. Asked for directly: "create a demo scenario
for explaining to other people."

### Decision
Add **M8**, explicitly not a course milestone — the course grades M1–M7 only, and this is not an FR
either. Deliverable: `docs/po/demo-script.md`, a narrated walkthrough of the same golden path
`demo-runbook.md` already runs, written for the audience watching rather than the person driving.
No sign-off gate, no acceptance criteria, no QA test case — it is prose, and it goes stale the moment
the golden path changes, at which point it gets edited, not re-approved.

### Why this and not the alternative
Folding this into `demo-runbook.md` was rejected: that document's audience is the Tech Lead
operating the stack (`.env`, `docker compose`, JWT minting), and interleaving narration for a
first-time viewer into command blocks would make both jobs — running the demo and narrating it —
harder to do from the same page. Two documents, one for each half of a two-person demo (driver +
narrator, often the same person switching hats), reads better than one document trying to serve
both.

### Consequence
- `CLAUDE.md` §4 gains an M8 row, marked not graded.
- Owner is PO (`docs/po/`), not Tech Lead — this is the product's story, not its operation.
- Living document: update it whenever the golden path in `demo-runbook.md` changes, same as that
  file's own maintenance expectation.
