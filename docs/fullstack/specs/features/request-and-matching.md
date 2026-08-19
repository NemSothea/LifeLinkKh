---
id: SPEC-REQUEST-MATCHING
owner: Fullstack
status: draft — awaiting Tech Lead + Security sign-off (R5 applies)
milestone: M4
fr_ref: >
  ../../../po/features/FR-REQUEST-001-create-urgent-request.md,
  ../../../po/features/FR-REQUEST-002-respond-accept-decline.md,
  ../../../po/features/FR-MATCH-001-donor-matching.md,
  ../../../po/features/FR-NOTIFY-001-request-push-alert.md
adr_ref: >
  ../../../tech-lead/adr/0003-donor-location-precision.md,
  ../../../tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md,
  ../../../tech-lead/adr/0008-max-notified-donor-count.md
contract: ../../api-contract/mobile/contract.md
---

# M4 Build Spec — urgent request, matching, and the alert

| Method | Path | Auth | FR |
|---|---|---|---|
| GET | `/hospitals` | JWT | `FR-REQUEST-001` (form data) |
| POST | `/requests` | JWT | `FR-REQUEST-001` + `FR-MATCH-001` + `FR-NOTIFY-001` |
| GET | `/requests/me` | JWT | `FR-REQUEST-001` |
| GET | `/requests/{id}` | JWT | `FR-REQUEST-001`, `FR-REQUEST-002` |
| POST | `/requests/{id}/cancel` | JWT | `FR-REQUEST-001` |
| GET | `/matches/me` | JWT | `FR-REQUEST-002` |
| POST | `/matches/{id}/respond` | JWT | `FR-REQUEST-002` |

Depends on M3 — there is no requester and no matchable donor before `auth-google-sign-in.md` and
`donor-profile.md`. Every entity this spec needs already exists from `V1__init.sql`
(`blood_requests`, `request_matches`, `hospitals`, `blood_compatibility`) with a repository each.
**No new table is required.** One column is.

## The blocker that had to close first: there were no hospitals

> **Closed 2026-08-19.** `V7__seed_hospitals.sql` seeds five. The section is kept because the reasoning
> is still the standing rule for anyone adding a sixth.


`POST /requests` requires a `hospitalId` and `hospitals` is **empty**. Nothing seeds it — not a
migration, not a fixture. `GET /hospitals` returns `[]` today, the request form has an empty
dropdown, and the entire M4 flow is unreachable. This is the districts problem again
([DEC-005](../../../decisions.md)) and it has the same shape: reference data with an external source
of truth, landing in a foreign key.

It is worse than districts in one way. `hospitals.latitude`/`longitude` are `NOT NULL` at
`NUMERIC(9,6)`, and they are **not decoration** — they are the origin point for every distance in
`FR-MATCH-001`. A hospital pinned in the wrong place silently ranks the wrong donors first, and
nothing in the system can detect it. A wrong district code costs a two-row `UPDATE`; a wrong
hospital coordinate costs a demo where matching visibly does the wrong thing.

So: **coordinates must come from a checked source, not from memory.** PO owns the reference file, the
way `reference/phnom-penh-districts.md` is owned. Requested from Sourn SAVOURN as
`docs/po/reference/phnom-penh-hospitals.md`, one row per hospital:

| Field | Rule |
|---|---|
| `name` | English name as the hospital writes it |
| `district_code` | Must exist in `districts` — this is what makes `Hospital.districtName` answerable |
| `latitude`, `longitude` | 6 dp, from a checked source, each row marked ✅ verified or ⚠️ provisional |
| `contact_phone` | Optional. Public switchboard only — never a person |

The pilot needs a handful, not a census: the hospitals a Phnom Penh emergency actually reaches —
Calmette, Khmer-Soviet Friendship, Preah Kossamak, the National Pediatric Hospital, and the
National Blood Transfusion Center. Five is enough to demo and small enough to verify properly.

> **Do not seed a ⚠️ row.** Unlike the district codes in DEC-005, there is no argument that the cost
> of being wrong is bounded here — a bad coordinate corrupts ranking, which is the feature. Build
> against a local fixture if the reference file is late; do not merge a guessed coordinate.

### `V4__hospitals_district.sql`

```sql
ALTER TABLE hospitals ADD COLUMN district_code VARCHAR(16) NULL;
ALTER TABLE hospitals ADD CONSTRAINT hospitals_district_fk
    FOREIGN KEY (district_code) REFERENCES districts (code);
```

