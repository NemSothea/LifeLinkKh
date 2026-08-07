# REQUEST-create-urgent (mobile)

**Milestone:** M1 wireframe · freeze before M4 build
**FR:** [`FR-REQUEST-001-create-urgent-request`](../../../features/FR-REQUEST-001-create-urgent-request.md),
[`FR-MATCH-001-donor-matching`](../../../features/FR-MATCH-001-donor-matching.md)

## Question this settles

Can a panicking family finish this in under a minute? (`prd.md` FR-04 user story.)

## Answer

**Yes — four required fields on one screen, no wizard.** Blood type, units, hospital, urgency. A
multi-step flow is correct for donor onboarding, which happens once when calm, and wrong here, which
happens once while frightened. One screen means the user can see the end from the start.

Defaults do the rest: units = 1, urgency = `URGENT`, hospital = nearest by GPS if available. A
family that changes nothing still submits something valid.

> Khmer strings are a first pass — native check needed before M4.

## Screen 1 — Request form

```
┌─────────────────────────────────┐
│  ← ស្នើសុំឈាមបន្ទាន់                 │
│    Request blood                │
│                                 │
│  ក្រុមឈាមអ្នកជំងឺ  *                │
│  Patient blood type  *          │
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
│  ចំនួនឯកតា  *                     │
│  Units needed  *                │
│      ┌───┐  ┌─────┐  ┌───┐      │
│      │ − │  │  1  │  │ + │      │
│      └───┘  └─────┘  └───┘      │
│                                 │
│  មន្ទីរពេទ្យ  *                    │
│  Hospital  *                    │
│  ┌───────────────────────────┐  │
│  │ មន្ទីរពេទ្យកាល់ម៉ែត្រ        ▾ │  │
│  │ Calmette Hospital         │  │
│  └───────────────────────────┘  │
│                                 │
│  ភាពបន្ទាន់  *                    │
│  Urgency  *                     │
│  ┌─────────┬─────────┬───────┐  │
│  │បន្ទាន់បំផុត│  បន្ទាន់  │ ធម្មតា │  │
│  │CRITICAL │ URGENT  │ROUTINE│  │
│  └─────────┴─────────┴───────┘  │
│            ▲ selected           │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ស្នើសុំឥឡូវ / Send request │  │  ← blood-red, full width
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

The same 8-button grid as donor setup — one learned interaction, used twice.

Urgency is a 3-segment control, not a dropdown, because it changes nothing about the form and
everything about how the request reads to a donor.

## Screen 2 — Confirm

```
┌─────────────────────────────────┐
│  បញ្ជាក់ការស្នើសុំ                   │
│  Confirm request                │
│                                 │
│  ┌───────────────────────────┐  │
│  │  A+   ·  ១ ឯកតា / 1 unit  │  │
│  │  មន្ទីរពេទ្យកាល់ម៉ែត្រ         │  │
│  │  Calmette Hospital        │  │
│  │  បន្ទាន់ / URGENT           │  │
│  └───────────────────────────┘  │
│                                 │
│  យើងនឹងជូនដំណឹងទៅអ្នកបរិច្ចាគ         │
│  ដែលអាចផ្តល់ឈាមបាន និងនៅជិត         │
│  We will alert donors who can   │
│  give A+ blood and are nearby   │
│                                 │
│  ⓘ រួមបញ្ចូល O−, O+, A− ផងដែរ       │
│    Includes O−, O+ and A−       │
│    donors, not only A+          │
│                                 │
│  ┌──────────┐ ┌──────────────┐  │
│  │ កែប្រែ    │ │ បញ្ជូន / Send │  │
│  │ Edit     │ │              │  │
│  └──────────┘ └──────────────┘  │
└─────────────────────────────────┘
```

The ⓘ line exists to stop the most likely support question — *"why did an O− donor get my A+
request?"* It is ADR 0004's compatibility table made visible, and it also quietly tells the family
their odds are better than they think.

One confirm step only. It is the difference between a mis-tapped blood type and a wasted alert to
every O− donor in the city.

## Screen 3 — Waiting for responders

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
│  ────────────────────────────   │
│  អ្នកឆ្លើយតប / Responses         │
│                                 │
│      ⧗  កំពុងរង់ចាំ...            │
│         Waiting for the first   │
│         donor to accept         │
│                                 │
│  ────────────────────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │  បោះបង់ការស្នើសុំ            │  │
│  │  Cancel request           │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

"12 donors alerted" is the single most important number on the screen. It replaces the Facebook-post
feeling of shouting into a void, and it is the metric that shows the app worked even before anyone
accepts.

Once a donor accepts, this list fills — that is `REQUEST-responders-list`, an M4 prototype, not this
one.

**Cancel, not expire.** `status = 'EXPIRED'` is unreachable in this build (DEC-004), so the only way
a request closes is a person closing it. That is a deliberate limit, not an omission.

## Cross-check against the API

`patient_blood_type`, `units_needed`, `hospital_id`, `urgency`, `status` — all present in
`blood_requests`. "12 donors alerted" is a count of `request_matches` rows for this request, which
exists because matching writes them (`data-model.md`).

The hospital dropdown reads `hospitals`, which needs seed rows in `V1__init.sql` — Phnom Penh
hospitals with `latitude`/`longitude`. **Not yet written.**

## Open — blocks M4

**Max notified donor count.** "12 donors alerted" implies a cap and there is no agreed default
(`FR-MATCH-001`). Too few and the request goes unanswered; too many and donors learn to ignore
alerts. This is the last unresolved item on the matching path and it is a Tech Lead call.
