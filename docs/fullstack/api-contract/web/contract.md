---
id: SPEC-WEB-API-CONTRACT
owner: Fullstack
status: draft
milestone: M1 (spec) → M5 (build)
---

# Web API Contract (hospital portal)

Human contract; machine twin is [`openapi.yaml`](openapi.yaml) — **openapi wins on conflict**.

**Scope: three endpoints.** `FR-PORTAL-001` was trimmed by DEC-004 to a single page — a table of open
requests plus the action to confirm a donation. `FR-PORTAL-002` (admin dashboard) is deferred, so
there is no metrics endpoint here ([`docs/scope.md`](../../../scope.md)).

## Endpoints

| Method | Path | Purpose | Auth | FR |
|--------|------|---------|------|----|
| POST | `/auth/google` | Sign in. Same endpoint as mobile | none | FR-AUTH-003 |
| GET  | `/portal/requests` | Open requests table | JWT (HOSPITAL/ADMIN) | FR-PORTAL-001 |
| POST | `/portal/requests/{id}/confirm-donation` | Record a donation against a request | JWT (HOSPITAL/ADMIN) | FR-DONATION-001 |

## Sign-in reuses the mobile endpoint

No separate portal auth flow, and no `FR-AUTH-004`. Hospital staff sign in with Google exactly like a
donor; the difference is that their account **already exists with `role: HOSPITAL`**, seeded by
migration.

This works because `POST /auth/google` honours the `role` field only on first sign-in — an existing
account returns its stored role and ignores anything the client sends. So a privileged account cannot
be created through the front door (`TM-AUTH-001` E1), and a seeded one signs in with no extra code.

> **The seeding itself is an unreviewed privileged path.** Creating the first `HOSPITAL`/`ADMIN` rows
> in `V1__init.sql` bypasses every check in the application. Flagged in `TM-AUTH-001` residual risk;
> it needs its own security review when the migration is written, not after.

RBAC is enforced server-side on both `/portal/*` endpoints. A `DONOR` JWT reaching them gets 403 — the
portal not linking to them is not a control.

## Open requests table

```
GET /portal/requests?status=OPEN

200 [ { "id": "uuid", "patientBloodType": "A+", "unitsNeeded": 1, "urgency": "URGENT",
         "status": "OPEN", "hospital": { "id": "uuid", "name": "Calmette Hospital" },
         "alertedCount": 12, "acceptedCount": 1,
         "createdAt": "2026-08-07T09:14:00+07:00",
         "acceptedDonors": [ { "matchId": "uuid", "displayName": "Sothea",
                               "bloodType": "O-", "districtName": "Toul Kork",
                               "respondedAt": "..." } ] } ]
```

`acceptedDonors` contains **only donors who have accepted**. A hospital does not see the alerted-but-
silent list — that is 11 people's blood type and district for no operational reason
(`TM-AUTH-001` I1).

No `latitude`, no `longitude`, no unrounded distance — the same rule as the mobile contract, and the
one most likely to be broken here by serialising the entity for a table view (ADR 0003). Distance is
omitted entirely rather than shown, because a hospital does not route donors.

Hospital staff see requests for **their own hospital**; `ADMIN` sees all. Scoped server-side from the
JWT, never from a query parameter.

## Confirm a donation

```
POST /portal/requests/{id}/confirm-donation
{ "matchId": "uuid", "donatedOn": "2026-08-07" }

201 { "id": "uuid", "donorDisplayName": "Sothea", "donatedOn": "2026-08-07",
      "requestStatus": "FULFILLED", "donorNextEligibleOn": "2026-10-02" }
```

**This is the only write path to `donations` in the entire product.** `FR-DONATION-001` (the donor's
history) and `FR-DONOR-002` (the 56-day cooldown) both read from it, so if this endpoint is skipped at
M5 the history screen is permanently empty and every donor stays eligible forever.

One call does three things, in one transaction:

1. Insert `donations` — `donor_profile_id`, `hospital_id`, `blood_request_id`, `donated_on`,
   `confirmed_by_user_id` = the staff member.
2. Update `donor_profiles.last_donation_date`. It is a cache of `MAX(donations.donated_on)`
   (`data-model.md`) and must not drift from the row just written.
3. Set `blood_requests.status = 'FULFILLED'` when `unitsNeeded` is met.

`donatedOn` must not be in the future. `matchId` must belong to this request and be `ACCEPTED` —
confirming a donation from a donor who never accepted would silently start their 56-day cooldown.

`donorNextEligibleOn` is returned so staff can tell the donor when to come back, which is the
information the donor actually wants at that moment.

## Errors

Same shape and status meanings as the [mobile contract](../mobile/contract.md#errors).
`403` on `/portal/*` for a non-privileged role; `409` when the match is already confirmed.

## Not here, deliberately

- Admin metrics/dashboard — `FR-PORTAL-002` deferred. The five PRD metrics come from SQL `COUNT`
  queries at demo time (DEC-004).
- Request creation from the portal. Hospitals could plausibly need it, but `prd.md` has the requester
  creating requests on mobile and nothing in the graded set requires a second path.
- Donor search or browse. There is no endpoint that lists donors to a human, at all. Matching returns
  them to the server for notification only.
