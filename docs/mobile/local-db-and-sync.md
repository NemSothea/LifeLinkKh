# Local database and sync strategy — LifeLink KH mobile

**Owner:** Mobile (Tech Lead). **Status:** design complete; the accept/decline slice is built (see the last section).
**Course deliverable:** team milestone M4 from Week 9 — full DDL for the team product's local
database, a sync strategy per entity, and a conflict-resolution choice per syncable entity.
**Written:** 2026-09-21, nine days after the Monday it was due.

This document answers three questions the Week 9 lecture asks of every team product, and one
sharpening question the lecturer said he would ask in review.

## Why the app needs this at all

Today every write in `mobile/` is server-first: the screen calls a service, the service calls a
Dio repository, and the user watches a spinner until the API answers. Week 9 names that pattern as
forbidden from Week 9 onwards, and the reason is not stylistic. The app's whole premise is a donor
reached during an emergency, and the places that generates — a hospital corridor, a basement ward,
a provincial road — are exactly where the network is worst. A donor who taps **Accept** on a
request and gets an eight-second spinner has no way to tell a slow network from a broken app.

The write that has to survive a dead network is **accept/decline** (`FR-REQUEST-002`). Everything
else in this document is arranged around protecting that one interaction.

## What lives on the device

`shared_preferences` already holds the locale and `flutter_secure_storage` holds the session JWT.
Neither moves into SQLite: a key-value store is right for config, and a token belongs in the
keystore, not in a database file. What follows is what Drift owns.

| Entity | On device | Direction | Why |
|---|---|---|---|
| `districts` | full copy | pull, rarely | 14 rows of reference data behind the profile-setup dropdown. Without it, an offline donor cannot finish registering |
| `hospitals` | name + district only | pull, rarely | Request cards name the hospital. Coordinates stay server-side |
| `donor_profile` (own) | full row | pull + **push** | The donor's own record. `is_available` is a toggle a donor flips while standing in a hospital |
| `blood_requests` (alerted to me) | cached copy | pull | The alert list must render with no network. Contact fields are absent until acceptance, so the cache cannot leak them |
| `request_matches` (own) | full row + **queue** | **push**, offline-first | The accept/decline decision. The reason this document exists |
| `donations` (own) | cached copy | pull | The 56-day eligibility countdown must be readable offline; it is the screen a donor opens most |
| `blood_compatibility` | **never** | — | Matching is a server-side join (ADR 0004). Shipping 27 patient-safety rows to a device that could hold a stale copy buys nothing and risks everything |
| Other donors' rows | **never** | — | `TM-AUTH-001`. A device holds its own data, not the donor registry |
| Coordinates (`latitude`/`longitude`) | own only, never others' | — | ADR 0003. The API never returns another donor's coordinates; the cache must not invent a place to keep them |

## DDL

Drift generates SQLite from table classes, so the DDL below is stated twice: as the Drift
definition that is the source of truth, and as the SQL it produces, because the deliverable asks
for DDL and because a reviewer reads SQL faster.

### Drift definitions — `lib/src/core/database/app_database.dart`

```dart
class DistrictRows extends Table {
  TextColumn get code => text().withLength(min: 4, max: 8)();
  TextColumn get nameKm => text()();
  TextColumn get nameEn => text()();
  @override
  Set<Column> get primaryKey => {code};
}

class HospitalRows extends Table {
  TextColumn get id => text()();                       // server UUID, stored as text
  TextColumn get name => text()();
  TextColumn get districtCode => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class DonorProfileRows extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get bloodType => text().withLength(min: 2, max: 3)();
  DateTimeColumn get lastDonationDate => dateTime().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get districtCode => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();        // client clock, drives last-write-wins
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class BloodRequestRows extends Table {
  TextColumn get id => text()();
  TextColumn get patientBloodType => text()();
  IntColumn get unitsNeeded => integer()();
  TextColumn get urgency => text()();
  TextColumn get status => text()();
  TextColumn get hospitalId => text().nullable()();
  RealColumn get distanceKm => real().nullable()();
  DateTimeColumn get notifiedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();         // staleness, not freshness
  @override
  Set<Column> get primaryKey => {id};
}

class RequestMatchRows extends Table {
  TextColumn get id => text()();                       // server UUID, or a client UUID until sync
  TextColumn get bloodRequestId => text().references(BloodRequestRows, #id)();
  TextColumn get response => text().nullable()();      // ACCEPTED | DECLINED | null
  DateTimeColumn get respondedAt => dateTime().nullable()();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  TextColumn get rejectedReason => text().nullable()(); // set when the server refused the write
  @override
  Set<Column> get primaryKey => {id};
}

class DonationRows extends Table {
  TextColumn get id => text()();
  DateTimeColumn get donatedOn => dateTime()();
  TextColumn get hospitalId => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class PendingSync extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();                   // request_match | donor_profile
  TextColumn get entityId => text()();                 // the local row's primary key
  TextColumn get operation => text()();                // create | update
  TextColumn get idempotencyKey => text()();           // client UUID, replayed on every retry
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
}
```

