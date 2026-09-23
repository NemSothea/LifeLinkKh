---
id: BUG-API-004
title: A donor's district stays English on the Khmer board — the hospital's does not
area: API
severity: medium
status: closed
found_in: demo verification 2026-09-23, GET /api/public/requests
reported_by: QA
---
## Steps to reproduce
1. `bash scripts/dev-up.sh`, then seed: `docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/seed-demo-request.sql`
2. Open `http://localhost:3000/km/portal` — Khmer, the default locale.
3. Expand any request with an accepted donor.

## Expected
Every place name on a Khmer page reads in Khmer. `districts` carries `name_km` for all 14 khan
(`V3__seed_districts.sql`), so the data exists.

## Actual
The hospital's district renders `មានជ័យ`; the donor's renders `Doun Penh`. Both are the same
column in the same table, displayed one row apart on the same card.

The API is where they diverge — `GET /api/public/requests`:

```json
"hospital":       { "districtName": { "km": "មានជ័យ", "en": "Mean Chey" } },
"acceptedDonors": [ { "displayName": "Sok Dara", "districtName": "Doun Penh" } ]
```

`hospital.districtName` is the bilingual object the portal can pick from. `acceptedDonors[].districtName`
is a bare English string, so the client has nothing to localize with.

## Fix
Closed 2026-09-23. `AcceptedDonorResponse.districtName` and `PublicDonorResponse.districtName`
became `DistrictName{km, en}` — the same record the hospital's district already used — and both
mappers in `BoardService` and `PortalService` now build it. The portal picks the label with
`districtLabel(district, locale)` (`frontend/src/lib/api/district.ts`), a leaf type shared by
`board.ts` and `portal.ts` so the two cannot drift apart again in exactly this way.

Contract: `api-contract/web/openapi.yaml` 0.3.0 → 0.4.0, with a `DistrictName` schema. The same
bump documents `Hospital.districtName`, which the API had always sent and the web spec had never
declared.

Tests: `PortalServiceTest.anAcceptedDonorsDistrictCarriesBothLabels` and
`anUnknownDistrictLeavesTheLabelNull`, `BoardControllerTest.anAcceptedDonorsDistrictIsAnObjectWithBothLabels`
(the wire shape, since that is what the portal reads), and `district.test.ts` for the client-side
pick including the unknown-locale fallback.

Verified live on the running stack: `GET /api/public/requests` returns
`"districtName": {"km": "ទួលគោក", "en": "Tuol Kouk"}` for an accepted donor, the Khmer board renders
`Sok Dara · O+ · ដូនពេញ`, and the English board renders `Sok Dara · O+ · Doun Penh`.

The mobile client was checked and needed no change: it reads `/public/requests` for the board but
ignores `acceptedDonors`, and it already parsed every other `districtName` as a km/en map.

## Notes
- The web contract documents the current shape, so it is a contract decision, not an oversight
  in the code: `docs/fullstack/api-contract/web/contract.md` line 70 shows
  `"districtName": "Toul Kork"` on an accepted donor. The mobile contract has a CR log
  (`api-contract/mobile/change-requests.md`, where CR-MAPI-001 made the *donor profile's* district
  bilingual for exactly this reason); the web contract has none, so this file is the record until
  Fullstack decides where that change is written down.
- Fix is a DTO change on the accepted-donor projection to the same `{km, en}` shape, the portal
  reading it the way it already reads the hospital's, and an `openapi.yaml` minor bump. It is a
  contract change, which is why this is filed rather than patched during demo prep.
- Visible on the Khmer board, which is the default locale and the first screen of the demo.
  Cosmetic, not a data or security fault — a donor's district is public by `DEC-009` either way.
- Found alongside the urgency badge printing raw `CRITICAL`/`URGENT`/`ROUTINE` on the Khmer
  board. That one was frontend-only (the filter chips above the list were already translated) and
  is fixed; this one is not, because it crosses the API contract.
