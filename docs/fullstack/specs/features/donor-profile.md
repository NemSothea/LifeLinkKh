---
id: SPEC-DONOR-PROFILE
owner: Fullstack
status: draft — awaiting Tech Lead + Security sign-off (R5 applies)
milestone: M3
fr_ref: ../../../po/features/FR-DONOR-001-donor-profile.md
adr_ref: ../../../tech-lead/adr/0003-donor-location-precision.md
contract: ../../api-contract/mobile/contract.md
---

# M3 Build Spec — Donor profile

| Method | Path | Auth | FR |
|---|---|---|---|
| GET | `/donors/me` | JWT | `FR-DONOR-001`, `FR-DONOR-002` |
| PUT | `/donors/me` | JWT | `FR-DONOR-001` |

Depends on [`auth-google-sign-in.md`](auth-google-sign-in.md) — there is no "me" before there is a
JWT subject.

## The schema gap that has to close first

`DonorProfile` in `openapi.yaml` lists **`districtName` as required**. Nothing can supply it.
`V1__init.sql` has `donor_profiles.district_code VARCHAR(16) NOT NULL` as a bare string with no
table behind it, no foreign key, and no name — Khmer or Latin — anywhere in the database.

So M3 needs a migration before it needs a controller:

### `V2__districts.sql`

```sql
CREATE TABLE districts (
    code       VARCHAR(16)  PRIMARY KEY,
    name_km    VARCHAR(80)  NOT NULL,
    name_en    VARCHAR(80)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
-- + 14 seeded rows
-- + ALTER TABLE donor_profiles
--     ADD CONSTRAINT donor_profiles_district_fk
--     FOREIGN KEY (district_code) REFERENCES districts (code);
```

Reference data seeded in its own migration, the way `blood_compatibility` was (ADR 0004) — not
application inserts, not a data-loader bean. The content comes from
[`reference/phnom-penh-districts.md`](../../../po/reference/phnom-penh-districts.md), which PO owns.

The foreign key is the point of the exercise. Without it `district_code` is a free-text field that
accepts `"toul kork"`, `"TK"`, and `"Toul  Kork"` as three different districts, and a matching query
that filters by district silently returns nothing. Adding the constraint after donor rows exist means
cleaning data first.

> **Blocked:** five of the fourteen codes (`1210`–`1214`) are marked ⚠️ unverified in the PO
> reference file, which says plainly: do not seed while any row reads ⚠️. `district_code` lands in
> `donor_profiles` rows, so a wrong code becomes a data migration rather than an edit. This is a
> ten-minute check against an official NCDD/MoI list and it blocks the migration, not the controller
> — build against the nine verified codes if it helps, but do not merge the seed.

**Language:** both `name_km` and `name_en` are stored and both are returned. `districtName` in the
contract is singular and does not say which language — resolve at sign-off. Returning both and
letting the client pick is the least surprising answer and costs one field; the alternative is the
server reading `users.language` and choosing, which puts a presentation decision in the API. This
needs a CR-MAPI either way, since it changes a response schema.

## `PUT /donors/me`

Create-or-update, keyed on the JWT subject. First call creates the row, later calls update it — the
client does not distinguish, and there is no `POST`.

### Validation

| Field | Rule | Violation |
|---|---|---|
| `fullName` | required, ≤ 120 | 400 |
| `bloodType` | required, one of the 8 | 422 |
| `districtCode` | required, must exist in `districts` | 422 |
| `latitude` / `longitude` | optional, both-or-neither | 400 |
| `lastDonationDate` | optional, **not in the future** | 422 |
| `isAvailable` | optional, defaults true | — |

Server-side, on every request, without exception (ASVS baseline, input-validation row). The client
also validates — the picker cannot select a future date (`FR-DONOR-001`) — and that is a courtesy,
not a control. A profile arriving from a replayed or hand-built request gets the same treatment.

Both-or-neither on coordinates: a latitude with no longitude is not a partial location, it is a bug,
and storing it produces a donor who is neither rankable nor obviously broken.

There is **no `phone` field**. `FR-DONOR-001` removed it 2026-08-17 and `prd.md` FR-02 was amended to
match. `users.phone` stays in the schema, nullable and unused — do not add it to this DTO to "keep
the entity complete".

There is no `userId` field either, for the same structural reason as in the auth spec: the row
written is the JWT subject's, and there is no way to express any other intent.

### Blood type has no unknown value

Enforced three deep: the OpenAPI enum, a bean-validation enum binding, and the existing
`donor_profiles_blood_type_check` CHECK constraint from `V1__init.sql`. A donor with an unknown type
cannot be matched — `blood_compatibility` has no row for it (ADR 0004) — so accepting one creates a
profile that silently never appears in results. `FR-DONOR-001` sends that donor to a hospital instead.

## `GET /donors/me`

Returns the caller's profile with computed eligibility. **404** when the user has no donor profile
yet, which is the normal state for a `REQUESTER` and for a `DONOR` mid-signup — not an error
condition to log.

