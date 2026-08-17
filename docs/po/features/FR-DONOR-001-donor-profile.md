---
id: FR-DONOR-001-donor-profile
title: Donor registration and profile
area: DONOR
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-02
---

## Problem
An authenticated user is not yet a findable donor. Without blood type and location on record the
system cannot tell whether this person can help a specific patient, and a donor who gets alerts for
incompatible or distant requests learns to ignore the app entirely.

## Desired outcome
A donor records their name, blood type, and location once, can edit it whenever it changes, and can
mark themselves unavailable without deleting anything. From then on they only hear about requests
they could actually answer.

## Why
This is the supply side of the whole product. `prd.md` section 1 targets 200 registered donors in
the first pilot month, and none of them exist until this ships.

The availability toggle stays inside this FR rather than splitting out. Whether it grows into
something with its own behaviour — auto-unavailable after repeated declines, scheduled
unavailability — is an open brief in `../briefs/roadmap.md`; splitting it now would pre-decide that.

~~Blocked in part on the **location-precision brief**~~ — **unblocked 2026-08-07 by
[ADR 0003](../../tech-lead/adr/0003-donor-location-precision.md)**, accepted. "Location" means a
required `district_code` plus optional coordinates at `NUMERIC(8,5)`, and the coordinates are never
returned to another user — distance is exposed only rounded to 0.5 km. Both halves of the old
question (privacy under `prd.md` §6, and matching accuracy) are answered there.

## Scope
Finalized 2026-08-17 from [`DONOR-profile-setup`](../prototypes/mobile/DONOR-profile-setup/), which
is now frozen for the M3 build.

**In:**
- A three-step setup after first sign-in: blood type → location → last donation, with a progress bar.
- **Blood type** as a grid of all 8 values, required, with no "unknown" option. A donor whose type is
  unknown is sent to a hospital first, because `blood_compatibility` has no row for unknown (ADR 0004)
  and such a profile would silently never match.
- **Location** as a required district dropdown plus an optional "use my current location" button
  (`geolocator`, no map — DEC-004). A district-only donor still matches and simply sorts `NULLS LAST`.
- The on-screen promise that others only ever see the district, never exact coordinates — the
  user-facing half of ADR 0003.
- **Last donation date** optional, with "I have never donated" as an equally weighted button writing
  NULL. Future dates are not selectable in the picker.
- A save result screen showing eligibility once: either eligible, or a countdown **and** the absolute
  date ("Eligible in 12 days (14 Aug 2026)"). Computed server-side and read from the response, never
  calculated on the device.
- Editing any of the above at any time afterwards.
- An availability toggle, default available, which hides the donor from matching without deleting
  anything.

**Out:**
- **Phone number.** `prd.md` FR-02 lists it as required; that predates ADR 0002 and is superseded
  here — see "Conflict with the PRD" below.
- Anything the availability toggle might grow into: auto-unavailable after repeated declines,
  scheduled unavailability. Open brief in `../briefs/roadmap.md`.
- The full eligibility status screen, which is M5. M3 shows the one-shot result screen only.

## Conflict with the PRD — resolved here
`prd.md` FR-02 requires "phone" among the required fields. **That criterion does not apply to this
build.** ADR 0002 replaced phone OTP with Google Sign-In, so a phone number would be unverified, and
M3–M4 coordination runs over FCM push instead of phone calls (`FR-REQUEST-002`, `FR-NOTIFY-001`).
Collecting a number the app never reads is inventing data.

This is a real reduction in the product, not a tidy-up: it is the carried risk named in
`FR-AUTH-003` — nothing guarantees a donor is reachable by voice. If `FR-REQUEST-002`'s accept flow
turns out to need a callable number, phone returns as a lazy step at acceptance time only
(ADR 0002, mitigation 2) — as a new FR, not by reopening this one.

## Acceptance criteria
The four product criteria live in `../prd.md` under FR-02 and are not duplicated here, except that
**"phone" is struck from its required-fields list** per the conflict above. What follows is what the
prototype settled and the PRD does not say.

- [ ] All 8 blood types are visible at once, without scrolling or opening a dropdown.
- [ ] Saving is refused without a blood type and a district; it is **not** refused for a missing
      date or missing coordinates.
- [ ] Declining the GPS permission still produces a complete, matchable profile.
- [ ] A first-time donor can finish setup without entering any date.
- [ ] The result screen shows both the day count and the calendar date when not yet eligible.
- [ ] An ineligible donor keeps their account and their alerts; they simply do not match until the
      date passes.
- [ ] Every string on all three steps exists in Khmer and English (`FR-GLOBAL-001`).

## Blocks the M3 build
The **district list itself is unwritten** — Phnom Penh has 14 districts and the dropdown needs real
`district_code` values seeded in a migration. The wireframe does not need it; the build cannot start
without it. PO owns the list and the Khmer labels; seeding it is Backend's.
