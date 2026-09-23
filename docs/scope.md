# Scope — what we build, what we deliberately did not

**Group 2 · decided 2026-08-07 by Tech Lead (DEC-004).** This is the answer to "why isn't feature X in your app"
at the project defence. Read it before the demo.

## The reasoning

LifeLink KH is a **13-week course case study**, not a product launch. The registry held 19 functional
requirements, seven course milestones, and a full multi-role governance process. Building all of it is
not a scheduling problem to be solved with better estimates — it does not fit, and a plan that does not
fit produces eight half-finished features instead of eight working ones.

The course grades five things: **authentication, push notifications, GPS, a relational database, and a
Play Store internal-testing release.** Everything else is optional. So the cut was made against that
list, not against how interesting a feature is.

A deliberate, documented cut is also a better defence answer than a burndown chart that flatlines in
Week 12.

## The build — 8 FRs

| FR | Why it survives |
|---|---|
| `FR-AUTH-003` Google Sign-In | Graded (authentication). Also the cheapest possible option — Firebase does the identity proof, so there is no code to generate, expire, or rate-limit (ADR 0002) |
| `FR-DONOR-001` Donor profile | Graded (relational DB). The data the whole app operates on |
| `FR-DONOR-002` 56-day eligibility | The one real business rule in the product, and cheap — a date comparison against `donations.donated_on` |
| `FR-REQUEST-001` Create urgent request | Start of the core loop |
| `FR-MATCH-001` Matching | The demo moment. A compatibility join (ADR 0004) plus a distance sort (ADR 0003) |
| `FR-NOTIFY-001` Request push alert | Graded (push notifications) |
| `FR-REQUEST-002` Accept / decline | Ends the core loop. Without it the demo has no conclusion |
| `FR-DONATION-001` Donation history | Graded (course feature 3). A plain list |

Plus two trims rather than cuts:

- **`FR-PORTAL-001`** reduced to **one** page: a table of open requests. That satisfies the Next.js
  requirement. It is not a hospital management console.
- **`FR-GLOBAL-001`** Khmer/English at M6, unchanged.

**GPS via `geolocator` only — no `google_maps_flutter`.** Reading coordinates satisfies the GPS
requirement. Rendering an interactive map with markers is roughly a week of work and earns nothing
extra, so distance is shown as a number and location as a district name (which ADR 0003 requires
anyway).

## Deferred — 8 FRs

Documents kept, `status: deferred`, nothing started. These are the "future work" section.

| FR | Why cut |
|---|---|
| `FR-REQUEST-003` Duplicate-request warning | Rarer than the cost of the check. Duplicates are visible to the hospital in the list |
| `FR-REQUEST-004` Withdraw acceptance | State transition + re-notify path + UI, for an edge case a phone call handles during a pilot |
| `FR-REQUEST-005` Request expiry | Needs a scheduled job and a rule nobody has written. `status = 'EXPIRED'` stays a dead value; requests are closed manually |
| `FR-MATCH-002` Zero-match fallback | Needs radius widening and retry. A zero-match is handled by telling the requester none were found |
| `FR-NOTIFY-002` Eligibility reminder push | Needs a scheduled job + FCM batch that nothing else in the build requires. **Only the unprompted push is cut** — the 56-day status is still visible in-app at M5 |
| `FR-PORTAL-002` Admin dashboard | A second web surface with charts. `FR-PORTAL-001` already covers the Next.js requirement |
| `FR-GLOBAL-002` Metrics instrumentation | Event capture across three milestones plus a dashboard. Replaced by SQL `COUNT` queries against pilot data at demo time — same numbers for the defence, none of the instrumentation. This withdraws DEC-003 |
| `FR-SECURITY-001` Account and data deletion | See the warning below |

### An idea surfaced after the cut, not part of the original 19

Unlike the eight above — all cut from the original 19-FR registry by this same decision (DEC-004,
2026-08-07) — `FR-DONOR-003` (scannable donor ID, a QR/barcode hospital staff could scan to confirm
a donation instead of finding the request row by hand) was registered later, on 2026-08-27 during
the M7 demo dry run. Same outcome, different reason: not on the graded list, and real scope (a
signed/expiring token, a backend endpoint, camera-scan on the portal) this late in the schedule.
See `docs/po/features/FR-DONOR-003-scannable-donor-id.md` and `docs/po/changelog.md`'s 2026-08-27
entry.

### One deferral that is not purely a scheduling choice

`FR-SECURITY-001` (account and personal data deletion) is a **privacy obligation**, not a feature. It
is deferred only because the pilot runs on team-created test accounts, with no member of the public
involved and no real donor's phone number, location, or blood type in the database.

**It must be built before any real donor uses this app.** If the pilot ever widens beyond the team —
a campus drive, an NGO partner, anyone outside the five of us — this comes back into scope first, ahead
of every other deferred item. Say this out loud at the defence rather than hoping nobody asks.

