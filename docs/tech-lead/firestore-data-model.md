# Firestore data model

> ADR 0009. The PostgreSQL schema (`backend/src/main/resources/db/migration/`) mapped to Firestore
> collections. `firebase/firestore.rules` enforces who reads and writes each one, and
> `firebase/rules-tests/` has a test for every rule below. When this file and the rules disagree,
> the rules are what runs — fix this file.

## Principals

| Who | How the rules know | Can |
|---|---|---|
| Anyone, signed out | no `request.auth` | Read the public board: `requests`, `requests/*/acceptedDonors`, `hospitals`, `districts` |
| Mobile user | signed in, **no** `role` claim | Own `users` and `donors` doc; post and cancel own requests; answer own matches |
| Hospital staff | claim `role == 'HOSPITAL'` + `hospitalId` | Read matches and donations at their hospital |
| Admin | claim `role == 'ADMIN'` | Read everything |

Claims are set only by a Cloud Function (Admin SDK). Every write the rules refuse to a client —
match creation, counts, donations, `lastDonationDate` after a confirmed donation — is a Function's job.

## Collections

### `users/{uid}` — was `users`
`displayName` string · `language` `'km'|'en'` · `role` `'DONOR'|'REQUESTER'` · `fcmToken` string|null ·
`createdAt` · `updatedAt`

Created by the app's first push registration, not at sign-in. Owner and admin read. Owner writes. Staff roles are **not** here — they are claims, so a client
cannot promote itself by writing a field. `fcmToken` is private for the same reason it was: it can
address a push to this person.

### `donors/{uid}` — was `donor_profiles`
`fullName` · `bloodType` (8 ABO/Rh values) · `districtCode` (must exist in `districts`) ·
`lastDonationDate` timestamp|null (not in the future) · `isAvailable` bool ·
`lat`, `lng`, `geohash` — all three null or all three set (ADR 0003: declining GPS is allowed) ·
`createdAt` · `updatedAt`

Doc id is the uid — one profile per account, which was `UNIQUE (user_id)`. Owner and admin read;
**nobody else**, not even staff. Matching reads it through the Admin SDK.

### `requests/{requestId}` — was `blood_requests`
`createdBy` uid · `hospitalId` · `hospital` {name, districtCode} (written by the Function) ·
`patientBloodType` · `unitsNeeded` 1–20 · `urgency` `'CRITICAL'|'URGENT'|'ROUTINE'` ·
`status` `'OPEN'|'FULFILLED'|'CANCELLED'|'EXPIRED'` · `alertedCount` · `acceptedCount` ·
`createdAt` · `updatedAt` · and three the `onRequestCreated` Function adds: `matchedAt` (its
at-most-once claim — a redelivered event that finds it set does nothing), `hospital`, and
`cancelReason: 'RATE_LIMITED'` on the sixth request from one creator inside ten minutes.

**Public read** — this document is the public board (DEC-009), so nothing on it is private.
Create: signed in, `createdBy` is you, `status OPEN`, counts `0`. Update: the creator may move
`OPEN → CANCELLED` and touch nothing else. Counts and `FULFILLED` belong to Functions.

### `requests/{requestId}/private/contact` — was `contact_name`, `contact_phone`
`contactName` 1–120 · `contactPhone` normalized `+855…` Cambodian mobile

Split out because a rule cannot hide one field of a readable document. Read by the creator, an
admin, and **a donor whose match on this request says `ACCEPTED`** — the `requesterContact` rule
from `RequestViews`. Created by the creator only, in the same batch as the request. Never updated.

### `requests/{requestId}/acceptedDonors/{donorUid}` — the board's `acceptedDonors`
`displayName` · `bloodType` · `districtCode` · `respondedAt`

Public read, Function write. Same fields as `PublicDonorResponse`: no match id, no uid in the body.

### `matches/{requestId}_{donorUid}` — was `request_matches`
`requestId` · `donorUid` · `requesterUid` · `hospitalId` · `distanceKm` number|null ·
`notifiedAt` · `response` `null|'ACCEPTED'|'DECLINED'` · `respondedAt`

The composite id is `UNIQUE (blood_request_id, donor_profile_id)`. Created only by
`onRequestCreated`, so only notified donors have one (ADR 0008). Read by that donor, staff of
that hospital, and admin. The donor may set `response` **once** (`null → ACCEPTED|DECLINED`, with
`respondedAt == request.time`) while the request is `OPEN`. A replayed answer is refused by the
rules — the client treats `permission-denied` on an already-answered match as success.

### `donations/{donationId}` — was `donations`
`donorUid` · `hospitalId` · `requestId`|null · `donatedOn` · `confirmedBy` · `createdAt`

Read by the donor, staff of that hospital, and admin. Written only by the `confirmDonation`
Function, which also sets `donors/{uid}.lastDonationDate` and may mark the request `FULFILLED`.

### `hospitals/{id}`, `districts/{code}` — reference data
Public read, no client write. Seeded by `firebase/seed/` from the same values as V3 and V7.

## Not carried over

- `blood_compatibility` — a constant in the Functions code (still a table, ADR 0004).
- `telegram_auth_challenges` — Telegram sign-in dropped in phase 1 (ADR 0009).
- `username`, `password_hash`, `deactivated_at` — Firebase Auth owns credentials and disabling.
