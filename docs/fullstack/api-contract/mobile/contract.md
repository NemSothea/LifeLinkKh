---
id: SPEC-MOBILE-API-CONTRACT
owner: Fullstack
status: draft
milestone: M1 (spec) → M3/M4 (build)
---

# Mobile API Contract (Flutter donor/requester app)

Human contract; machine twin is [`openapi.yaml`](openapi.yaml) — **openapi wins on conflict**.
Mobile requests changes via CR-MAPI ([`change-requests.md`](change-requests.md)).

Covers the 8 core FRs only ([`docs/scope.md`](../../../scope.md)). Deferred FRs have no endpoints
here, deliberately.

Base URL `/api`. All responses JSON. All errors use the shape in "Errors" below.

## Endpoints

| Method | Path | Purpose | Auth | FR | Milestone |
|--------|------|---------|------|----|-----------|
| GET  | `/health` | Liveness. No auth by design | — | — | M2 |
| POST | `/auth/google` | Exchange a Google ID token for our JWT; create the account on first sign-in | none | FR-AUTH-003 | M3 |
| POST | `/auth/fcm-token` | Register/refresh this device's FCM token | JWT | FR-NOTIFY-001 | M3 |
| GET  | `/donors/me` | Own donor profile + computed eligibility | JWT | FR-DONOR-001/002 | M3 |
| PUT  | `/donors/me` | Create or update own donor profile | JWT | FR-DONOR-001 | M3 |
| GET  | `/hospitals` | Hospital list for the request form dropdown | JWT | FR-REQUEST-001 | M4 |
| POST | `/requests` | Create an urgent request; runs matching and push | JWT | FR-REQUEST-001, FR-MATCH-001, FR-NOTIFY-001 | M4 |
| GET  | `/requests/me` | Requester's own requests, with alerted/accepted counts | JWT | FR-REQUEST-001 | M4 |
| GET  | `/requests/{id}` | Request detail. Visible to its creator, and to donors matched to it | JWT | FR-REQUEST-001/002 | M4 |
| POST | `/requests/{id}/cancel` | Creator closes the request | JWT | FR-REQUEST-001 | M4 |
| GET  | `/matches/me` | Donor inbox — requests this donor is matched to | JWT | FR-MATCH-001 | M4 |
| POST | `/matches/{id}/respond` | Accept or decline | JWT | FR-REQUEST-002 | M4 |
| GET  | `/donations/me` | Own donation history | JWT | FR-DONATION-001 | M5 |

Thirteen endpoints for the whole product. If a fourteenth appears, check it against `scope.md` first.

## Auth

`POST /auth/google` is the only unauthenticated endpoint besides `/health`.

```
POST /auth/google
{ "idToken": "eyJhbGc...", "role": "DONOR" }     // role only honoured on first sign-in

200 { "token": "<our JWT>", "user": { "id": "uuid", "role": "DONOR", "displayName": "Sothea",
                                      "isNewAccount": true } }
```

Non-negotiable server behaviour, from
[`TM-AUTH-001`](../../../security/threat-models/TM-AUTH-001-google-sign-in.md):

- Identity comes **only** from the verified token's `sub` claim. No endpoint anywhere in this contract
  accepts a user id, `uid`, or email from the client (threat S1).
- Verify signature, `aud` == our Firebase project id, `iss`, and expiry — all four. A genuine token
  from someone else's Firebase project verifies cryptographically and must still be rejected (S2).
- `role` accepts `DONOR` or `REQUESTER` only. `HOSPITAL` or `ADMIN` → **422, rejected**, not silently
  downgraded (E1). A silent downgrade hides the attempt.
- The Google ID token is never accepted on any other endpoint; use the returned JWT (S3).

All other endpoints: `Authorization: Bearer <our JWT>`.

## The three response rules that are easy to break

These are the contract, not style guidance. `TC-AUTH-001` case 12 tests them.

1. **No donor endpoint ever returns `latitude` or `longitude`** — not to a requester, not to a
   matched donor, not in an admin view. Location is `districtName`; proximity is `distanceKm`
   (ADR 0003).
2. **`distanceKm` is server-rounded to 0.5** — `2.5`, not `2.4713`. Rounding in the client leaks the
   precise value it was rounded from.
3. **Contact details appear only after acceptance.** `requesterContact` is populated on
   `GET /requests/{id}` only when the caller is a donor whose `request_matches.response =
   'ACCEPTED'`. Build DTOs as explicit allow-lists — serialising the entity is how this leaks.

## Donor profile

```
PUT /donors/me
{ "fullName": "Nem Sothea", "bloodType": "O-", "districtCode": "PP-TK",
  "latitude": 11.5730, "longitude": 104.8920,      // optional, nullable
  "lastDonationDate": "2026-06-14" }                // null = never donated

200 { "id": "uuid", "bloodType": "O-", "districtCode": "PP-TK", "districtName": "Toul Kork",
      "lastDonationDate": "2026-06-14", "isAvailable": true,
      "eligibility": { "isEligible": false, "daysRemaining": 12, "eligibleOn": "2026-08-09" } }
```

