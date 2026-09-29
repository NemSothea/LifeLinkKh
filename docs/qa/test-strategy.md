# Test Strategy — LifeLink KH

**Owner:** QA. **Applies to:** the 8 FRs in [`../scope.md`](../scope.md). Deferred FRs get no tests.

This document defines the bar for **DoD step 3 — "QA sign-off vs acceptance criteria"**
([`../cheat-sheet.md`](../cheat-sheet.md)). Before this file existed, that step had no definition,
which in a build where one person writes the requirement, the code and the approval is the weakest
possible link. Everything here is chosen against that constraint: **tests are the only reviewer this
project has.**

> **Rewritten 2026-09-26 for ADR 0009.** The Spring Boot backend and its JUnit / `@WebMvcTest` /
> Testcontainers layers are gone with `backend/`. What they proved is now proved by **Security Rules
> tests** and **Cloud Functions tests** against the Firebase Emulator Suite. The M2 evidence at the
> end of this file is kept as the historical record it is.

## What we do not do, and why

A 13-week course project cannot afford full-pyramid coverage on three clients. Explicitly out:

| Not doing | Why |
|---|---|
| Mocking Firestore in rules or Functions tests | A mocked database proves the mock works. The emulator runs the real rules engine and the real triggers, which is where this app actually breaks |
| Testing the rules through the app | The app hides what it does not offer; the rules are the control. Rules tests call Firestore directly as each principal, including ones the UI would never produce |
| Visual regression / screenshot tests that gate CI | No design system, no budget. Layout goldens exist in `mobile/` but never gate CI |
| Load or performance testing | Pilot size is 1,000 donors (`../po/prd.md` §5). A slow query at that size is not a defect worth a harness |
| Cross-browser matrix | One portal page, one evaluator, Chrome |
| iOS push testing | The iOS target is build-only (DEC-006) and has no APNs; push is verified on Android |

## Layers, per client

### Firebase — `firebase/`

| Layer | Tool | Covers | Command |
|---|---|---|---|
| Security Rules | `@firebase/rules-unit-testing` + Vitest, Firestore emulator (`demo-lifelink`) | **One test per rule.** Each principal — signed out, donor, requester, another donor, an ADMIN claim without its `admins/{uid}` record — reading and writing each collection. A rule without a test is treated as absent (ADR 0009) | `cd firebase && npm run test:rules` |
| Functions, unit | Vitest, no emulator | Pure logic: the ABO/Rh table and its direction, the 56-day cooldown boundary, the 10 km radius, no-GPS-sorts-last, the 25-donor cap, push payloads. Every clause of the old matching SQL | `cd firebase/functions && npm test` |
| Functions, emulator | Vitest against the Firestore emulator, FCM faked | Every handler end to end: `onRequestCreated` (rate limit, match documents, alert), `onMatchAnswered` (accepted count, board row, acceptance push), `confirmDonation` (admin only, cooldown written) | `cd firebase/functions && npm run test:emulator` |
| Seed data | Node script against the emulator | 14 districts, 5 hospitals, no orphans | `cd firebase && npm run test:seed` |

On a `demo-` project the Functions write every push to `_outbox` instead of sending it — FCM has no
emulator, and this is how a test reads exactly what a donor would have received.

The emulator needs **Java 21**. Without it these layers do not run at all; a missing JDK is an
environment failure to report, never a pass.

The ABO/Rh compatibility table gets a dedicated unit test: every recipient's donor list pinned
exactly, and the direction (an O− patient is offered O− donors only). Per ADR 0004 this is a
patient-safety rule, not a feature — a wrong entry means giving incompatible blood. It is the single
highest-value test in the project.

### Web portal — `frontend/`

| Layer | Tool | Covers |
|---|---|---|
| Unit / component | Vitest + React Testing Library | The request table renders rows, empty state and error state; the Firebase REST client and session handling |
| e2e | Playwright (Chromium only) — planned, not built | One flow: open the portal, see open requests, see one rendered from seeded data |

### Mobile — `mobile/`

| Layer | Tool | Covers |
|---|---|---|
| Unit | `flutter_test` | Eligibility display logic, distance formatting, i18n key resolution |
| Widget | `flutter_test` | Donor register form validation, request card, eligibility banner |
| Integration | `integration_test` | One happy path on a device/emulator: sign in → register as donor → see eligibility status |

Push notification delivery and GPS acquisition are **verified manually** on a device and recorded in
this file's sign-off table. Neither is reliably automatable inside a course timeline, and both are
graded features, so the evidence must exist as a written manual result rather than a green tick.
Push needs the real project with Functions deployed; the local emulator stack sends none.

All of it runs in one pass with `bash scripts/verify-all.sh`, the same steps as CI's `firebase`,
`web` and `mobile` jobs.

## Coverage floor

No percentage. The bar is the named tests: **every rule in `firestore.rules` has a rules test, and
every filter in `selectCandidates` has a unit test.** The old 70 % JaCoCo floor on backend service
classes went with the backend; a line percentage over a rules file measures nothing, because a rule
can be "covered" by an allowed read while its denial path is never exercised.

## Naming

