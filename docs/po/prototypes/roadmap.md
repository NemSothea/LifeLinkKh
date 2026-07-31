# Prototype Roadmap

Which screens get wireframed by which milestone, and what each prototype must settle.

Milestone dates are **not** repeated here — root `CLAUDE.md` section 4 owns the M1..M7 table.
This file only says *which flows are due by which milestone*.

Rule of thumb: a prototype ships **one milestone ahead** of the code that implements it.
The Flutter or Next.js work starts from a settled screen, never from a blank file.

## Registry

| Flow | Client | Area | Due by | Status | FR |
|---|---|---|---|---|---|
| _(none yet)_ | | | | | |

Status: `todo` | `drafting` | `in review` | `frozen` | `dropped`

## M1 — wireframes deliverable (due now)

M1 explicitly lists "PRD + wireframes". These are the M1 set — the four flows from
[`../prd.md`](../prd.md) section 7, enough to defend the concept:

| Flow | Client | Screens | Question it settles |
|---|---|---|---|
| `AUTH-otp-signin` | mobile | phone entry → OTP entry → role pick | How many taps to a usable account. Resend-OTP placement. |
| `DONOR-profile-setup` | mobile | blood type → location → last donation | Whether blood type is a picker or a grid. Whether last-donation is skippable. |
| `REQUEST-create-urgent` | mobile | form → confirm → waiting-for-responders | Can a panicking family finish it in under a minute (`FR-04` user story). |
| `NOTIFY-donor-alert` | mobile | push → request detail → accept/decline | What a donor sees before accepting, and what accepting reveals (`FR-07`). |

Also due at M1: a **one-screen home/dashboard sketch** per role so the navigation shell is
decided before Flutter routing is written.

## M3 — auth + donor register build

Freeze `AUTH-otp-signin` and `DONOR-profile-setup` before build week. Add:

| Flow | Client | Question it settles |
|---|---|---|
| `DONOR-eligibility-status` | mobile | How the 56-day countdown reads to a donor (`FR-03`) — days remaining vs. eligible-on date. |
| `AUTH-portal-signin` | web | Whether hospital staff use OTP or admin-issued credentials. Blocks `FR-01` scope for web. |

## M4 — request + matching build

Freeze `REQUEST-create-urgent`. Add:

| Flow | Client | Question it settles |
|---|---|---|
| `REQUEST-responders-list` | mobile | What a requester sees as donors accept (`FR-07`) — contact reveal, order, count. |
| `MATCH-no-donors-found` | mobile | The zero-match screen. Depends on the zero-match fallback brief (`../briefs/roadmap.md`). |
| `PORTAL-hospital-requests` | web | Hospital request list + confirm-donation action (`FR-10`). |

## M5 — history + cooldown + push build

Freeze `NOTIFY-donor-alert`. Add:

| Flow | Client | Question it settles |
|---|---|---|
| `DONATION-history` | mobile | Whether history is a list or an impact summary (`FR-08` user story is about feeling impact). |
| `NOTIFY-eligibility-reminder` | mobile | Reminder push copy and where it lands (`FR-09`). |

## M6 — GPS, i18n, portal polish

| Flow | Client | Question it settles |
|---|---|---|
| `GLOBAL-language-switch` | both | Where the Khmer/English toggle lives and how it persists (`FR-12`). |
| `MOBILE-map-picker` | mobile | Map vs. district dropdown for location. Depends on the location-precision brief. |
| `PORTAL-admin-dashboard` | web | Which of the section-1 success metrics are actually shown (`FR-11`). |

**Khmer pass at M6:** every frozen prototype gets re-checked with real Khmer strings.
Khmer runs longer than English and taller per line — layouts that passed in English can break.
Anything that breaks reopens (status back to `drafting`) and the fix goes through the FR.

## M7 — no new prototypes

Test pass and release only. A prototype request at M7 is a `CR-PO` change request, not a
roadmap item.

## Cadence

- Review this table at each milestone boundary alongside `../briefs/roadmap.md`.
- A flow still `drafting` when its build week opens is a blocker — escalate to PM
  (`docs/pm/risks.md`), don't let the client role guess the screen.
- Dropped flows keep their row. The reason a screen was never built is worth as much as the screen.
