---
id: REF-DISTRICTS-PP
title: Phnom Penh districts — the donor location list
owner: PO
status: draft — codes need one official check before seeding
fr_ref: ../features/FR-DONOR-001-donor-profile.md
adr_ref: ../../tech-lead/adr/0003-donor-location-precision.md
---

# Phnom Penh districts (khan)

`FR-DONOR-001` makes `district_code` the **required** half of a donor's location and the only
location any other user ever sees (ADR 0003). This file is the list behind that dropdown. It was
missing, and its absence blocked the M3 build rather than the wireframe — see the closing section of
`FR-DONOR-001`.

Fourteen districts. Boeng Keng Kang and Kamboul are the two newest, split out of Chamkar Mon and
Dangkao/Pou Senchey in 2019, which is why older lists show twelve and why a stale list would silently
drop donors in the two densest new areas.

## The list

Code follows the national geocode scheme: province `12` (Phnom Penh) + a two-digit district number.
`VARCHAR(16)` per ADR 0003, so there is room if the scheme ever grows.

| `district_code` | Khmer | Latin | Verified |
|---|---|---|---|
| `1201` | ចំការមន | Chamkar Mon | ✅ |
| `1202` | ដូនពេញ | Doun Penh | ✅ |
| `1203` | ប្រាំពីរមករា | Prampi Makara | ✅ |
| `1204` | ទួលគោក | Tuol Kouk | ✅ |
| `1205` | ដង្កោ | Dangkao | ✅ |
| `1206` | មានជ័យ | Mean Chey | ✅ |
| `1207` | រុស្សីកែវ | Russey Keo | ✅ |
| `1208` | សែនសុខ | Sen Sok | ✅ |
| `1209` | ពោធិ៍សែនជ័យ | Pou Senchey | ✅ |
| `1210` | ជ្រោយចង្វារ | Chroy Changvar | ⚠️ |
| `1211` | ព្រែកព្នៅ | Prek Pnov | ⚠️ |
| `1212` | ច្បារអំពៅ | Chbar Ampov | ⚠️ |
| `1213` | បឹងកេងកង | Boeng Keng Kang | ⚠️ |
| `1214` | កំបូល | Kamboul | ⚠️ |

## What "verified" means, and what still has to happen

The fourteen names are right and the set is complete. **The numeric codes for the last five are
not confirmed** — they are the ones assigned after the 2019 reorganisation, and their ordering in
the official geocode tables is exactly the kind of detail that is easy to get subtly wrong from
memory. `1201`–`1209` are long-standing and safe.

Before the seed migration is written, someone must check `1210`–`1214` against an official source —
the NCDD or MoI geocode list — and correct this table. This is a ten-minute task that gets
expensive later: `district_code` lands in `donor_profiles` rows, so a wrong code is a data migration
after donors exist, not an edit.

Two things make a wrong code survivable but ugly: nothing in the matching logic parses the code (it
is compared, not decoded), and the dropdown shows the name, not the number. So a mis-numbered
district still works end to end — it just stops matching any external dataset we later join against.

**Do not seed this table while any row still reads ⚠️.**

## Rules for whoever seeds it

- Seed as reference data in its own Flyway migration, the way `blood_compatibility` was — not as
  application inserts. Backend owns the migration; this file owns the content.
- Khmer is the primary label. The app defaults to `km` (`FR-GLOBAL-001`), and a Latin-only dropdown
  is unusable for the majority of donors.
- Sort the dropdown by Khmer name, not by code. Code order is administrative history and means
  nothing to a donor looking for their own district.
- No "other" or "outside Phnom Penh" option in M3. The pilot is Phnom Penh (`prd.md` §1), and an
  escape hatch would collect donors the matching radius cannot serve.