### The SQL that generates

```sql
CREATE TABLE district_rows (
    code     TEXT NOT NULL PRIMARY KEY,
    name_km  TEXT NOT NULL,
    name_en  TEXT NOT NULL
);

CREATE TABLE hospital_rows (
    id            TEXT NOT NULL PRIMARY KEY,
    name          TEXT NOT NULL,
    district_code TEXT NULL
);

CREATE TABLE donor_profile_rows (
    id                  TEXT NOT NULL PRIMARY KEY,
    full_name           TEXT NOT NULL,
    blood_type          TEXT NOT NULL,
    last_donation_date  INTEGER NULL,
    is_available        INTEGER NOT NULL DEFAULT 1,
    district_code       TEXT NULL,
    updated_at          INTEGER NOT NULL,
    is_pending          INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE blood_request_rows (
    id                  TEXT NOT NULL PRIMARY KEY,
    patient_blood_type  TEXT NOT NULL,
    units_needed        INTEGER NOT NULL,
    urgency             TEXT NOT NULL,
    status              TEXT NOT NULL,
    hospital_id         TEXT NULL,
    distance_km         REAL NULL,
    notified_at         INTEGER NOT NULL,
    cached_at           INTEGER NOT NULL
);

CREATE TABLE request_match_rows (
    id               TEXT NOT NULL PRIMARY KEY,
    blood_request_id TEXT NOT NULL REFERENCES blood_request_rows (id),
    response         TEXT NULL,
    responded_at     INTEGER NULL,
    is_pending       INTEGER NOT NULL DEFAULT 0,
    rejected_reason  TEXT NULL
);

CREATE TABLE donation_rows (
    id          TEXT NOT NULL PRIMARY KEY,
    donated_on  INTEGER NOT NULL,
    hospital_id TEXT NULL,
    cached_at   INTEGER NOT NULL
);

CREATE TABLE pending_sync (
    id               INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entity           TEXT NOT NULL,
    entity_id        TEXT NOT NULL,
    operation        TEXT NOT NULL,
    idempotency_key  TEXT NOT NULL,
    retry_count      INTEGER NOT NULL DEFAULT 0,
    last_attempt_at  INTEGER NULL,
    queued_at        INTEGER NOT NULL
);
```

`schemaVersion` ships at **1**. There is no v0 in the wild, so there is no upgrade path to write
yet — but the migration hook is written now, empty, with the v2 plan recorded below, because the
Week 7 lecture's stated classic mistake is changing a table without bumping the version and
crashing every installed app on launch.

**Planned v2:** add `donor_profile_rows.phone` when `FR-DONOR-001`'s phone field reaches the app.
`m.addColumn(donorProfileRows, donorProfileRows.phone)` inside `if (from < 2)`, committed with the
code that reads it, never before.

## Sync strategy, per entity

Three classes of entity, three behaviours.

**Reference data — `districts`, `hospitals`.** Pulled on sign-in and refreshed whenever the app
comes back online after more than 24 hours offline. Never written on the device. A district that
disappears from the server stays in the local copy until the next successful pull replaces the
whole table in one transaction; a partial write would leave a donor's district dangling.

**Read caches — `blood_requests`, `donations`.** Written only by a pull. The screen renders from
the cache immediately and a refresh runs behind it, which is what makes the eligibility countdown
and the alert list open instantly with no network. `cached_at` exists so the UI can say *"as of
14:02"* rather than silently present stale data as current. Nothing in these tables is ever pushed.

**Offline-first writes — `request_matches`, `donor_profile`.** The local row is written first,
inside a Drift transaction that also inserts the `pending_sync` row, so the app can never end up
with a decision the queue does not know about. The UI shows the new state immediately with a
PENDING badge. `SyncService` drains the queue when connectivity returns.

`SyncService.triggerSync()` is idempotent — a `_draining` guard makes concurrent calls safe — and
retries with exponential backoff at 1s, 2s, 4s, capped at 8s, reset to 1s on success. It is the
documented exception to Service rule S2 (services are stateless): it holds `_draining`, the current
backoff, and a connectivity subscription. Rules S1, S3, S4, S5 and S6 still hold, and the exception
is commented at the class.

Every queued write carries an `idempotency_key` — a client-generated UUID, replayed unchanged on
every retry. Without it, a retry after a response that was sent but never received records the
donor's acceptance twice.

> **Backend dependency.** The accept endpoint must honour that key, and it does not today. This
> needs a CR-MAPI change request against the mobile contract before the sync engine can be trusted:
> `POST /requests/{id}/respond` gains an `Idempotency-Key` header, and a replay returns the first
> response rather than a second row. Filed as part of this document, not assumed.

## Conflict resolution, per syncable entity

Only two entities are ever pushed, so only two need a rule.

