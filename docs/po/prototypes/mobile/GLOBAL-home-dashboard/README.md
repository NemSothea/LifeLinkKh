# GLOBAL-home-dashboard (mobile)

**Milestone:** M1 sketch — required by [`roadmap.md`](../../roadmap.md) so the Flutter navigation
shell is decided before routing is written.

## Question this settles

What is the navigation shell, and does it differ by role?

## Answer

**Two different home screens, one shell.** Bottom navigation with three tabs for a donor, two for a
requester. Role is chosen at sign-in (`AUTH-google-signin` screen 3) and decides which shell mounts
— so Flutter routing branches once, at the root, not inside every screen.

Deciding this now matters because it is the one M1 answer that constrains code structure rather than
UI: a shared shell with conditional tabs is a different widget tree from two shells.

> Khmer strings are a first pass — native check needed before M3.

## Donor home

```
┌─────────────────────────────────┐
│  ជីវិត LifeLink KH           ⚙   │
│                                 │
│  ┌───────────────────────────┐  │
│  │  មានសិទ្ធិបរិច្ចាគ  ✓         │  │  ← green
│  │  Eligible to donate       │  │
│  │  O−  ·  ទួលគោក            │  │
│  │       Toul Kork           │  │
│  └───────────────────────────┘  │
│                                 │
│  សំណើនៅជិតអ្នក                     │
│  Requests near you              │
│                                 │
│  ┌───────────────────────────┐  │
│  │ A+ · បន្ទាន់ · ~២.៥ គ.ម     │  │
│  │ មន្ទីរពេទ្យកាល់ម៉ែត្រ         │  │
│  │ Calmette · 14 min ago     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ O+ · ធម្មតា · ~៦.០ គ.ម      │  │
│  │ មន្ទីរពេទ្យព្រះកេតុមាលា        │  │
│  │ Preah Ketumealea · 2 h    │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌─────────────────────────────┐│
│  │  ដើម    │  ប្រវត្តិ  │  ខ្ញុំ    ││
│  │  Home   │ History  │  Me   ││
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

The eligibility card is the top element because it is the one thing a donor opens the app to check.
An ineligible donor sees the amber countdown card here instead (same component as
`DONOR-profile-setup` screen 4).

**A request list on the home screen is not redundant with push.** Notifications get missed, silenced,
and swiped away. This is the recovery path, and it is also what the app shows a donor who opens it
unprompted.

Ineligible donors see the list but the cards are disabled with `មិនមានសិទ្ធិឥឡូវ / Not eligible yet`
— visible, not hidden, so the app never looks empty and broken.

## Requester home

```
┌─────────────────────────────────┐
│  ជីវិត LifeLink KH           ⚙   │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │   🩸  ស្នើសុំឈាម              │  │  ← blood-red, large
│  │       Request blood       │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  សំណើរបស់ខ្ញុំ / My requests      │
│                                 │
│  ┌───────────────────────────┐  │
│  │ A+ · ១ ឯកតា · ● បើកចំហ      │  │
│  │ Calmette · OPEN           │  │
│  │ អ្នកបរិច្ចាគ ១២ · យល់ព្រម ១    │  │
│  │ 12 alerted · 1 accepted   │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌─────────────────────────────┐│
│  │      ដើម      │     ខ្ញុំ      ││
│  │      Home     │     Me     ││
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

One oversized primary action. A requester opens this app for exactly one reason, usually in a
hospital corridor, and the button must be findable without reading.

No History tab — a requester has no donation history. Two tabs, not three greyed out.

## Shell decision for Flutter

```
sign-in → role
   ├── DONOR      → shell A: [Home | History | Me]
   └── REQUESTER  → shell B: [Home | Me]
```

- Branch at the root on `users.role`. No per-screen role checks.
- `HOSPITAL` / `ADMIN` never reach this shell — they use the Next.js portal
  (`FR-PORTAL-001`), and the mobile app has no screens for them. Server-side allow-list keeps them
  out of self-service sign-up entirely (`TM-AUTH-001` E1).
- "Me" holds profile edit, language toggle (`FR-GLOBAL-001`, M6), and sign-out. Not a settings
  labyrinth — three items.

## Cross-check against the API

Donor home needs a "requests matching me" list — `request_matches` joined to `blood_requests`,
filtered to this donor, which is the same query `FR-MATCH-001` already produces. Requester home needs
"my requests" plus alerted and accepted counts, both counts of `request_matches` rows.

Neither needs an endpoint that isn't already implied by the eight core FRs. Both are named in the API
spec.

## Deliberately absent

- Donation streaks, badges, leaderboards. Not in the PRD, and gamifying blood donation is a product
  decision nobody has made.
- A map tab (DEC-004).
- Admin metrics (`FR-PORTAL-002`, deferred).
