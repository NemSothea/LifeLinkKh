# Prototype Roadmap

Which screens get wireframed by which milestone, and what each prototype must settle.

Milestone dates are **not** repeated here — root `CLAUDE.md` section 4 owns the M1..M7 table.
This file only says *which flows are due by which milestone*.

Rule of thumb: a prototype ships **one milestone ahead** of the code that implements it.
The Flutter or Next.js work starts from a settled screen, never from a blank file.

## Registry

| Flow | Client | Area | Due by | Status | FR |
|---|---|---|---|---|---|
| `AUTH-google-signin` | mobile | AUTH | M1 | frozen (M3 build shipped) | `FR-AUTH-003` |
| `DONOR-profile-setup` | mobile | DONOR | M1 | frozen (M3 build shipped) | `FR-DONOR-001` |
| `REQUEST-create-urgent` | mobile | REQUEST | M1 | frozen (M4 build shipped) | `FR-REQUEST-001` |
| `NOTIFY-donor-alert` | mobile | NOTIFY | M1 | frozen, corrected 2026-08-22 by `REQUEST-responders-list` | `FR-NOTIFY-001` |
| `REQUEST-responders-list` | mobile | REQUEST | M4 | drafted 2026-08-22, late — written after M4 build, matches what shipped | `FR-REQUEST-002` |
| `PORTAL-open-requests` | web | PORTAL | M4 | frozen 2026-08-22, build shipped same day | `FR-PORTAL-001` |
| `DONOR-eligibility-status` | mobile | DONOR | M5 | drafted 2026-08-22, late — matches what shipped at M3 | `FR-DONOR-002` |
| `DONATION-history` | mobile | DONATION | M5 | drafted 2026-08-22, build starting now | `FR-DONATION-001` |

Status: `todo` | `drafting` | `in review` | `frozen` | `dropped`

## M1 — wireframes deliverable (due now)

M1 explicitly lists "PRD + wireframes". These are the M1 set — the four flows from
[`../prd.md`](../prd.md) section 7, enough to defend the concept. **DEC-004 fixed the M1 set at these
four and nothing else** ([`../../scope.md`](../../scope.md)); dropped rows below keep their reason.

| Flow | Client | Screens | Question it settles |
|---|---|---|---|
| `AUTH-google-signin` | mobile | Google account picker → role pick | How many taps to a usable account. What the screen says before the account picker appears. |
| `DONOR-profile-setup` | mobile | blood type → location → last donation | Whether blood type is a picker or a grid. Whether last-donation is skippable. |
| `REQUEST-create-urgent` | mobile | form → confirm → waiting-for-responders | Can a panicking family finish it in under a minute (`FR-04` user story). |
| `NOTIFY-donor-alert` | mobile | push → request detail → accept/decline | What a donor sees before accepting, and what accepting reveals (`FR-07`). |

Also due at M1: a **one-screen home/dashboard sketch** per role so the navigation shell is
decided before Flutter routing is written.

## M3 — auth + donor register build

Freeze `AUTH-google-signin` and `DONOR-profile-setup` before build week. Add:

| Flow | Client | Question it settles |
|---|---|---|
| ~~`AUTH-portal-signin`~~ | web | **Dropped (DEC-004).** One admin is seeded by migration; there is no portal sign-in flow to design. |

## M4 — request + matching build

Freeze `REQUEST-create-urgent`. Add:

| Flow | Client | Question it settles |
|---|---|---|
| `REQUEST-responders-list` | mobile | What a requester sees as donors accept (`FR-07`) — contact reveal, order, count. |
| `PORTAL-open-requests` | web | The single web page: open-requests table (`FR-PORTAL-001`, trimmed by DEC-004). |
| ~~`MATCH-no-donors-found`~~ | mobile | **Dropped (DEC-004)** with `FR-MATCH-002`. A zero-match shows a plain "none found" message. |

## M5 — history + eligibility status

Freeze `NOTIFY-donor-alert`. Add:

| Flow | Client | Question it settles |
|---|---|---|
| `DONATION-history` | mobile | Whether history is a list or an impact summary (`FR-08` user story is about feeling impact). |
| `DONOR-eligibility-status` | mobile | Moved here from M3 — the 56-day countdown, now that there is no reminder push. |
| ~~`NOTIFY-eligibility-reminder`~~ | mobile | **Dropped (DEC-004)** with `FR-NOTIFY-002`. Status is shown in-app; no unprompted push. |

## M6 — GPS, i18n, Android build

| Flow | Client | Question it settles |
|---|---|---|
| `GLOBAL-language-switch` | both | Where the Khmer/English toggle lives and how it persists (`FR-12`). |
| ~~`MOBILE-map-picker`~~ | mobile | **Dropped (DEC-004).** No map widget — `geolocator` reads coordinates, a district dropdown is the input. |
| ~~`PORTAL-admin-dashboard`~~ | web | **Dropped (DEC-004)** with `FR-PORTAL-002`. |

**Khmer pass at M6:** every frozen prototype gets re-checked with real Khmer strings.
Khmer runs longer than English and taller per line — layouts that passed in English can break.
Anything that breaks reopens (status back to `drafting`) and the fix goes through the FR.

## M7 — no new prototypes

Test pass and release only. A prototype request at M7 is a `CR-PO` change request, not a
roadmap item.

## Cadence

- Review this table at each milestone boundary alongside `../briefs/roadmap.md`.
- A flow still `drafting` when its build week opens is a blocker — log it in `docs/risks.md` and raise
  it with QA (who tracks Definition of Done), don't let the client role guess the screen.
- Dropped flows keep their row. The reason a screen was never built is worth as much as the screen.