- Rules and Functions: `test('<who> <can/cannot> <what> — <why>')` — e.g.
  `a client cannot give itself a staff role — roles are claims, not fields`. A failing name must
  state the defect without opening the file.
- Web: `describe('<component>')` + `it('renders empty state when no requests')`.
- Flutter: `testWidgets('donor register rejects an empty blood type', ...)`.
- Every test that exists to satisfy an acceptance criterion cites its FR ID in a comment.

## Which FR needs which layer

| FR | Unit | Rules / widget | Emulator / e2e | Manual |
|---|---|---|---|---|
| `FR-AUTH-003` Google Sign-In | — | you create and read only your own `users/{uid}`; no client-set role | — | first-run on device |
| `FR-DONOR-001` Donor profile | — | own profile only; bad values refused; form validation | — | GPS acquisition |
| `FR-DONOR-002` 56-day eligibility | **yes — boundary cases 55/56/57 days, and never-donated** | eligibility banner | `confirmDonation` writes the cooldown | — |
| `FR-REQUEST-001` Create request | — | starts `OPEN` with zero counts; contact normalized to +855; form | rate limit closes the sixth request | — |
| `FR-MATCH-001` Matching | **compatibility table + direction, radius, no-GPS-last, own-request excluded, cap 25** | only the Function creates a match | `onRequestCreated` writes the right matches | — |
| `FR-NOTIFY-001` Push alert | payload builder | — | the alert lands in `_outbox` | **device receipt** |
| `FR-REQUEST-002` Accept / decline | — | answered once, never overwritten; nothing but the answer changes | `onMatchAnswered` counts and pushes | — |
| `FR-DONATION-001` History | date ordering | donor and admin read; no client writes | — | — |

## Non-negotiable security tests

These exist because their failure is a privacy breach, not a bug. Traced from
[`../security/security-checklist.md`](../security/security-checklist.md) and
[`TC-AUTH-001`](test-cases/TC-AUTH-001-google-sign-in-security.md). Each is a rules test.

1. **Nobody but the donor and an admin reads a donor profile** — so no other client ever sees a
   donor's coordinates (ADR 0003). Distances leave the Function rounded to half a kilometre.
2. **A client cannot give itself a role.** Roles are custom claims, and ADMIN also needs an
   `admins/{uid}` record that no client can write; a claim without the record is no access
   (`TM-AUTH-001` E1).
3. **Identity comes only from the verified token.** A document written for another uid is refused
   (`TM-AUTH-001` S1).
4. **The requester's contact is unreadable until that donor has accepted** — it lives in
   `requests/{id}/private/contact`, readable by the creator and accepting donors only.

## Bug flow

Any failure becomes a `BUG-<AREA>-###` in [`bugs/`](bugs/) with: exact repro steps, expected vs
actual, the failing output quoted verbatim, and the FR it violates. DoD step 5 blocks a milestone
while any bug on its FRs is open or in progress.

## Sign-off record

Per milestone, QA records: date, the FRs covered, the command run, its output, manual results for
push and GPS, and pass or fail. **A milestone with no recorded evidence is not signed off** — and
since QA sign-off is the only gate outside one person (`../scope.md`), an unrecorded pass is
indistinguishable from a skipped one.

> The rows below predate ADR 0009. They are evidence of what was true on their dates — the M2
> commands (`docker compose`, `./mvnw verify`) no longer exist in this repository.

| Milestone | Date | Evidence | Verdict |
|---|---|---|---|
| M2 | — | pending: `docker compose up`, Flyway history, 7 tables in `psql` | **not signed — Docker absent, `docker-compose.yml` absent** |
| M2 | 2026-08-17 | See [M2 evidence](#m2-evidence-2026-08-17) below | **signed — pass** |
| M3 | 2026-09-27 | FRs: `FR-AUTH-003`, `FR-DONOR-001` (register), FCM token registration. Run on the Firebase stack (ADR 0009), commit `2922fa1`, clean tree. **`bash scripts/verify-all.sh`** exit 0, ends `All checks passed.`: rules 51/51, Functions unit 22/22, Functions emulator 40/40, web lint + `tsc` clean, web 57/57, `flutter analyze` `No issues found!`, `flutter test` `+257: All tests passed!`. **0 skipped** in every layer. M3 rules tests in that run: `you create and read your own user doc`, `another user cannot read it — the FCM token addresses a push to you`, `a client cannot give itself a staff role — roles are claims, not fields`, `you cannot write someone else's user doc`, `you register your own profile, without GPS (ADR 0003)`, `a profile for someone else is refused`, `nobody but the donor and an admin reads a profile — not staff, not a requester`. Flutter: `sign_in_flow_test`, `donor_registration_flow_test`, `push_registration_service_test`, `firestore_fcm_token_repository_test`. **Manual, confirmed by Sothea 2026-09-27** (device not recorded): Google sign-in on first run lands in the app; `fcmToken` seen on `users/{uid}` after sign-in; `BUG-MOBILE-005` retested, donor Home loads on an installed APK. **Not run:** mobile `integration_test` (no `mobile/integration_test/` exists). GPS acquisition is M6, out of scope here | **signed — pass**, with caveats: no device integration test; `BUG-MOBILE-005` still says `fixed` in `bugs/index.md` and needs closing |

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
