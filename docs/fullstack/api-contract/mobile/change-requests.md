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

---

## CR-MAPI-004 — `PUT /donors/me` gains `updateCoordinates`

**Ask.** Add a boolean `updateCoordinates` (default `false`) to `DonorProfileWrite`. `latitude`/
`longitude` are applied — including an explicit clear when both are null — only when it is `true`.
When it is `false` or absent, stored coordinates are left exactly as they are, whatever `latitude`/
`longitude` carry.

**Why.** M6 wires `geolocator` into `DONOR-profile-setup`'s "use my current location" button
(`FR-DONOR-001`), which is the first thing that ever populates these columns. That exposed a landmine
flagged since M3 (`DonorService.draftFrom`, mobile): response rule 1 means no endpoint — including
`GET /donors/me` for the owner — ever returns `latitude`/`longitude` (ADR 0003, unconditionally, no
self-view exception). A client editing an existing profile therefore has no value to resend, and the
old `PUT` semantics (`profile.setLatitude(body.latitude())` unconditionally) treated every omitted
pair as "clear." A donor who edited their name or last-donation date — never touching location — would
silently lose the GPS precision that ranks them ahead of district-only donors, with no error and no
way to notice.

Three candidates were on the table (mobile's own comment named them): a `PUT` that treats omitted
coordinates as unchanged, a `PATCH`, and an edit screen that always re-acquires GPS. The last was
rejected — it would demand a fresh location permission prompt on every edit, including edits that
have nothing to do with location, and would still lose precision outright for a donor who declines.
A separate `PATCH` was rejected as more surface for one flag's worth of behavior. Exposing coordinates
back through `GET /donors/me` for self only was considered and rejected too — rule 1 is written as an
absolute ("no donor endpoint ever returns latitude or longitude"), not "no other user," and weakening
it for a case this narrow is not worth reopening a documented invariant that `TC-AUTH-001` asserts
against.

An explicit flag needs no server-side "was this JSON key present" trick — Jackson cannot distinguish
an absent key from an explicit `null` on a plain record without extra machinery, and this problem
does not need that machinery. It mirrors the pattern the client already uses locally for "I have
never donated" (`DonorProfileDraft.clearLastDonationDate`): an explicit signal, not null-as-overload.

**Resolution.** Accepted and built. `DonorProfileWriteRequest.updateCoordinates` (`Boolean`, same
nullable-wrapper style as `isAvailable`). `DonorService.save` only writes and only pair-validates
`latitude`/`longitude` when it is `true`. No response schema changed; rule 1 is untouched.
`openapi.yaml` is at 0.4.0.
