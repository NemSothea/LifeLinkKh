---
id: REF-DISTRICTS-PP
title: Phnom Penh districts — the donor location list
owner: PO
status: accepted — 1201–1212 verified against NCDD; 1213–1214 provisional (DEC-005)
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
| `1210` | ជ្រោយចង្វារ | Chroy Changvar | ✅ |
| `1211` | ព្រែកព្នៅ | Prek Pnov | ✅ |
| `1212` | ច្បារអំពៅ | Chbar Ampov | ✅ |
| `1213` | បឹងកេងកង | Boeng Keng Kang | 🟡 provisional |
| `1214` | កំបូល | Kamboul | 🟡 provisional |

## The check, and what it found — 2026-08-18

Checked against the **NCDD Gazetteer for Phnom Penh** (`library.ncdd.gov.kh/detail/9649`), which is
the official source this file asked for. Result in two parts, because the answer was not uniform.

**`1201`–`1212` are confirmed exactly as listed.** The gazetteer's khan (ខណ្ឌ) rows carry these
twelve codes and no others, each with the sub-decree that created it — `1210` Chraoy Chongvar
(អនុក្រឹត្យ ៥៧៧), `1211` Praek Pnov (៥៧៨), `1212` Chbar Ampov (៥៧៩). The three that were the main
worry are right. Cross-checked against a published province/district/commune dataset that agrees on
all twelve.

**`1213` and `1214` are not in the gazetteer at all**, and the reason is dates, not error: Boeng Keng
Kang and Kamboul were created by **sub-decree 03 of 8 January 2019**, after that document was
published. So there is no official code to copy, and the two rows above are LifeLink-assigned,
following the same `12` + two-digit pattern. Their agreement with the postal prefixes for those two
khan is supporting evidence, not proof — postal codes and gazetteer geocodes are separate schemes,
and at least one third-party source lists Boeng Keng Kang's geocode as `1206`, which is Mean Chey's
and cannot be right.

**The Latin column is our own transliteration, not the gazetteer's.** NCDD writes *Prampir
Meakkakra*, *Saensokh*, *Pur SenChey*, *Chraoy Chongvar*, *Praek Pnov*; this table keeps the spellings
a Phnom Penh reader recognises, because the Latin label is UI copy. The Khmer column and the code are
the parts that must match the source.

Two things make a provisional code survivable: nothing in the matching logic parses the code (it is
compared, not decoded), and the dropdown shows the name, not the number. A mis-numbered district
still works end to end — it just stops matching an external dataset we later join against, and we
join against none.

**Seeding is now unblocked for all fourteen** — see [DEC-005](../../decisions.md). Correcting `1213`
or `1214` later is a two-row `UPDATE` plus the same update on `donor_profiles.district_code`, which
is why they ship marked rather than withheld: the alternative was a pilot where a donor in Boeng Keng
Kang — one of the densest areas in the city — has no district to pick.

## Rules for whoever seeds it

- Seed as reference data in its own Flyway migration, the way `blood_compatibility` was — not as
  application inserts. Backend owns the migration; this file owns the content.
- Khmer is the primary label. The app defaults to `km` (`FR-GLOBAL-001`), and a Latin-only dropdown
  is unusable for the majority of donors.
- Sort the dropdown by Khmer name, not by code. Code order is administrative history and means
  nothing to a donor looking for their own district.
- No "other" or "outside Phnom Penh" option in M3. The pilot is Phnom Penh (`prd.md` §1), and an
  escape hatch would collect donors the matching radius cannot serve.
