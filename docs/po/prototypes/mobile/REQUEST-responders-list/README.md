# REQUEST-responders-list (mobile)

**Milestone:** M4 wireframe · freeze before M4 build
**FR:** [`FR-REQUEST-002-respond-accept-decline`](../../../features/FR-REQUEST-002-respond-accept-decline.md),
[`FR-MATCH-001-donor-matching`](../../../features/FR-MATCH-001-donor-matching.md)

> **Late.** This flow was due before M4 build per `../../roadmap.md`. Mobile build (M4 backend
> 2026-08-19, M4 Flutter client 2026-08-22) shipped without it. Written now, after the fact, because
> the gap it exposes is real: `RequestViews` on the backend has no branch that shows a requester
> anything about *who* accepted — only `acceptedCount`. This prototype is what should have settled
> that before code was written.

## Question this settles

What does a requester see as donors accept? `NOTIFY-donor-alert` screen 2 promises **"mutual
reveal, one direction at a time"** — but mutual implies the requester eventually sees the donor
back, and nothing on the backend does that. Which one is wrong: the promise, or the build?

## Answer

**The promise was wrong. Reveal stays one-directional.** A requester sees a *count* going up
(`acceptedCount`), never a name, phone, or blood type per acceptance.

Reasoning:

1. **ADR 0003 protects donor location; it says nothing about donor identity — but the omission was
   never a decision, it was silence.** A donor's phone number is exactly the kind of fact that
   should get the same explicit allow-list treatment ADR 0003 gives coordinates, and nobody wrote
   that ADR. Defaulting to "not exposed" until someone writes it is the safe default, not a
   workaround.
2. **The donor already called.** `NOTIFY-donor-alert` screen 3 hands the donor the requester's
   phone number specifically so the donor can call. The requester does not need the donor's number
   to receive that call — caller ID does the identification for free. Symmetric reveal solves a
   problem that does not exist and creates one that does (a stranger's number on a frightened
   family's phone).
3. **`acceptedCount` was already the number that mattered.** `REQUEST-create-urgent` screen 3 calls
   "N donors alerted" *"the single most important number on the screen... it is the metric that
   shows the app worked even before anyone accepts."* Watching it climb from 0 does the same job
   for acceptances.

## Screen — Your request, live

```
┌─────────────────────────────────┐
│  ការស្នើសុំរបស់អ្នក                  │
│  Your request                   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ A+ · ១ ឯកតា · បន្ទាន់        │  │
│  │ មន្ទីរពេទ្យកាល់ម៉ែត្រ          │  │
│  │ ● បើកចំហ / OPEN            │  │
│  └───────────────────────────┘  │
│                                 │
│  ជូនដំណឹងដល់អ្នកបរិច្ចាគ ១២ នាក់      │
│  12 donors alerted              │
│                                 │
│  ២ នាក់បានយល់ព្រម                  │
│  2 accepted                     │  ← climbs live, no identity
│                                 │
│  អ្នកបរិច្ចាគនឹងទាក់ទងអ្នកតាមទូរស័ព្ទ    │
│  A donor who accepts will call  │
│  the number you gave            │
│                                 │
│  ┌───────────────────────────┐  │
│  │  បោះបង់ការស្នើសុំ            │  │
│  │  Cancel request           │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

No list, no order, no per-donor row — there is nothing per-donor to show. "A donor who accepts
will call the number you gave" is the one line doing the work `NOTIFY-donor-alert` screen 3's
promise implied a whole screen would need.

## Cross-check against the API

`acceptedCount` already exists (`RequestViews.summary`/`detail`, computed on read from
`request_matches`). **Nothing new is needed on the backend for this answer.** The gap this
prototype closes is a documentation gap, not a missing endpoint — `NOTIFY-donor-alert.md`'s "mutual
reveal" line should be corrected to match this, not the other way around.

## What is deliberately absent

- Any donor-identifying field on any requester-facing response. If a future FR wants this
  (post-accept in-app coordination, a name without a number), it is a new `CR-PO` against
  `TM-AUTH-001`, not a field quietly added to `BloodRequestDetailResponse`.
