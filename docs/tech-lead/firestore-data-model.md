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
| Admin | claim `role == 'ADMIN'` **and** an `admins/{uid}` record | Read everything; the portal |

v1 has no hospital staff (DEC-014). The claim and the record are both written by
`firebase/seed/admin.mjs` (Admin SDK). The rules require both: a claim outlives a revoke by up to
an hour, the record does not. Every write the rules refuse to a client —
match creation, counts, donations, `lastDonationDate` after a confirmed donation — is the portal's functions' (ADR 0010; Cloud Functions before) job.

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
`lat`, `lng`, `geohash` — all three null or all three set (ADR 0003: declining GPS is allowed),
geohash at most 10 characters · `sex` `'M'|'F'|null` (DEC-019) · `createdAt` · `updatedAt`

Doc id is the uid — one profile per account, which was `UNIQUE (user_id)`. Owner and admin read;
**nobody else**, not a requester. Matching reads it through the Admin SDK. The portal asks only
for the fields it shows (`fullName`; the dashboard's four) — never the coordinates (ADR 0003
amendment, SEC-REVIEW-003 F-11). Once set, `lastDonationDate` only moves later and `sex` does not
change: both set the cooldown matching reads (F-04).

### `requests/{requestId}` — was `blood_requests`
`createdBy` uid · `hospitalId` · `hospital` {name, districtCode} (written by `createRequest`) ·
`patientBloodType` · `unitsNeeded` 1–20 · `urgency` `'CRITICAL'|'URGENT'|'ROUTINE'` ·
`status` `'PENDING'|'OPEN'|'REJECTED'|'FULFILLED'|'CANCELLED'|'EXPIRED'` · `alertedCount` · `acceptedCount` ·
`createdAt` · `updatedAt` · and three the approval adds: `matchedAt` (its
at-most-once claim — a redelivered event that finds it set does nothing), `hospital`, and
`cancelReason: 'RATE_LIMITED'` on the sixth request from one creator inside ten minutes.

**Public read once approved** — this document is the public board (DEC-009), so nothing on it is private.
Create: signed in, `createdBy` is you, `status PENDING`, counts `0`. Update: the creator may move
`PENDING|OPEN → CANCELLED` and touch nothing else. Creating one, counts and `FULFILLED` belong to the portal's functions (ADR 0010).

**Review (DEC-015).** A request starts `PENDING`: not on the public board, alerting nobody. The
`reviewRequest` callable (admin only) moves it to `OPEN` — the `onRequestApproved` trigger then
matches and alerts — or to `REJECTED` with `rejectReason` (1–200 characters, shown to the
requester). Both write `reviewedBy` and `reviewedAt`. `PENDING` and `REJECTED` are readable only by
the creator and the admin, so the read rule above is public only for `OPEN`, `FULFILLED`,
`CANCELLED` and `EXPIRED`, and a list query must filter on one of those statuses (the board asks
for `OPEN`).

### `requests/{requestId}/private/contact` — was `contact_name`, `contact_phone`
`contactName` 1–120 · `contactPhone` normalized `+855…` Cambodian mobile

Split out because a rule cannot hide one field of a readable document. Read by the creator, an
admin, and **a donor whose match on this request says `ACCEPTED`** — the `requesterContact` rule
from `RequestViews`. Created by the creator only, in the same batch as the request. Never updated.

### `requests/{requestId}/acceptedDonors/{boardId}` — the board's `acceptedDonors`
`displayName` · `bloodType` · `districtCode` · `respondedAt`

Public read, server write. Same fields as `PublicDonorResponse`: no match id, no uid in the body
— and, since SEC-REVIEW-003 F-11, none in the id either: `boardId(requestId, donorUid)` is the
first 24 hex characters of `sha256("{requestId}:{donorUid}")` (`frontend/src/server/board-id.js`),
so one donor's rows on two requests cannot be linked. Rows written before that are keyed by the
uid; `deleteAccount` removes both kinds, and the portal resolves both through `matches`.

### `matches/{requestId}_{donorUid}` — was `request_matches`
`requestId` · `donorUid` · `requesterUid` · `hospitalId` · `distanceKm` number|null ·
`notifiedAt` · `response` `null|'ACCEPTED'|'DECLINED'` · `respondedAt`

The composite id is `UNIQUE (blood_request_id, donor_profile_id)`. Created only by
`onRequestCreated`, so only notified donors have one (ADR 0008). Read by that donor and the
admin. The donor may set `response` **once** (`null → ACCEPTED|DECLINED`, with
`respondedAt == request.time`) while the request is `OPEN`. A replayed answer is refused by the
rules — the client treats `permission-denied` on an already-answered match as success.

### `donations/{donationId}` — was `donations`
`donorUid` · `hospitalId` · `requestId`|null · `donatedOn` · `confirmedBy` · `createdAt`

Read by the donor and the admin. Written only by the `confirmDonation`
function, which also sets `donors/{uid}.lastDonationDate` and may mark the request `FULFILLED`.

### `admins/{uid}` — was `users.role = 'ADMIN'`, `users.username`
`displayName` · `username` · `updatedAt`

The second half of `isAdmin()`. Read only by that admin; written only by `seed/admin.mjs`.
Deleting it ends the admin's access on the next request; disable the Auth user as well, so they
cannot sign in again.

### `hospitals/{id}`, `districts/{code}` — reference data
Public read, no client write. Seeded by `firebase/seed/` from the same values as V3 and V7.

## Not carried over

- `blood_compatibility` — a constant in the matching code, `frontend/src/server/matching.js` (still a table, ADR 0004).
- `telegram_auth_challenges` — Telegram sign-in dropped in phase 1 (ADR 0009).
- `password_hash`, `deactivated_at` — Firebase Auth owns credentials and disabling. The username
  is kept on `admins/{uid}` and is the Auth email's local part (`{username}@portal.lifelink.invalid`).
- `users.hospital_id` and the `HOSPITAL` role — v1 has no hospital staff (DEC-014).
