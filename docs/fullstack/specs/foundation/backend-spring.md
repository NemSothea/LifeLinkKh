---
id: SPEC-FOUNDATION-BACKEND-SPRING
owner: Fullstack
status: draft
milestone: M2
---

# Foundation Spec — Spring Boot API + PostgreSQL

Scope of this spec: the project shape and initial schema the backend is created with at M2.
Milestone dates are in root `CLAUDE.md` section 4 — not repeated here.

## What M2 delivers

A Spring Boot project in `backend/` that:

- starts against the `postgres` container from `infra-docker.md`,
- applies `V1__init.sql` via Flyway on boot,
- serves `GET /api/health` returning 200 with no authentication,
- has Spring Security on the classpath configured permissively, so M3 can tighten it rather than
  introduce it.

No OTP. No JWT. No matching. No business endpoints.

## Project identity

| Field | Value |
|---|---|
| Group / base package | `kh.lifelink.api` |
| Artifact | `lifelink-api` |
| Java | 21 (LTS) |
| Spring Boot | 3.x — pin the version chosen at init |
| Build tool | **Maven** — more course-level documentation and a single `pom.xml` to review; Gradle's flexibility buys nothing at this size |
| Context path | `/api` (`server.servlet.context-path=/api`) |

## Package layout

Domain-module first, so M3–M5 features grow inside their own module instead of into four
ever-growing technical folders:

```
backend/src/main/java/kh/lifelink/api/
  LifelinkApiApplication.java
  config/
    SecurityConfig.java
    JacksonConfig.java
  common/
    error/         # @ControllerAdvice, error response shape
    audit/         # created_at / updated_at base entity
  health/
    HealthController.java
  user/            # entity, repository, service, dto  (no controller at M2)
  donor/
  hospital/
  request/
  match/
  donation/
```

At M2 each domain module contains only its JPA entity and repository. Controllers, services, and
DTOs arrive with the milestone that needs them. Do not create empty service or controller classes.

## Flyway

- Location: `backend/src/main/resources/db/migration/`
- Naming: `V<n>__<snake_case_description>.sql` — e.g. `V1__init.sql`, `V2__add_request_expiry.sql`
- Versions are integers, one migration per logical change, **never edited after merge**. A mistake
  in a merged migration is fixed by a new migration, not by rewriting history.
- `spring.jpa.hibernate.ddl-auto=validate`. Hibernate never generates schema — Flyway owns it, per
  `.capybara/setup.md` ("DB schema ownership: app migrations").
- Rollback is not automated. A destructive migration needs a backup first; coordinate with DevOps.

## Initial schema — `V1__init.sql`

Covers the six entities in `prd.md` section 6 and nothing beyond them.

**Primary keys are UUID**, not sequential integers. Sequential IDs in API paths would let anyone
enumerate donors and requests, and donor phone numbers plus blood type are the sensitive data this
project has (`prd.md` section 6). Requires `pgcrypto` for `gen_random_uuid()`.

Blood type is `VARCHAR(3)` with a `CHECK` constraint rather than a PostgreSQL `ENUM` — enums are
painful to alter in migrations, and the eight ABO/Rh values are stable enough not to need type
safety at the database level.

All timestamps are `TIMESTAMPTZ`. Cambodia is UTC+7 and storing naive local time makes the 56-day
cooldown arithmetic wrong at boundaries.

### `users`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `phone` | `VARCHAR(20) NOT NULL UNIQUE` | E.164, Cambodian numbers |
| `role` | `VARCHAR(16) NOT NULL` | `CHECK (role IN ('DONOR','REQUESTER','HOSPITAL','ADMIN'))` |
| `language` | `CHAR(2) NOT NULL DEFAULT 'km'` | `CHECK (language IN ('km','en'))` |
| `fcm_token` | `TEXT NULL` | populated at M5 |
| `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |
| `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |

### `donor_profiles`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `user_id` | `UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE` | 1:0..1 per `prd.md` §6 |
| `full_name` | `VARCHAR(120) NOT NULL` | |
| `blood_type` | `VARCHAR(3) NOT NULL` | `CHECK (blood_type IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))` |
| `last_donation_date` | `DATE NULL` | NULL means never donated; drives FR-03 eligibility |
| `is_available` | `BOOLEAN NOT NULL DEFAULT true` | FR-02 availability toggle |
| `created_at` / `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |

> **Location columns are BLOCKED and deliberately absent.** See "Blocked schema decisions" below.

### `hospitals`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `name` | `VARCHAR(160) NOT NULL` | |
| `address` | `TEXT NULL` | |
| `contact_phone` | `VARCHAR(20) NULL` | |
| `latitude` | `NUMERIC(9,6) NOT NULL` | ~0.1 m resolution; a hospital's location is public, not personal data, so it is not blocked |
| `longitude` | `NUMERIC(9,6) NOT NULL` | |
| `created_at` / `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |

