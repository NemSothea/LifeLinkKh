# PORTAL-open-requests (web)

**Milestone:** M4 wireframe · freeze before M4 build
**FR:** [`FR-PORTAL-001-hospital-request-management`](../../../features/FR-PORTAL-001-hospital-request-management.md)
**Also referenced as** `PORTAL-hospital-requests` in the FR doc — same flow, one folder, this name
kept because it matches `../../roadmap.md`.

> **Late, like `../../mobile/REQUEST-responders-list/`.** Due before M4 build; never drafted as a
> wireframe. Unlike that one, the API-level answer already exists in full —
> [`docs/fullstack/api-contract/web/contract.md`](../../../../fullstack/api-contract/web/contract.md)
> — nobody skipped the design question, they skipped writing it as a picture. What is actually
> missing is the build: **no `backend/.../portal/` package exists, and `frontend/src` has no request
> page.** `GET /donations/me` (M5, 2026-08-22) reads a table nothing writes to, because
> `POST /portal/requests/{id}/confirm-donation` — the only write path to `donations` — was never
> built. The donation-history feature is currently a read endpoint over a permanently empty table.

## Question this settles

What does hospital staff see and do on the one portal page (`scope.md`'s DEC-004 trim: "a table of
open requests," not a management console)?

## Answer

A table, one row per open request, each row expandable to its accepted donors, each donor row
carrying a "confirm donation" action. Matches `contract.md`'s `GET /portal/requests` and
`POST /portal/requests/{id}/confirm-donation` exactly — this wireframe adds no field the contract
does not already have.

## Screen — Open requests

```
┌────────────────────────────────────────────────────────────┐
│  LifeLink KH — Calmette Hospital                    [sign out] │
├────────────────────────────────────────────────────────────┤
│  Open requests                                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ A+ · 1 unit · URGENT · alerted 12 · accepted 1     ▾ │  │
│  │   Sophea · O− · Tuol Kouk · accepted 09:20    [Confirm donation] │
│  ├──────────────────────────────────────────────────────┤  │
│  │ O− · 2 units · CRITICAL · alerted 25 · accepted 0  ▾ │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ B+ · 1 unit · ROUTINE · alerted 4 · accepted 2      ▸ │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

`acceptedDonors` is the reveal a mobile requester never gets (`REQUEST-responders-list`, next door)
— hospital staff coordinate arrivals, so they need the name and blood type a requester does not.
No `latitude`/`longitude`, no unrounded distance, same rule as everywhere else (ADR 0003).

**"Confirm donation" opens one field: a date, defaulting to today, capped at today.** It is the
only write in this screen — the row's `donatedOn` — and closes to
`POST /portal/requests/{id}/confirm-donation`.

A confirmed row shows `requestStatus` inline (`FULFILLED` once `unitsNeeded` is met) rather than
disappearing, so staff can see today's work at a glance.

## Sign-in

No screen. `contract.md` reuses `POST /auth/google`: staff sign in with the same Google button the
mobile app uses, against an account seeded with `role: HOSPITAL`. `AUTH-portal-signin` was dropped
at M3 for exactly this reason (`../../roadmap.md`).

## What is deliberately absent

- Request creation, donor search/browse, admin metrics — all out per `contract.md`'s "Not here,
  deliberately" and `scope.md`'s deferred list (`FR-PORTAL-002`).
- The alerted-but-silent 11 donors on an unaccepted request. Not shown, ever — their blood type and
  district would be exposed for no operational reason (`TM-AUTH-001` I1).

## Blocks M4/M5 build

- `backend/.../portal/PortalController` (or equivalent) implementing both endpoints —
  does not exist yet.
- `frontend/src/app/[locale]/portal/` — does not exist yet.
- Until `confirm-donation` is built, `donations` never gets a row from the app itself, and
  `GET /donations/me` has nothing real to show in a demo. This blocks the M5 acceptance criterion
  more than any mobile screen does.