## Governance also trimmed

Kept, because it exists already and costs nothing to keep: the PRD, the feature registry, ADRs
0001–0004, the schema spec and ERD, and QA test cases for the three core flows.

Stopped: brief → prototype → finalize as a per-FR ritual, a threat model per change, CR channels,
sprints, retros. `TM-AUTH-001` and `SEC-REVIEW-001` already cover the only R5 surface that matters
(auth) — they are done, not a template to repeat eight more times.

Definition of Done still applies to the eight FRs in the build, and **QA sign-off stays independent**.
That one is not a trim: with Tech Lead holding Security and co-PO, it is the only gate outside one
person.

## Start now regardless of scope

Two items have external lead time and will block M3/M7 if left:

1. **Firebase project** — register the Android app and add the **debug SHA-1 fingerprint**. Google
   Sign-In fails silently without it, which is the single most common wasted afternoon here.
2. **Google Play Console account, $25 one-time.** Identity verification can take days. Do it in
   Week 3, not Week 14.

## Still open, and still needed for the build

| Open item | Status |
|---|---|
| Max notified donor count | **Closed** 2026-08-19 by [ADR 0008](tech-lead/adr/0008-max-notified-donor-count.md) — `FR-MATCH-001` no longer blocked |
| Deploy runbook | **Written** — [`tech-lead/deploy-runbook.md`](tech-lead/deploy-runbook.md). Backend-host question resolved by [DEC-007](decisions.md#dec-007--m7-internal-testing-backend-reached-via-tunnel-not-a-hosted-deploy) (tunnel, not hosted). No signed AAB built yet, and [DEC-012](decisions.md) moves that behind the demo deliberately — the demo runs on one local machine and never touches the store |

Both are Tech Lead's.

The critical path is now the **local demo**, not the store release ([DEC-012](decisions.md)):
[`po/demo-script.md`](po/demo-script.md) §7 for what to do the day before, and
[`demo-runbook.md`](demo-runbook.md) §§1-3 for the commands.

## Grown after M7 — 2026-09-06

DEC-004's cut still stands: eight FRs built, eight deferred, and none of the deferred eight has
been started. What follows was added *after* the graded milestones, on the same day, and is
recorded here rather than quietly enlarging the table above — the point of this document is that
scope changes are visible.

None of these is a new FR. Two are the completion of an FR that shipped half-finished, and two are
decisions with their own DEC record.

| Added | What it actually is | Where it is argued |
|---|---|---|
| Public request board | `/portal` is readable with no account, including accepted donor names — a deliberate override of `TM-AUTH-001` I1 | [DEC-009](decisions.md) |
| Portal staff sign-in | Username and password replacing `PORTAL_DEV_JWT`, a token pasted into `.env` by hand | [DEC-010](decisions.md) |
| Staff lifecycle | Create, promote, demote, revoke. Password login without an account lifecycle was half a feature | DEC-010's consequences |
| In-app language switch (mobile) | `FR-GLOBAL-001`'s mobile half. The locale was pinned to `km` with no way to change it, so an English speaker could not read one screen | — |
| Push alert language | `users.language` decided the language of every urgent-request alert and **no client had ever written it** — every push in the product was Khmer regardless of the app's setting | — |
| Intro carousel (mobile) | Three skippable slides before sign-in, shown once per install. The app asked for a Google account before saying what it wanted one for | [DEC-011](decisions.md) |
| Staff filtering (portal) | Role and hospital filters on `/portal/staff`, in the URL rather than in client state. Appears only above four staff — three chips over three rows is decoration | — |
| Public board on mobile | The donor home screen reads `/public/requests` under the alert inbox. `GET /matches/me` is empty most days by design, and that emptiness was the entire screen | — |

### What this costs, said plainly

Two debts, both with the same deadline as `FR-SECURITY-001` — *before any real donor's data is in
this database*:

1. ~~**A password sits in the repository.**~~ **Closed 2026-09-23.**
   `V19__unseed_portal_passwords.sql` replaced the four seeded digests with BCrypt hashes of
   random values generated inside the database, and `PortalPasswordBootstrap` now sets the real
   passwords from `PORTAL_ADMIN_PASSWORD` / `PORTAL_STAFF_PASSWORD` at startup. Unset means
   nobody can sign in; under 12 characters is refused. See [DEC-013](decisions.md) and
   [`demo-runbook.md`](demo-runbook.md) section 9. The narrower thing that remains is not a
   repository leak: three hospital accounts share one environment value, so three people share
   one credential.
2. **Donor names are world-readable.** DEC-009 publishes a named person's blood type and district
   to anyone with the link. Safe only because every donor row is a team-created test account, and
   there is no consent step because until that day there was nothing to consent to.

Neither is an oversight to be discovered at the defence. Both are choices with a recorded reason
and a recorded expiry.