Nullable, deliberately: the column is added before any hospital row exists, and a `NOT NULL` on an
empty table that a later seed must satisfy is the same constraint expressed less clearly. `Hospital`
in the contract marks `districtName` optional (only `id` and `name` are required), so a hospital
without a district still serializes.

### `V5__request_contact.sql` — the accept flow had nobody to call

Found while wiring the accept path, and it is not a detail. `RequesterContact` requires a
`displayName` and a `phone`, and **nothing in the database could produce either**: the display name
arrives inside the Google ID token and is never stored, and phone was dropped from sign-up when auth
moved to Google Sign-In (ADR 0002). A donor who accepted would have reached the one screen the whole
accept flow exists to produce, and found it blank.

`blood_requests` gains `contact_name` and `contact_phone`, both NOT NULL with no default — the table
is empty, so there is nothing to back-fill, and a default would let a future insert omit the field the
flow depends on. The contact belongs to the request rather than the account because the person posting
may be posting for someone else. See CR-MAPI-003.

### `V6__match_distance.sql` — the distance that ranked this donor, kept

`Match.request.distanceKm` means `GET /matches/me` has to answer a distance for a match created
earlier. Recomputing from the donor's current coordinates answers a different question: distance is a
fact *about the match* — how far away this donor was when they were chosen. A donor who has since
moved would watch their alert list re-rank itself, and the order they were notified in would no longer
be reconstructible for the pilot's own metrics. `request_matches.distance_km NUMERIC(4,1) NULL`,
written once, never recomputed.

### `V7__seed_hospitals.sql` — **unblocked 2026-08-19**

Reference data in its own migration, as `blood_compatibility` and `V3__seed_districts.sql` were.
PO delivered [`phnom-penh-hospitals.md`](../../../po/reference/phnom-penh-hospitals.md): five
hospitals, every coordinate from the OpenStreetMap Nominatim hospital object, three of the five
cross-checked against Wikipedia to within ~50 m.

Two rows carry a ⚠️ on their **district** and ship anyway. That is not a relaxation of the rule above
— the rule was about coordinates, and it is the coordinates that corrupt ranking silently.
`district_code` on a hospital is display only: nothing in matching reads it, it feeds
`Hospital.districtName` on the request form, and correcting it is one `UPDATE` with nothing to
cascade into. Both uncertain rows sit on Street 271, which is an administrative boundary, and both are
downstream of the same 2019 redistricting that made `1213` provisional in DEC-005.

`SchemaIntegrationTest` now asserts the five names, the district foreign key, and a bounding box over
Phnom Penh. The box exists for the failure with no other detector: a transposed coordinate satisfies
`NUMERIC(9,6)` and still returns 25 plausibly-ranked donors. Swapping latitude and longitude — the
classic version — lands at 104°N, off the planet.

## `POST /requests` — the whole chain in one call

The contract is explicit that matching and push run **inside** this request, not on a queue:
FR-04 requires notification on creation, and the NFR is request-to-first-notification under 10 s. A
job runner would be a second failure surface for a path that has to work in 10 seconds anyway.

Order of operations, and each step's failure behaviour:

1. **Validate** (below). Reject before writing anything.
2. **Insert `blood_requests`** with `status = 'OPEN'`, `created_by_user_id` from the JWT subject.
3. **Match** — one SQL query, section below. Returns at most 25 donor profile ids in rank order.
4. **Insert `request_matches`** — one row per matched donor, `notified_at` NULL.
5. **Push** — FCM multicast to those donors' `users.fcm_token`. Set `notified_at` on the rows whose
   send succeeded.
6. **Respond `201`** with `alertedCount` = rows written at step 4.

**Steps 2–4 are one transaction. Step 5 is not, and must not be.** An FCM outage cannot roll back a
blood request — the request still exists, the matches still exist, and `notified_at` stays NULL,
which is exactly what that nullable column is for. Log the failure and return `201`. A requester
whose alert failed to send still has a request the hospital can see; a requester whose `POST` 500s
has nothing and retries, creating a duplicate.

`alertedCount` counts **matches written, not pushes delivered.** The two differ whenever a matched
donor has no FCM token — a donor who signed in before granting notification permission. Do not
conflate them; `prd.md`'s ≥95% delivery metric is measured over `notified_at IS NOT NULL`, and
inflating the denominator with donors who were never sendable would flatter it.

### Validation