| Entity | Rule | Why this one |
|---|---|---|
| `request_matches` | **Server-wins** | A request can be fulfilled or cancelled while the donor is offline. If the server says the request closed, the local ACCEPTED must lose — the alternative is a donor who believes they are expected at a hospital that no longer needs them. The refusal is not swallowed: `rejected_reason` is set, the badge becomes an explanation, and the donor is told the request was already fulfilled |
| `donor_profile` | **Last-write-wins**, by `updated_at` | The only pushed fields are the availability toggle and profile edits. Both are pure statements of the donor's own intent, and the most recent statement is the correct one. No safety rule depends on them: eligibility is computed from `donations.donated_on`, which the device cannot write |

Eligibility is worth stating separately, because it looks like a sync problem and is not. The
56-day countdown is derived server-side from a donation row a hospital confirms. The device caches
the answer; it never computes a competing one. There is nothing to reconcile.

## The lecturer's sharpening question

> *"What happens if two users edit the same row offline?"*

In LifeLink, they cannot — and that is a property of the schema, not luck. `request_matches` is one
row per donor per request, and a donor has one account. `donor_profiles` is one row per user,
enforced by a UNIQUE constraint on `user_id`. No two devices ever hold the same row for writing.

The real contention is different, and the answer is not a sync rule at all. Two donors, both
offline, both accept the last remaining unit of the same request. Both writes are legitimate; both
queues drain when signal returns. This is resolved **server-side**, not on the device: the accept
endpoint is a conditional update against `status = 'OPEN'` and the remaining unit count, so the
first write to arrive wins and the second is refused with `ALREADY_FULFILLED`. The loser's device
reads that refusal, clears the pending badge, and tells the donor plainly that the need was already
met — which is true, and is good news.

Put another way: offline-first changes when the write is attempted, never who is allowed to win.
Authority stays on the server, because the server is the only place that can see both donors.

## What this does not cover

- **Creating a blood request offline.** Queued like any other write, but a request that cannot
  reach the server notifies nobody, so the UI must say "not sent yet" rather than imply help is on
  the way. Deferred until the accept/decline path is proven.
- **Background sync.** `SyncService` drains on app resume and on a connectivity change. A true
  background worker (WorkManager) is not in scope for the course build.
- **Encryption at rest.** The SQLite file holds the donor's own name, blood type and district.
  `FR-SECURITY-001` (account and data deletion) is already deferred and already dated; local
  database encryption joins it under the same deadline — before any real donor's data is in this
  app.

## What is built, as of 2026-09-21

The accept/decline slice — the one write that has to survive a dead network — is implemented and
tested. The rest of the table above is still design.

| Piece | File |
|---|---|
| Database, two tables, migration hook | `mobile/lib/src/core/database/app_database.dart` |
| DAO — atomic write, queue, backoff bookkeeping | `mobile/lib/src/features/match/data/match_sync_dao.dart` |
| Offline-first repository | `mobile/lib/src/features/match/data/offline_first_match_repository.dart` |
| Sync engine (the S2 exception) | `mobile/lib/src/features/match/application/match_sync_service.dart` |
| PENDING badge, Khmer + English | `mobile/lib/src/features/match/presentation/match_detail_screen.dart` |
| 12 tests, `NativeDatabase.memory()` | `mobile/test/offline_first_match_test.dart` |

Swapping SQLite in front of the network changed **one line** in `match_providers.dart`. The service,
the notifier and every widget were written against the abstract `MatchRepository` and did not move —
the Week 3 rule S4 payoff, demonstrable in a diff for the Week 16 defense.

Three deviations from the design above, each deliberate:

1. **`request_match_rows` has no foreign key to `blood_request_rows`.** The request cache is not in
   this slice, so the reference would point at a table that does not exist.
2. **Only two tables ship.** `districts`, `hospitals`, `blood_requests` and `donations` stay
   server-fetched until the read-cache slice.
3. **`drift_flutter` is not used, and `drift` is pinned below its latest.** `drift_dev` at any
   version that resolves against `riverpod_generator 2.6.x` requires `build ^2.0.0`; the current
   `drift_dev` requires `build >=3.0.0`. Same shape of trap as ADR 0006's `matcher` pin, same
   resolution: the graded requirement (Riverpod code generation, Week 4) wins, and the other
   dependency gives way. Resolved versions: `drift 2.28.2`, `drift_dev 2.28.0`, opened with
   `NativeDatabase` and `path_provider` directly.

### Still owed

- **The backend does not read `Idempotency-Key` yet.** The client sends it on every replay; the
  server ignores it. Until the CR-MAPI lands, a retry after a lost response can still record a
  second acceptance. This is the one correctness gap in the slice and it is not mobile's to close.
- **Offline restart shows an empty inbox.** The answers persist, but the alert list itself is not
  cached, so `GET /matches/me` failing leaves nothing to overlay them onto. The read-cache slice
  fixes it.
