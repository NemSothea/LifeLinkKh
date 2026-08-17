# Test Strategy — LifeLink KH

**Owner:** QA. **Applies to:** the 8 FRs in [`../scope.md`](../scope.md). Deferred FRs get no tests.

This document defines the bar for **DoD step 3 — "QA sign-off vs acceptance criteria"**
([`../cheat-sheet.md`](../cheat-sheet.md)). Before this file existed, that step had no definition,
which in a build where one person writes the requirement, the code and the approval is the weakest
possible link. Everything here is chosen against that constraint: **tests are the only reviewer this
project has.**

## What we do not do, and why

A 13-week course project cannot afford full-pyramid coverage on three clients. Explicitly out:

| Not doing | Why |
|---|---|
| Backend controller tests for every endpoint | The slice test duplicates what an integration test already proves. One integration test per FR flow is stronger and cheaper. |
| Mocked-repository service tests as a default | Mocking JPA proves the mock works. Real-database tests catch the constraint violations that actually break this app. |
| Visual regression / screenshot tests | No design system, no budget, earns no marks. |
| Load or performance testing | Pilot size is 1,000 donors (`../po/prd.md` §5). A slow query at that size is not a defect worth a harness. |
| Cross-browser matrix | One portal page, one evaluator, Chrome. |
| iOS testing | Out of scope — Android only (`../../CLAUDE.md`). |

## Layers, per client

### Backend — `backend/`

| Layer | Tool | Covers | Runs where |
|---|---|---|---|
| Unit | JUnit 5 + AssertJ | Pure logic with no Spring context: 56-day eligibility arithmetic, distance calculation, ABO/Rh expectations | every build |
| Web slice | `@WebMvcTest` | Request/response shape, status codes, that a DTO does **not** leak a forbidden field | every build |
| Integration | `@SpringBootTest` + Testcontainers PostgreSQL | Flyway applies cleanly, entities match the schema under `ddl-auto: validate`, CHECK constraints reject bad data, the matching query returns the right donors | **blocked — see below** |

> **Blocker: Docker is not installed on this machine.** Testcontainers needs a container runtime, so
> the integration layer cannot run yet. Until Docker exists, the schema is unverified by anything
> except a successful boot. Do not substitute H2 — H2 has no `gen_random_uuid()`, different `CHECK`
> semantics and no `TIMESTAMPTZ`, so a green H2 test would be a false pass on exactly the things this
> layer exists to catch.

The 27 `blood_compatibility` rows get a dedicated integration test: assert all 27 pairs are present
and that **no 28th row exists**. Per ADR 0004 this is a patient-safety rule, not a feature — a wrong
row means giving incompatible blood. It is the single highest-value test in the project.

### Web portal — `frontend/`

| Layer | Tool | Covers |
|---|---|---|
| Unit / component | Vitest + React Testing Library | The request table renders rows, empty state, and error state |
| e2e | Playwright (Chromium only) | One flow: open the portal, see open requests, see one rendered from seeded data |

`FR-PORTAL-001` is one page. Two layers is the correct amount of test for one page.

### Mobile — `mobile/`

| Layer | Tool | Covers |
|---|---|---|
| Unit | `flutter_test` | Eligibility display logic, distance formatting, i18n key resolution |
| Widget | `flutter_test` | Donor register form validation, request card, eligibility banner |
| Integration | `integration_test` | One happy path on a device/emulator: sign in → register as donor → see eligibility status |

Push notification delivery and GPS acquisition are **verified manually** on a device and recorded in
this file's sign-off table. Neither is reliably automatable inside a course timeline, and both are
graded features, so the evidence must exist as a written manual result rather than a green tick.

## Coverage floor

One number, enforced on one package: **70 % line coverage on backend service and domain-logic
classes** (`kh.lifelink.api.*` excluding `config`, entities, repositories and DTOs).

Reasoning: a repo-wide percentage on generated getters and Spring config rewards writing tests for
code that cannot break. Excluded code is covered indirectly by integration tests or is declarative.
No floor is set for `frontend/` or `mobile/` — the named tests above are the bar there, because a
percentage on two screens measures nothing.

## Naming

- Backend: `MethodOrBehaviour_condition_expectedResult` — e.g.
  `eligibility_lastDonation55DaysAgo_isNotEligible`. A failing name must state the defect without
  opening the file.
- Web: `describe('<component>')` + `it('renders empty state when no requests')`.
- Flutter: `testWidgets('donor register rejects an empty blood type', ...)`.
- Every test that exists to satisfy an acceptance criterion cites its FR ID in a comment.

## Which FR needs which layer

| FR | Unit | Slice / widget | Integration / e2e | Manual |
|---|---|---|---|---|
| `FR-AUTH-003` Google Sign-In | token-claim validation | reject request-supplied uid | full sign-in against a real DB | first-run on device |
| `FR-DONOR-001` Donor profile | — | form validation | create + read profile | — |
| `FR-DONOR-002` 56-day eligibility | **yes — boundary cases 55/56/57 days, and never-donated** | eligibility banner | reads `donations`, not the cached column | — |
| `FR-REQUEST-001` Create request | units/urgency validation | form | persists with `status = OPEN` | — |
| `FR-MATCH-001` Matching | distance maths | — | **27-row compatibility assertion + full matching query** | — |
| `FR-NOTIFY-001` Push alert | payload builder | — | `notified_at` is set on success | **device receipt** |
| `FR-REQUEST-002` Accept / decline | — | button states | `UNIQUE(request, donor)` holds; response + timestamp persist | — |
| `FR-DONATION-001` History | date ordering | list + empty state | newest-first from a real DB | — |

