# Phnom Penh hospitals — pilot reference list

Owner: PO. Consumed by `V7__seed_hospitals.sql` (`backend/src/main/resources/db/migration/`).
Same contract as [`phnom-penh-districts.md`](phnom-penh-districts.md): this file is the source, the
migration is the copy, and a change here is a new `V<n>` migration rather than an edit to a merged one.

## Why these five and not a census

The pilot needs the hospitals a Phnom Penh blood emergency actually reaches. Five is enough to demo
the whole flow and small enough that every coordinate can be checked properly — which matters more
here than length, for the reason below.

## Why the coordinates are the part that must be right

`hospitals.latitude` / `longitude` are **not decoration**. They are the origin point for every
distance in `FR-MATCH-001`: the matching query measures each donor from the hospital named on the
request. A hospital pinned in the wrong place silently ranks the wrong donors first, and there is
nothing in the system that can detect it — the query still returns 25 rows, still ordered, still
plausible.

That is a different class of risk from the district codes in [DEC-005](../../decisions.md), where a
wrong code cost a two-row `UPDATE`. A wrong pin costs a demo where matching visibly does the wrong
thing and nobody can say why.

`district_code` on a hospital is the opposite: it is **display only**. Nothing in matching reads it —
`Hospital.districtName` is a label on the request form. A wrong district here costs a wrong label and
a one-line `UPDATE`, which is why the two uncertain ones below ship marked rather than withheld.

## The list

Coordinates from the OpenStreetMap Nominatim API (the hospital `amenity` object, not a nearby bus
stop or traffic signal — both of those appeared in the results and were discarded), checked
2026-08-19. Three of the five cross-check against Wikipedia to within ~50 m.

| Name | District | Code | Latitude | Longitude | Coordinate | District |
|---|---|---|---|---|---|---|
| Calmette Hospital | Doun Penh | `1202` | `11.581329` | `104.915690` | ✅ | ✅ |
| Khmer–Soviet Friendship Hospital | Boeng Keng Kang | `1213` | `11.545289` | `104.903984` | ✅ | ⚠️ |
| Preah Kossamak Hospital | Tuol Kouk | `1204` | `11.564010` | `104.890378` | ✅ | ✅ |
| National Pediatric Hospital | Tuol Kouk | `1204` | `11.568123` | `104.896826` | ✅ | ✅ |
| National Blood Transfusion Center | Mean Chey | `1206` | `11.544034` | `104.904658` | ✅ | ⚠️ |

Cross-checks that passed:

- **Calmette** — Wikipedia gives 11.581318, 104.915822. About 14 m from the OSM pin.
- **Khmer–Soviet Friendship** — Wikipedia gives 11.544837, 104.904022. About 50 m from the OSM
  hospital polygon's centre, which is what a large campus looks like from two sources.
- **National Pediatric** — Wikipedia gives 11.568, 104.897 at three decimal places, which is ±50 m by
  construction. Consistent.

Preah Kossamak and the NBTC have no Wikipedia coordinate. Both were taken from the OSM hospital
object and both sit where their street addresses say they should.

### The two ⚠️ districts, and why they are marked

Both sit on or beside **Street 271**, which is an administrative boundary, and both are affected by
the same 2019 redistricting that made `1213` provisional in the first place.

- **Khmer–Soviet Friendship Hospital** — OSM places the hospital polygon in Sangkat Tumnob Tuek, and
  Tumnob Tuek moved to Khan Boeng Keng Kang under sub-decree 03 of 8 January 2019. So the district is
  right and the **code** is the provisional part: `1213` is LifeLink-assigned because no official code
  for that khan exists (DEC-005). A second OSM entry for the same hospital, on the far side of Street
  271, reports Khan Mean Chey — that is the boundary, not a contradiction.
- **National Blood Transfusion Center** — genuinely disputed. OSM puts it in Sangkat Boeng Tumpun 1,
  Khan Mean Chey; public directories give its address as Khan Boeng Keng Kang. It sits about 120 m
  from the KSFH campus on the other side of Street 271, so both readings are geographically
  defensible. Seeded as Mean Chey (`1206`) because that is what the mapped object says, and marked.

Correcting either is `UPDATE hospitals SET district_code = ... WHERE name = ...` in a new migration.
No donor row carries a hospital district, so nothing cascades.

## Known gap: these names are English only

`hospitals` has a single `name` column, unlike `districts` which carries `name_km` and `name_en`. A
Khmer-reading donor picking from this dropdown gets Latin script — the exact problem
[CR-MAPI-001](../../fullstack/api-contract/mobile/change-requests.md) solved for districts.

Not fixed here, deliberately: it is a schema change plus a contract change to `Hospital.name`, and
five hospitals in a pilot dropdown is a smaller harm than fourteen districts was. It belongs with
`FR-GLOBAL-001` at M6. The Khmer names, for whoever does it:

| English | Khmer |
|---|---|
| Calmette Hospital | មន្ទីរពេទ្យកាល់ម៉ែត |
| Khmer–Soviet Friendship Hospital | មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត |
| Preah Kossamak Hospital | មន្ទីរពេទ្យព្រះកុសុមៈ |
| National Pediatric Hospital | មន្ទីរពេទ្យកុមារជាតិ |
| National Blood Transfusion Center | មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម |

## Contact phones

Left NULL. `hospitals.contact_phone` is nullable, nothing in M4 reads it, and a switchboard number
from a scraped directory is exactly the kind of unchecked value this file exists to keep out. Add
them when someone has called the number and it answered.

## Sources

- [OpenStreetMap Nominatim](https://nominatim.openstreetmap.org/) — every coordinate above
- [Calmette Hospital — Wikipedia](https://en.wikipedia.org/wiki/Calmette_Hospital)
- [Khmer–Soviet Friendship Hospital — Wikipedia](https://en.wikipedia.org/wiki/Khmer%E2%80%93Soviet_Friendship_Hospital)
- [National Pediatric Hospital, Cambodia — Wikipedia](https://en.wikipedia.org/wiki/National_Pediatric_Hospital,_Cambodia)