| Rule | Failure |
|---|---|
| `patientBloodType` is one of the 8 | `422` — must join `blood_compatibility`, so no "unknown" |
| `unitsNeeded >= 1` | `422` |
| `hospitalId` exists | `422` — a `404` here would leak which UUIDs are real hospitals |
| Caller is authenticated | `401` |

Rate limit `POST /requests` per user — reuse the `SignInRateLimiter` shape from M3, `429` on trip.
A request fans out to 25 push notifications; unthrottled it is a spam cannon aimed at the exact
population whose attention this product depends on. This is the same reasoning as ADR 0008, applied
to a different axis: the cap bounds one request, the limiter bounds one user.

**Role:** any authenticated user may create a request. Do **not** restrict to `REQUESTER`. A donor
whose relative needs blood is the most likely requester in the pilot, and forcing a second account
to post an emergency is a failure mode with a body count. `SelfServiceRole` exists to stop
self-assignment of `HOSPITAL`/`ADMIN` (TM-AUTH-001 E1), not to gate this.

## The matching query — `FR-MATCH-001`

One query, not a Java loop over candidates. Every filter is a join or a predicate the database can
index, and pulling 200 donor rows into the JVM to sort them there would put donor coordinates in
application memory for no gain (ADR 0003's exposure argument applies to logs and heap dumps too).

```sql
SELECT c.id                                    AS "donorProfileId",
       ROUND(c.distance_km::numeric * 2, 0) / 2 AS "distanceKm"    -- 0.5 km steps (ADR 0003)
FROM (
    SELECT dp.id,
           dp.latitude,
           CASE WHEN dp.latitude IS NULL OR dp.longitude IS NULL THEN NULL
                ELSE 6371 * acos(least(1,
                    cos(radians(:hospitalLat)) * cos(radians(dp.latitude))
                      * cos(radians(dp.longitude) - radians(:hospitalLng))
                  + sin(radians(:hospitalLat)) * sin(radians(dp.latitude))
                ))
           END AS distance_km
    FROM donor_profiles dp
    JOIN blood_compatibility bc
      ON bc.donor_type     = dp.blood_type
     AND bc.recipient_type = :patientBloodType      -- ADR 0004: joined, never branched
    WHERE dp.is_available = true
      AND (dp.last_donation_date IS NULL            -- 56-day cooldown, FR-DONOR-002
           OR dp.last_donation_date <= :eligibleCutoff)
) c
WHERE c.latitude IS NULL OR c.distance_km <= :radiusKm  -- no coordinates: still matches (ADR 0003)
ORDER BY "distanceKm" ASC NULLS LAST, c.id ASC          -- ADR 0008: deterministic
LIMIT :maxNotified
```

The haversine appears once, in a subquery, rather than three times inline. Aliases are quoted so
Postgres preserves their case and the projection getters bind — an unquoted `AS distanceKm` folds to
`distancekm` and silently fails to map.

Points that are decisions, not style:

- **Compatibility direction.** `bc.recipient_type = patient` and `bc.donor_type = donor`. Reversing
  these compiles, runs, returns rows, and matches exactly the wrong donors — an O− patient would be
  offered every donor in the city. There must be a test for a non-symmetric pair (`A+` patient
  accepts `O−`; an `O−` patient accepts only `O−`) or this bug ships.
- **Eligibility reads `donor_profiles.last_donation_date`, not `donations`.** `V1__init.sql` calls
  that column a cache of `MAX(donations.donated_on)` and says donations wins on disagreement. That
  is correct for `GET /donors/me` and wrong to put in a 25-way matching query as a subselect. The
  cache is written whenever a donation is recorded; if the two ever disagree, the fix is the writer,
  not this query. Note it and move on — `EligibilityCalculator` stays the single source for the
  displayed value.
- **56 days is `EligibilityCalculator.COOLDOWN_DAYS`, not a literal `56` in SQL.** Bind it.
- **`NULLS LAST` is load-bearing.** Postgres sorts NULL first on `ASC` by default, which would put
  every GPS-declining donor at the front of the alert list. The one word inverts the whole ranking.
- **`least` needs an explicit NULL guard, and this was a real bug.** Postgres' `least` *skips* NULL
  arguments rather than propagating them, so `least(1, NULL)` is `1`, `acos(1)` is `0`, and a donor
  with no coordinates comes back at **0.0 km — first in the alert list**. It is the same inversion
  `NULLS LAST` exists to prevent, arriving by a different route, and `NULLS LAST` cannot catch it
  because the value is no longer null. Hence the `CASE ... IS NULL` wrapper. The first implementation
  had this bug and `MatchingIntegrationTest` caught it, which is the whole argument for testing the
  ranking rules against a real PostgreSQL instead of a mock. (The `least` itself still has to stay:
  floating-point can push the `acos` argument a hair above 1 for two points at the same place, which
  is a domain error rather than a distance of zero.)
- **Radius default 10 km** (`prd.md` FR-05), `lifelink.matching.radius-km`. Cap 25,
  `lifelink.matching.max-notified` / `MATCHING_MAX_NOTIFIED` (ADR 0008).
- **No spatial index.** ADR 0003 settled this: a computed ordering over pilot size is fine. Revisit
  only with a measurement, not a hunch.
- **Distance is rounded server-side to 0.5 km** in the query itself, and that rounded value is what
  is written to `request_matches.distance_km` and returned. There is no code path in the product that
  produces an unrounded donor distance.

## `POST /matches/{id}/respond` — `FR-REQUEST-002`

The one place in the product where a donor's phone number is revealed, so it is the one place
`TM-AUTH-001` finding I1 is enforced:

- `403` if the match's `donor_profile_id` is not the caller's profile. Not `404` — the caller knows
  the id, they got it from `/matches/me`; hiding it here would be theatre.
- `409` if `response` is already set. **One response, never overwritten** — withdrawal is
  `FR-REQUEST-004`, deferred. The `WITHDRAWN` enum value in `V1__init.sql` stays unreachable, exactly
  like `EXPIRED`.
- On `ACCEPTED`, and only then, the response carries `requesterContact`. `phoneVerified` is
  hard-coded `false` (ADR 0002 — nothing verifies phone numbers in this build) and the client is
  required to show that caveat.
- On `DECLINED`, `requesterContact` is `null`. Not omitted-and-defaulted, not an empty object —
  `null`, so a client bug reads as a crash rather than as a contact card with blank fields.

`acceptedCount` on the request is `COUNT(*) WHERE response = 'ACCEPTED'`, computed on read. It is
not a counter column; a denormalized counter that disagrees with the rows is the classic version of
this bug and there is no volume here to justify one.

**Accepting does not close the request.** `status` stays `OPEN` until the creator cancels or marks
it fulfilled. A request needing 3 units and holding 1 acceptance is still open, and no rule in this
build closes it automatically (ADR 0008 decision 2 accepted that gap deliberately).

## `GET /requests/{id}` — who can see it

Visible to the creator, and to any donor with a `request_matches` row for it. Everyone else gets
**`404`, not `403`** — a `403` confirms the request exists, which turns the endpoint into an oracle
for enumerating blood requests. This is the opposite of the `/matches/{id}` rule above and the
difference is deliberate: there the caller is proven to already know the id.

`requesterContact` appears only for a caller whose own match is `ACCEPTED`. Same rule as the respond
endpoint, and it must be one shared helper, not two implementations that can drift apart.

`distanceKm` is present when the caller is a matched donor with coordinates, `null` otherwise.
`districtName` is the hospital's district, not the donor's.

## Push — `FR-NOTIFY-001`

FCM tokens already exist: M3 registered them via `POST /auth/fcm-token`. This adds the send path
only, which was the point of moving token registration earlier.

- **Data payload, not a notification-only message.** The alert must carry `requestId` so tapping it
  opens the request detail (`prd.md` FR-06). A notification-only message gives the client nothing to
  route on.
- Body text is built from `users.language` (`km` default) — `FR-GLOBAL-001` is M6 for the UI, but a
  push whose text is chosen server-side cannot wait for the client's locale switch.
- **The body must not contain a phone number, a donor name, or a coordinate.** A push notification
  renders on a locked screen. Blood type and hospital name are the payload; that is enough to decide
  whether to open the app.
- A dead token (FCM `UNREGISTERED`) should clear `users.fcm_token`. Leaving it means every future
  request pays a failed send for a phone that no longer exists.

## Tests this spec is not done without

Beyond the acceptance criteria in `FR-MATCH-001`:

- Compatibility in the non-symmetric direction, both ways round (the reversal bug above).
- Exactly 25 rows written from 30 qualifying candidates; the 26th has no row.
- Two identical matching runs return the same donors in the same order.
- A donor with NULL coordinates is matched and sorts last.
- FCM failure at step 5 still returns `201` with the matches written and `notified_at` NULL.
- No response body anywhere in this spec contains `latitude`, `longitude`, or an unrounded distance.
- `requesterContact` is absent for a `DECLINED` match, an unanswered match, and a non-matched caller.