### `blood_requests`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `created_by_user_id` | `UUID NOT NULL REFERENCES users(id)` | requester or hospital staff |
| `hospital_id` | `UUID NOT NULL REFERENCES hospitals(id)` | |
| `patient_blood_type` | `VARCHAR(3) NOT NULL` | same CHECK as `donor_profiles` |
| `units_needed` | `SMALLINT NOT NULL` | `CHECK (units_needed > 0)` |
| `urgency` | `VARCHAR(16) NOT NULL` | `CHECK (urgency IN ('CRITICAL','URGENT','ROUTINE'))` |
| `status` | `VARCHAR(16) NOT NULL DEFAULT 'OPEN'` | `CHECK (status IN ('OPEN','FULFILLED','CANCELLED','EXPIRED'))` |
| `created_at` / `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |

> `status` includes `EXPIRED` because FR-04 lists it, but **nothing in this schema can set it** —
> the expiry rule is undecided. See "Blocked schema decisions".

### `request_matches`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `blood_request_id` | `UUID NOT NULL REFERENCES blood_requests(id) ON DELETE CASCADE` | |
| `donor_profile_id` | `UUID NOT NULL REFERENCES donor_profiles(id) ON DELETE CASCADE` | |
| `notified_at` | `TIMESTAMPTZ NULL` | set when FCM send succeeds (M5) |
| `response` | `VARCHAR(16) NULL` | `CHECK (response IN ('ACCEPTED','DECLINED','WITHDRAWN'))` |
| `responded_at` | `TIMESTAMPTZ NULL` | |
| | `UNIQUE (blood_request_id, donor_profile_id)` | a donor is matched to a request at most once |

`WITHDRAWN` is included because the `prd.md` section 7 error-case flow describes a donor withdrawing
acceptance — but no FR covers it. Tracked as a brief (see blockers).

### `donations`

| Column | Type | Notes |
|---|---|---|
| `id` | `UUID PK DEFAULT gen_random_uuid()` | |
| `donor_profile_id` | `UUID NOT NULL REFERENCES donor_profiles(id)` | |
| `hospital_id` | `UUID NOT NULL REFERENCES hospitals(id)` | |
| `blood_request_id` | `UUID NULL REFERENCES blood_requests(id)` | nullable per FR-08 ("optionally linked") |
| `donated_on` | `DATE NOT NULL` | source of truth for the 56-day cooldown |
| `confirmed_by_user_id` | `UUID NULL REFERENCES users(id)` | hospital staff who confirmed (FR-08) |
| `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | |

### Indexes in `V1__init.sql`

- `users(phone)` — unique, already implied by the constraint.
- `donor_profiles(blood_type, is_available)` — the matching query's first filter (FR-05).
- `blood_requests(status, created_at DESC)` — open-request listings.
- `request_matches(donor_profile_id)` — a donor's inbox.
- `donations(donor_profile_id, donated_on DESC)` — cooldown lookup and history (FR-03, FR-08).

No spatial index at M2 — distance ranking depends on a blocked decision.

## Blocked schema decisions

These are **not** designed here. Both are open briefs in `docs/po/briefs/roadmap.md`, and inventing
a column to work around either would mean rewriting a merged migration later.

| Blocked | What is missing | Consequence for M2 |
|---|---|---|
| **Request expiry** | FR-04 defines the `EXPIRED` status but no rule for how long an open request lives, whether urgency changes it, or who is notified. No `expires_at` column, no scheduled job. | `blood_requests.status` can never become `EXPIRED`. Ships as a known dead value, resolved in a later `V<n>__add_request_expiry.sql`. |
| **Donor location precision** | Undecided whether to store exact lat/lng or a district centroid. This changes column types *and* is simultaneously a privacy decision (`prd.md` §6 calls precise location sensitive) and a matching-accuracy decision (FR-05 ranks by distance). | `donor_profiles` has **no location columns at all**. Donor matching cannot be implemented until this is decided — it blocks M4, not just M2. |

Resolve both before M4 build. They are also the two items named in `docs/pm/risks.md` under
concentrated sign-off authority, because the same person writes the requirement and approves the
migration.

## Spring Security at M2

`config/SecurityConfig.java`:

- CSRF disabled — this is a stateless REST API consumed by a Flutter app and a Next.js server, not
  a session-cookie form app.
- All requests permitted. **M2 has no authentication.**
- No JWT filter, no user-details service, no password encoder.

This exists so M3 changes one class rather than introducing security into a running system. It must
never reach a deployed environment: `docker-compose` is local-only per `infra-docker.md`, and the
M3 spec replaces this file wholesale.

## Deferred to later milestones

| Deferred | Milestone |
|---|---|
| OTP issue/verify, JWT issuing + filter, RBAC on endpoints | M3 |
| Donor CRUD endpoints, eligibility computation | M3 |
| Request create, ABO/Rh compatibility + distance matching query | M4 |
| FCM send, scheduled eligibility reminder job | M5 |
| Admin metrics endpoints | M6 |

## Contract gaps

`docs/fullstack/api-contract/*/openapi.yaml` both have `paths: {}`. M2 needs one endpoint defined in
both contracts:

- `GET /api/health` — unauthenticated. Response `200 {"status":"UP"}`.

This spec does not edit the contracts; `docs/cheat-sheet.md` puts that in `/capybara-adk:plan`.
Until it lands, `mobile-flutter.md` and `frontend-nextjs.md` both reference an endpoint with no
contract entry.

## Done when

- [ ] `backend/` contains a Maven Spring Boot 3.x project, Java 21, base package `kh.lifelink.api`.
- [ ] `./mvnw clean verify` passes.
- [ ] `docker compose up` brings the backend up healthy against the `postgres` service.
- [ ] Flyway applies `V1__init.sql` on first boot; `flyway_schema_history` shows one row.
- [ ] `psql` shows all six tables with the columns, CHECK constraints, and foreign keys above.
- [ ] `donor_profiles` has **no** location column and `blood_requests` has **no** expiry column.
- [ ] `GET /api/health` returns 200 without a token.
- [ ] `spring.jpa.hibernate.ddl-auto=validate` — boot fails if entities and schema disagree.
- [ ] No credential, connection string, or key literal appears in any committed file.
- [ ] Restarting the container twice applies zero new migrations (idempotent boot).

## Follow-ups this spec does not resolve

- **Request expiry** and **donor location precision** must be decided before M4. Both block schema.
- `GET /api/health` must reach both API contracts before M2 build starts.
- Donor-withdrawal (`WITHDRAWN` response value) has a column but no FR.
