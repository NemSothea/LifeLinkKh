# DONOR-profile-setup (mobile)

**Milestone:** M1 wireframe · freeze before M3 build
**FR:** [`FR-DONOR-001-donor-profile`](../../../features/FR-DONOR-001-donor-profile.md),
[`FR-DONOR-002-eligibility-check`](../../../features/FR-DONOR-002-eligibility-check.md)
**ADR:** [`0003`](../../../../tech-lead/adr/0003-donor-location-precision.md) (location)

## Questions this settles

1. Is blood type a picker or a grid?
2. Is last-donation-date skippable?
3. How is location captured, now that there is no map widget?

## Answers

1. **A grid of 8 buttons.** A dropdown hides the options behind a tap and makes O− and O+ adjacent
   in a scroll list where mis-taps are invisible. The set is fixed at 8 forever, so a grid costs
   nothing and shows everything.
2. **Yes, skippable.** `donor_profiles.last_donation_date` is nullable and NULL means "never
   donated", which is the correct state for a first-time donor. Forcing a date would make
   first-timers invent one, and the 56-day cooldown would then be wrong for exactly the people most
   likely to be eligible.
3. **GPS button + district dropdown, both optional.** No map (DEC-004). Coordinates are read once by
   `geolocator`; the district is a plain dropdown and is required. See the note under screen 2.

> Khmer strings are a first pass — native check needed before M3.

## Screen 1 — Blood type

```
┌─────────────────────────────────┐
│  ← ព័ត៌មានអ្នកបរិច្ចាគ  (1/3)        │
│    Donor details        (1/3)   │
│  ███████░░░░░░░░░░░░░░░░░░░░░   │
│                                 │
│  ក្រុមឈាមរបស់អ្នក                   │
│  Your blood type                │
│                                 │
│   ┌──────┐ ┌──────┐ ┌──────┐    │
│   │  O−  │ │  O+  │ │  A−  │    │
│   └──────┘ └──────┘ └──────┘    │
│   ┌──────┐ ┌──────┐ ┌──────┐    │
│   │  A+  │ │  B−  │ │  B+  │    │
│   └──────┘ └──────┘ └──────┘    │
│   ┌──────┐ ┌──────┐             │
│   │ AB−  │ │ AB+  │             │
│   └──────┘ └──────┘             │
│                                 │
│  មិនដឹងក្រុមឈាមរបស់អ្នក?              │
│  Don't know your blood type?    │
│  → សាកសួរមន្ទីរពេទ្យមុនចុះឈ្មោះ        │
│    Ask a hospital before        │
│    registering                  │
│                                 │
│         ┌─────────────┐         │
│         │  បន្ត / Next │         │
│         └─────────────┘         │
└─────────────────────────────────┘
```

**Blood type is required and has no "unknown" option.** A donor with an unknown type cannot be
matched — `blood_compatibility` has no row for it (ADR 0004) — so recording one would create a
profile that silently never appears in results. Better to send them to a hospital first.

## Screen 2 — Location

```
┌─────────────────────────────────┐
│  ← ព័ត៌មានអ្នកបរិច្ចាគ  (2/3)        │
│    Donor details        (2/3)   │
│  ██████████████░░░░░░░░░░░░░░   │
│                                 │
│  ខណ្ឌ/ស្រុក  *                    │
│  District  *                    │
│  ┌───────────────────────────┐  │
│  │ ទួលគោក / Toul Kork      ▾ │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ⌖  ប្រើទីតាំងបច្ចុប្បន្ន        │  │
│  │    Use my current         │  │
│  │    location               │  │
│  └───────────────────────────┘  │
│  ជួយដាក់លំដាប់តាមចម្ងាយ។ ស្រេចចិត្ត។   │
│  Helps rank you by distance.    │
│  Optional.                      │
│                                 │
│  ⓘ ទីតាំងជាក់លាក់មិនបង្ហាញអ្នកដទៃ      │
│    Others only ever see your    │
│    district — never your        │
│    exact location               │
│                                 │
│         ┌─────────────┐         │
│         │  បន្ត / Next │         │
│         └─────────────┘         │
└─────────────────────────────────┘
```

District required, coordinates optional — exactly ADR 0003. Declining GPS must never mean being
unfindable, so a district-only donor still matches and simply sorts `NULLS LAST`.

The ⓘ line is not decoration. It is the user-facing half of the ADR 0003 privacy decision, and it is
the sentence that makes granting GPS a reasonable thing to do.

## Screen 3 — Last donation

```
┌─────────────────────────────────┐
│  ← ព័ត៌មានអ្នកបរិច្ចាគ  (3/3)        │
│    Donor details        (3/3)   │
│  ███████████████████████████░   │
│                                 │
│  តើអ្នកបរិច្ចាគឈាមចុងក្រោយនៅពេលណា?     │
│  When did you last give blood?  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  📅  ជ្រើសរើសកាលបរិច្ឆេទ     │  │
│  │      Pick a date          │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │   ខ្ញុំមិនដែលបរិច្ចាគ            │  │
│  │   I have never donated    │  │
│  └───────────────────────────┘  │
│                                 │
│  ⓘ យើងប្រើវាដើម្បីរក្សាចម្ងាយ ៥៦ ថ្ងៃ   │
│    We use this to respect the   │
│    56-day rest period          │
│                                 │
│      ┌───────────────────┐      │
│      │  រក្សាទុក / Save   │      │
│      └───────────────────┘      │
└─────────────────────────────────┘
```

"I have never donated" is a **button, not a checkbox** — it is the more common answer for a new
volunteer app and deserves equal weight to the date picker. It writes NULL.

Future dates must be rejected by the picker, not by a validation message. A donation cannot be in
the future, and a future date would make the donor permanently ineligible.

## Screen 4 — Result (eligibility, shown once on save)

```
┌─────────────────────────────────┐
│                                 │
│            ✓                    │
│                                 │
│  អ្នកបានចុះឈ្មោះរួចរាល់              │
│  You're registered              │
│                                 │
│  ┌───────────────────────────┐  │
│  │  មានសិទ្ធិបរិច្ចាគ            │  │  ← green
│  │  Eligible to donate       │  │
│  └───────────────────────────┘  │
│                                 │
│         ── or ──                │
│                                 │
│  ┌───────────────────────────┐  │
│  │  នៅសល់ ១២ ថ្ងៃទៀត          │  │  ← amber
│  │  Eligible in 12 days      │  │
│  │  (14 Aug 2026)            │  │
│  └───────────────────────────┘  │
│                                 │
│       ┌──────────────────┐      │
│       │  ទៅដើម / Go home │      │
│       └──────────────────┘      │
└─────────────────────────────────┘
```

**Both a countdown and an absolute date.** "12 days" answers "am I eligible?" and "14 Aug" answers
"when should I come back?" — the second is the one a donor writes down. This is the M3-visible half
of `FR-DONOR-002`; the full status screen is M5.

An ineligible donor is **not** hidden from the app. They keep the account and get district alerts;
they simply do not match until the date passes.

## Cross-check against the API

`blood_type`, `district_code`, `latitude`, `longitude`, `last_donation_date` — all present in
`donor_profiles` (`backend-spring.md`). Eligibility is computed server-side, never in the client, so
the countdown is read from the response, not calculated on the device.

Phone number is **not** collected here yet. It is unverified and unused in the M3–M4 build, since
coordination goes through FCM push (ADR 0002). Adding a field the app never reads would be inventing
data.

## Open

The district list itself. Phnom Penh has 14 districts; the dropdown needs the real
`district_code` values seeded in `V1__init.sql`. Nobody has written that list. Blocks M3 build, not
this wireframe.
