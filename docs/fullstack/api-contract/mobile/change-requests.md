# CR-MAPI — Mobile → Fullstack (mobile API changes)
next: 003

One log for all mobile-driven API change requests. Body: Ask / Why / Resolution.

| ID | Ask | Status |
|----|-----|--------|
| CR-MAPI-001 | `districtName` becomes `{ km, en }` instead of a single string | **accepted** 2026-08-18 |
| CR-MAPI-002 | Add `GET /districts` — the dropdown has no source of options | **accepted** 2026-08-18 |

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