- `bloodType` must be one of the 8 ABO/Rh values. No "unknown" — an unknown type has no row in
  `blood_compatibility` and would create a profile that silently never matches.
- `districtCode` required; coordinates optional. Declining GPS must not exclude a donor (ADR 0003).
- `lastDonationDate` must not be in the future — a future date makes the donor permanently ineligible.
- **`eligibility` is computed server-side and returned.** The client never calculates the 56-day
  window; two implementations of one rule will disagree.

Coordinates are accepted on write and never returned on read. That asymmetry is intentional.

## Create a request

```
POST /requests
{ "patientBloodType": "A+", "unitsNeeded": 1, "hospitalId": "uuid", "urgency": "URGENT" }

201 { "id": "uuid", "status": "OPEN", "patientBloodType": "A+", "unitsNeeded": 1,
      "urgency": "URGENT", "hospital": { "id": "uuid", "name": "Calmette Hospital" },
      "alertedCount": 12, "acceptedCount": 0, "createdAt": "2026-08-07T09:14:00+07:00" }
```

Matching and push run **inside this request**, synchronously, because `prd.md` FR-04 requires
notification on creation. `alertedCount` is the number of `request_matches` rows written — the number
the waiting screen shows, and the one that replaces shouting into a void.

Matching applies, in order: ABO/Rh compatibility via the `blood_compatibility` join (ADR 0004),
`isAvailable`, eligibility (56 days), then distance ascending with `NULLS LAST` so district-only
donors still match.

`status` can be `OPEN`, `FULFILLED`, or `CANCELLED`. **`EXPIRED` is unreachable in this build** —
`FR-REQUEST-005` is deferred, so a request closes only when a person closes it (DEC-004).

## Donor inbox and responding

```
GET /matches/me
200 [ { "matchId": "uuid", "request": { "id": "uuid", "patientBloodType": "A+", "unitsNeeded": 1,
          "urgency": "URGENT", "hospitalName": "Calmette Hospital", "districtName": "Stung Meanchey",
          "distanceKm": 2.5, "createdAt": "..." },
        "myBloodType": "O-", "response": null, "notifiedAt": "..." } ]

POST /matches/{matchId}/respond
{ "response": "ACCEPTED" }        // or "DECLINED"

200 { "matchId": "uuid", "response": "ACCEPTED", "respondedAt": "...",
      "requesterContact": { "displayName": "Sophea", "phone": "012345678",
                            "phoneVerified": false } }
```

`myBloodType` is echoed so the app can say *"your O− blood is compatible"*. Without it, a donor who
knows they are O− and sees an A+ request assumes the app is broken.

`phoneVerified` is **always `false`** in this build and the client must show the caveat. Phone numbers
stopped being verified when auth moved to Google Sign-In (ADR 0002); returning the number without the
flag would let the app promise a call that may not connect.

A donor may respond once. A second POST → 409.

## Errors

```
{ "error": { "code": "ROLE_NOT_ALLOWED", "message": "Role must be DONOR or REQUESTER" } }
```

| Status | When |
|---|---|
| 400 | Malformed body, bad enum, future `lastDonationDate` |
| 401 | Missing/invalid/expired JWT; invalid or foreign-project Google ID token |
| 403 | Authenticated but not entitled to this resource (e.g. a request you neither created nor were matched to) |
| 404 | Unknown id — also used instead of 403 where existence itself is sensitive |
| 409 | Already responded to this match; cancelling a closed request |
| 422 | Semantically invalid: `role: "ADMIN"`, unknown blood type, `unitsNeeded < 1` |
| 429 | Rate limit (sign-in, request creation) |

Error messages never contain a phone number, blood type, token, or coordinate — logs and error bodies
are the least-protected copy of the data (`TM-AUTH-001` I2).

## Open — blocks M4 build

| Item | Why it blocks |
|---|---|
| **Max notified donor count** | `alertedCount` implies a cap; `FR-MATCH-001` says configurable with no default. Too few and requests go unanswered, too many and donors learn to ignore alerts. Tech Lead call |
| **In-app messaging** | `NOTIFY-donor-alert` screen 3 shows a message fallback because the phone number is unverified, and `docs/risks.md` names FCM coordination as *the* mitigation. There is no FR and no endpoint for it. Either add a minimal thread at M4 or accept phone-only and correct the risk register |
| **District list** | `districtCode` values for Phnom Penh's 14 districts, seeded in `V1__init.sql`. Not written |
| **Hospital seed rows** | `GET /hospitals` needs real rows with coordinates. Not written |