### Latitude and longitude are absent from the response

Not null. **Absent** — no such field on the read DTO.

This is ADR 0003's whole point, and `docs/qa/test-strategy.md` makes it non-negotiable test 1:
asserted on the raw JSON, not on a DTO object, because serialising the entity is exactly the mistake
being guarded against. `DonorProfile` is an explicit allow-list built field by field from the entity.
Never `@JsonIgnore` on the entity, never a projection that starts from "everything minus". Those both
fail open the moment someone adds a field.

Worth stating plainly: this endpoint returns the caller's *own* profile, so exposing their own
coordinates back to them leaks nothing today. The rule is absolute anyway, because the DTO that
`GET /donors/me` returns is the DTO that `GET /matches/me` will reach for at M4, and at that point it
is someone else's coordinates.

## Eligibility — and a milestone discrepancy to settle

The contract requires `GET /donors/me` to return an `Eligibility` object: `isEligible`,
`daysRemaining`, `eligibleOn`. `FR-DONOR-001`'s save-result screen shows both the countdown and the
absolute date, and the prototype states eligibility is computed server-side and read from the
response, never calculated on the device.

**But** root `CLAUDE.md` §4 puts "eligibility computation" in M4, and the FR registry lists
`FR-DONOR-002` as "M4 computation, M5 donor status".

These cannot both hold. `GET /donors/me` cannot satisfy its own schema at M3 without the computation.

Per `docs/fullstack/CLAUDE.md` — openapi wins on conflict — this spec implements it at M3. It is a
date comparison, not a feature:

```
lastDonationDate IS NULL         → eligible, daysRemaining null, eligibleOn null
lastDonationDate + 56 days <= today → eligible
otherwise                        → not eligible, eligibleOn = lastDonationDate + 56,
                                    daysRemaining = eligibleOn - today
```

Computed in the service on read. Not stored, not cached, not a column — a stored copy is a value that
goes stale at midnight with nothing to wake it up.

**This is flagged, not decided.** Pulling work into M3 is a milestone change and belongs to Tech Lead
and PO, not Backend. Either the milestone table is amended, or the `eligibility` field leaves the M3
contract and the FR loses its result screen. Silently building it and letting the tables disagree is
the outcome to avoid — the next person reads the disagreement as an error and "fixes" the wrong side.

`donor_profiles.last_donation_date` is documented as a cache of `MAX(donations.donated_on)` with
donations winning on disagreement. At M3 the `donations` table is empty and the column is whatever
the donor typed. That is correct for now and becomes a reconciliation question at M5 —
`FR-DONOR-002` already carries the related walk-in-donation open brief.

## Authorization

Every endpoint here operates on the JWT subject's own row. No path parameter, no query filter, no
"admin can also" branch. The donor-may-read-and-write-only-their-own-profile rule from the ASVS
baseline is satisfied structurally rather than by a check that could be forgotten — there is no
identifier to tamper with.

## Package layout

```
donor/
  DonorController.java       GET/PUT /donors/me
  DonorService.java          upsert, eligibility computation
  DonorProfile.java          entity (exists since M2)
  DonorProfileRepository.java (exists since M2)
  dto/                       DonorProfileWrite, DonorProfileRead, EligibilityDto
district/
  District.java, DistrictRepository.java
```

No new third-party dependency.

## Tests

1. `latitude`/`longitude` appear nowhere in the raw JSON of `GET /donors/me` — asserted on the
   response string, not on a deserialised object (test-strategy non-negotiable 1).
2. A `PUT` body containing `userId` or `firebaseUid` writes the caller's row and only the caller's.
3. `lastDonationDate` tomorrow → 422, and no row is written.
4. An unknown `districtCode` → 422, enforced by the FK, not only by the service.
5. Eligibility boundaries: exactly 56 days ago → eligible; 55 → not, with `daysRemaining == 1`. The
   off-by-one is the whole rule.
6. `lastDonationDate` null → eligible with both nullable fields null.
7. `GET` with no profile → 404, not 500 and not an empty object.
8. Coordinates persist at `NUMERIC(8,5)` and survive a round-trip — they are unreadable through the
   API by design, so only a repository-level test can prove they were stored at all.

Test 8 matters more than it looks: an ADR-0003 violation and a silently-dropped write produce
identical API output.

## Blocked on, before this can be built

1. **District codes `1210`–`1214` unverified** — blocks `V2__districts.sql`. PO's reference file, ten
   minutes against an official list.
2. **The eligibility milestone discrepancy** above — Tech Lead + PO.
3. **`districtName` singular vs. `nameKm`/`nameEn`** — needs a CR-MAPI, since it changes a response
   schema.

## Sign-off required

R5 applies: donor blood type and location are the PII this whole baseline exists to protect. DoD
step 1 needs PO (done — `FR-DONOR-001` finalized 2026-08-17), **Tech Lead**, and **Security**.
