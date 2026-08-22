# DONATION-history (mobile)

**Milestone:** M5 wireframe · freeze before M5 build
**FR:** [`FR-DONATION-001-donation-history`](../../../features/FR-DONATION-001-donation-history.md)

## Question this settles

Is history a plain list, or an impact summary? `FR-08`'s user story is explicit: *"As a donor, I
want to see my donation history, so that I feel my impact"* — a plain list answers "what happened,"
not "did it matter."

## Answer

**Both — an impact number first, the list underneath.** A volunteer giving blood for free earns the
one line that says the count out loud; the list is still there for anyone who wants the dates.

```
┌─────────────────────────────────┐
│  ←  ការបរិច្ចាគរបស់ខ្ញុំ           │
│     My donations                │
│                                 │
│         🩸  3                   │
│   អ្នកបានបរិច្ចាគ ៣ ដង            │
│   You've donated 3 times        │
│                                 │
│  ──────────────────────────────  │
│                                 │
│  ២២ សីហា ២០២៦ / Aug 22, 2026    │
│  មន្ទីរពេទ្យកាល់ម៉ែត្រ              │
│  Calmette Hospital              │
│  ──────────────────────────────  │
│  ១៤ មិថុនា ២០២៦ / Jun 14, 2026   │
│  មន្ទីរពេទ្យកាល់ម៉ែត្រ              │
│  Calmette Hospital              │
│  ──────────────────────────────  │
│  ១២ មេសា ២០២៦ / Apr 12, 2026     │
│  មន្ទីរពេទ្យប្រះកុសុមៈ              │
│  Preah Kossamak Hospital        │
└─────────────────────────────────┘
```

No count grows into a "lives saved" multiplier — `prd.md` makes no clinical claim about units per
patient, and inventing one is a promise nobody can back. The raw count is honest and still lands
emotionally; three real donations reads as three real donations.

## Screen — empty state (every donor starts here)

```
┌─────────────────────────────────┐
│  ←  ការបរិច្ចាគរបស់ខ្ញុំ           │
│     My donations                │
│                                 │
│         🩸  0                   │
│   អ្នកមិនទាន់បានបរិច្ចាគនៅឡើយទេ    │
│   No donations yet — when you   │
│   do, they'll show up here      │
└─────────────────────────────────┘
```

Zero is not an error. Every donor, including one who has been eligible and available for months
without a matching request ever reaching them, sits here — the empty state has to read as neutral,
not as a donor doing something wrong.

## Entry point

A "My donations" row on `DonorProfileScreen`, below the eligibility card — the two screens answer
related but different questions (*can I donate now* vs *what have I done*), so they stay separate
rather than merging the list into the profile screen itself.

## Cross-check against the API

`GET /donations/me` — `donatedOn`, `hospital.name` (+ district, both labels), `bloodRequestId`
(nullable, walk-in). The count on this screen is `List.length` on the client; there is no separate
count endpoint and none is needed for a number this cheap to derive from a list already fetched.

`bloodRequestId` is fetched but not shown — a donor already knows which request they answered
(they were the one who accepted it), and linking back into `RequestDetailScreen` from history is a
second navigation path with no FR asking for it. Noted for a future `CR-PO`, not built here.

## What is deliberately absent

- Sorting/filtering controls. The list is newest-first, server-order, matching every other list in
  this app (`GET /requests/me`, `GET /matches/me`) — a donor with three donations has no list to
  sort.
- A "lives helped" or units-multiplied number. See above.
- Walk-in donation entry from the donor side. `contract.md`'s `confirm-donation` is hospital-staff
  only; a donor cannot self-report a donation (the whole point of FR-08 is that a hospital confirms
  it).