## Non-negotiable security tests

These exist because their failure is a privacy breach, not a bug. Traced from
[`../security/security-checklist.md`](../security/security-checklist.md) and
[`TC-AUTH-001`](test-cases/TC-AUTH-001-google-sign-in-security.md).

1. **No donor endpoint response body contains `latitude`, `longitude`, or an unrounded distance**
   (ADR 0003). Asserted on the raw JSON, not on a DTO object — serialising an entity is exactly the
   mistake being guarded against.
2. **Self-service sign-up cannot produce `HOSPITAL` or `ADMIN`** — the request must be rejected, not
   silently downgraded (`TM-AUTH-001` E1).
3. **A `firebase_uid` supplied in a request body is ignored**; identity comes only from the verified
   token (`TM-AUTH-001` S1).
4. **Donor contact details are absent from a match response until that donor has accepted.**

## Bug flow

Any failure becomes a `BUG-<AREA>-###` in [`bugs/`](bugs/) with: exact repro steps, expected vs
actual, the failing output quoted verbatim, and the FR it violates. DoD step 5 blocks a milestone
while any bug on its FRs is open or in progress.

## Sign-off record

Per milestone, QA records: date, the FRs covered, the command run, its output, manual results for
push and GPS, and pass or fail. **A milestone with no recorded evidence is not signed off** — and
since QA sign-off is the only gate outside one person (`../scope.md`), an unrecorded pass is
indistinguishable from a skipped one.

| Milestone | Date | Evidence | Verdict |
|---|---|---|---|
| M2 | — | pending: `docker compose up`, Flyway history, 7 tables in `psql` | **not signed — Docker absent, `docker-compose.yml` absent** |
| M2 | 2026-08-17 | See [M2 evidence](#m2-evidence-2026-08-17) below | **signed — pass** |

### M2 evidence (2026-08-17)

M2's deliverable (root `CLAUDE.md` §4): Spring Boot init with PostgreSQL + Flyway, Flutter and
Next.js init, and `docker-compose up` running backend + web + db. No FR is in scope — M2 is
foundation, so there is nothing to test at the acceptance layer and no manual push or GPS result to
record. Every line below was run on 2026-08-17 against Docker Engine 29.7.2 / Compose v5.3.1.

**1. Stack comes up — `bash scripts/dev-up.sh`**

```
backend    Up 25 seconds (healthy)   127.0.0.1:8080->8080/tcp
postgres   Up 3 minutes (healthy)    127.0.0.1:5433->5432/tcp
web        Up 20 seconds (healthy)   127.0.0.1:3000->3000/tcp
```

All three healthy. This is the first run in which `web` reached `healthy` at all.

**2. Migration applied — `flyway_schema_history`**

```
 version | description | success
---------+-------------+---------
 1       | init        | t
```

**3. Schema is real — `psql \dt`**

Eight relations: the seven domain tables (`users`, `donor_profiles`, `hospitals`, `blood_requests`,
`request_matches`, `donations`, `blood_compatibility`) plus `flyway_schema_history`.
`select count(*) from blood_compatibility` returns **27**, the full ABO/Rh matrix.

**4. Endpoints answer**

| Request | Result |
|---|---|
| `GET :8080/api/health` | `200` `{"status":"UP"}` |
| `GET :3000/km` | `200` |
| `GET :3000/` | `307` → `http://127.0.0.1:3000/km` |

**5. Backend gate — `cd backend && ./mvnw verify`**

```
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0 -- in kh.lifelink.api.schema.SchemaIntegrationTest
Tests run: 11, Failures: 0, Errors: 0, Skipped: 0
All coverage checks have been met.
BUILD SUCCESS
```

`Skipped: 0` on `SchemaIntegrationTest` is the line that matters. It is annotated
`@Testcontainers(disabledWithoutDocker = true)`, so before today it skipped and the build still
printed `BUILD SUCCESS` — which is how the broken `users.language` column reached `main`. This is
the first local run where the schema was actually asserted.

**6. All three clients — `bash scripts/verify-all.sh`**

Ends `All checks passed.` — backend as above; web lint + typecheck + 6 vitest tests; Flutter
`No issues found!` and 4 tests.

**Three defects were found and fixed during this verification**, logged as `BUG-INFRA-001`,
`BUG-WEB-002` and `BUG-BUILD-003` in [`bugs/`](bugs/) and closed in `d1f5efd`. All six checks above
were re-run after the fixes; nothing here is pre-fix output.

**Verdict: pass.** Caveat carried forward, not blocking M2: `disabledWithoutDocker = true` still
means a developer without Docker gets a green build that proves nothing. CI covers it, but the
local signal is misleading — see the Tech Lead decision noted in `BUG-BUILD-003`.
