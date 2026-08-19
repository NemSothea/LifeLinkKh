# CR-MAPI — Mobile → Fullstack (mobile API changes)
next: 004

One log for all mobile-driven API change requests. Body: Ask / Why / Resolution.

| ID | Ask | Status |
|----|-----|--------|
| CR-MAPI-001 | `districtName` becomes `{ km, en }` instead of a single string | **accepted** 2026-08-18 |
| CR-MAPI-002 | Add `GET /districts` — the dropdown has no source of options | **accepted** 2026-08-18 |
| CR-MAPI-003 | A request carries its own contact; `Hospital.districtName` becomes `{ km, en }`; drop the duplicate on `BloodRequestDetail` | **accepted** 2026-08-19 |

---

## CR-MAPI-001 — `districtName` carries both labels

**Ask.** Change `DonorProfile.districtName` from `string` to `{ km: string, en: string }`.

**Why.** The contract's single string never said which language, and the backend cannot pick one
without reading a user language preference and choosing on the client's behalf. The app switches
locale at runtime (`FR-GLOBAL-001`) — with one label, changing language mid-session shows the donor a
district name in the language they just left, or forces a re-fetch of the profile to re-render a
label. Returning both keeps a presentation decision out of the API.

This was already flagged as owed in `docs/fullstack/specs/features/donor-profile.md`; the backend
merged `DistrictName(km, en)` ahead of the CR, so this closes the gap rather than opening one.

**Resolution.** Accepted. `openapi.yaml` now defines `DistrictName` and `DonorProfile.districtName`
references it. No code change: `DonorProfileResponse.DistrictName` already had this shape.

---

## CR-MAPI-002 — `GET /districts`

**Ask.** A new authenticated endpoint returning every district as `{ code, nameKm, nameEn }`, sorted
by Khmer name.

**Why.** `PUT /donors/me` requires `districtCode`, and `districts.code` is a foreign key — an unknown
code is a 422. Nothing in the contract told the client what the valid codes are, which left two
options: bundle the list in the app, or invent one. A bundled list goes stale silently and the failure
lands on a donor who cannot act on it ("that district is not valid" for a district they live in).

Sorting belongs on the server so both clients agree, and because Postgres' Khmer collation depends on
the container's locale — a sort that changes with the base image is worse than one that is slightly
wrong.

**Resolution.** Accepted and built: `DistrictController`, `DistrictResponse`, three web-slice tests.
Authenticated like everything else — the list is 14 public place names, but the deny-by-default chain
permits exactly three things and a fourth added for convenience is how that property erodes.

---

## CR-MAPI-003 — the accept flow had nobody to call

**Ask.** Three changes, one of them load-bearing:

1. `RequestCreate` gains **`contactName`** and **`contactPhone`**, both required.
2. `Hospital.districtName` changes from `string` to the shared `DistrictName` object.
3. `BloodRequestDetail.districtName` is **removed**.

**Why.**

The first is the real one. `RequesterContact` is required to carry a `displayName` and a `phone`, and
**nothing in the database could produce either.** The display name arrives inside the Google ID token
and is used once at sign-in — `users` has no name column. The phone field was dropped from sign-up
when auth moved to Google Sign-In (ADR 0002), so `users.phone` is nullable and nothing ever writes it.
A donor who accepted a request would have reached the one screen the entire accept flow exists to
produce, and found it blank.

Putting the contact on the **request** rather than on the account is better than back-filling the
account, not just easier. The person posting may be posting for someone else — a neighbour, a nurse,
a relative calling from another province — and the number that matters is the one answering at the
hospital tonight, not the one attached to a Google login. It also keeps the number scoped: it exists
on one request, is revealed only to donors who accepted that request, and does not become a permanent
account attribute. `phoneVerified` stays hard-coded `false`; nothing in this build verifies a number.

The second is CR-MAPI-001 applied where it was missed. That CR changed `DonorProfile.districtName` to
`{ km, en }` for a reason that has nothing to do with donors specifically — the app switches locale at
runtime (`FR-GLOBAL-001`), so a server that picks a language forces a re-fetch on every switch.
`Hospital` kept the old single string, which would have shown a hospital's district in the language
the user just left.

The third removes a duplicate. `BloodRequestDetail` listed its own `districtName` alongside the
`hospital` object that already carries one. Two fields holding the same value drift, and the drift
shows up as a request detail disagreeing with the hospital picker on the previous screen.

**Resolution.** Accepted and built. `V5__request_contact.sql` adds `contact_name` and `contact_phone`
to `blood_requests` as NOT NULL with no default — the table is empty, so there is no row to back-fill
and a default would let a future insert omit the one field the accept flow depends on.
`district.dto.DistrictName` is now one shared record used by donor profile, hospital and request
detail. `openapi.yaml` is at 0.3.0.
