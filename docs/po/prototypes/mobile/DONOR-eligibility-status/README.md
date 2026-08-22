# DONOR-eligibility-status (mobile)

**Milestone:** M5 wireframe · freeze before M5 build
**FR:** [`FR-DONOR-002`](../../../features/) (56-day cooldown)

> **Drafted retroactively, after the screen shipped.** `EligibilityCard` has shown this since
> M3 (`donor_setup_screen.dart`'s result step, then `donor_profile_screen.dart` on every open).
> Written now, per [[lifelink-check-prototypes-before-build]], to close the roadmap item rather
> than leave it looking undone — not because the answer needs to change.

## Question this settles

Roadmap moved this here from M3 with a specific reason: *"now that there is no reminder push"*
(`NOTIFY-eligibility-reminder` was dropped, DEC-004). Without a push, where does a donor learn
they're eligible again?

## Answer

**In-app, on the one screen a donor already opens to check their own record.** `DonorProfileScreen`
shows `EligibilityCard` first, above every other field — the countdown is the thing a returning
donor is most likely there to check, so it is not buried under name/blood type/district.

Two states, both already built:

```
┌───────────────────────────┐      ┌───────────────────────────┐
│ ✓ You can donate now       │      │ ⏱ Eligible in 12 days      │
│                            │      │   (Aug 9, 2026)            │
└───────────────────────────┘      └───────────────────────────┘
```

Both the day count and the absolute date show together in the not-yet case — a countdown alone
cannot be planned around, a date alone hides how close it is. This was `FR-DONOR-001`'s acceptance
criterion at M3 and nothing about moving the question to M5 changes it.

## Cross-check against the API

`GET /donors/me`'s `eligibility` object, computed server-side by `EligibilityCalculator` — never
recomputed on the client (two implementations of a 56-day rule would eventually disagree). No new
endpoint needed; this was never blocked on anything M5-specific.

## What is deliberately absent

- A push reminder. Dropped with `FR-NOTIFY-002` (DEC-004) — status is pull, not push, in this
  build. A donor who never re-opens the app never gets nudged; accepted at M5 sign-off, not
  reopened here.
