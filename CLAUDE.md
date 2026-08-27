# LifeLink KH (ជីវិត) — Blood Donor Matching App

> **Group 2** — Track B team product for **Cross-Platform Mobile App Development** (16-week course).
> This file is the source of truth for the project plan. Update it as decisions change.
>
> **Framework:** this repo runs the **Capybara** multi-role framework (always `full` tier).
> Governance lives in `docs/roles-and-flows.md`; the rulebook (R1–R8), role scopes, and
> Definition of Done are summarized in `docs/cheat-sheet.md`. Framework state:
> `.capybara/setup.md` + `.capybara/brief.md` (committed team state — never gitignore/delete).

## 1. What we are building

A blood-donor matching app for Cambodia. It connects patients/families who urgently
need blood with nearby eligible voluntary donors, replacing the current ad-hoc
Facebook-post approach used by hospitals and the National Blood Transfusion Center.

- **Problem:** Blood emergencies have no fast, systematic way to reach matching nearby donors.
- **Target user:** Voluntary blood donors and patient families in Phnom Penh (hospitals later).
- **Why mobile, not just a website:** Blood emergencies need instant location-aware push
  alerts to a donor's phone — a website cannot push time-critical notifications or read
  real-time GPS the way an installed mobile app can.

### Three core features
1. **Donor register** — blood type, location, last-donation date, with automatic
   eligibility check (56-day cooldown rule).
2. **Urgent request broadcast** — a family or hospital posts a need; the app push-notifies
   matching donors filtered by blood type and distance.
3. **Donation history + eligibility reminder** — tracks the 56-day cooldown and notifies
   a donor when they become eligible to donate again.

### Why we chose it
- Real, life-saving social impact — strong story for the project defense.
- Exercises grade-worthy tech: authentication, push notifications, GPS, and a relational database.
- Scope fits a team of 3 across ~13 weeks of development.
- Clear success metrics: donors registered, requests matched, notifications delivered.

## 2. Tech stack

Built on the **Capybara ADK** (KOSIGN Agent Development Kit) —
https://capybara.kosign.dev/en/docs/overview

| Layer         | Technology |
|---------------|------------|
| Backend       | Spring Boot (JPA, Flyway migrations, Spring Security) |
| Database      | PostgreSQL |
| Mobile app    | **Flutter** — donor/patient app, builds native Android → Play Store. iOS build target added (DEC-006): device/simulator build only, no App Store submission, no Apple Developer account. |
| Web portal    | Next.js (App Router, TypeScript, Tailwind CSS) — hospital/admin portal |
| Local dev     | Docker / docker-compose (postgres + backend + web) |
| CI            | GitHub Actions — owned by Tech Lead; there is no infra role |
| Push          | Firebase Cloud Messaging (FCM) — `firebase_messaging` (Flutter) |
| Location      | `geolocator` (Flutter). **No map widget** — coordinates satisfy the GPS requirement; rendering a map is a week for no marks (DEC-004) |
| i18n          | Khmer + English (both clients) |

### Why this stack
- Matches the requested stack: PostgreSQL backend, Next.js web frontend, Docker.
- **Flutter** builds a native Android app directly, satisfying the course Play Store
  requirement cleanly (no Capacitor / hybrid wrapper).
- Two clients share one Spring Boot + PostgreSQL API: Flutter for donors/patients on
  mobile, Next.js for hospitals/admin on the web.

## 3. Architecture

```
                 Spring Boot API  ──>  PostgreSQL
                     ▲        ▲
        REST / HTTP  │        │  REST / HTTP
                     │        │
        Flutter app ─┘        └─ Next.js web portal
     (donors/patients)          (hospitals/admin)
      → Play Store
```

Backend + web + database run locally via `docker-compose` (services: `postgres`,
`backend`, `web`). The Flutter app runs on device/emulator against the same API.

## 4. Milestones (course requirement: M1 → M7, from Week 3, M7 by Week 15)

| Milestone | Week   | Deliverable |
|-----------|--------|-------------|
| M1 | W3-4   | ERD (done), wireframes for the 4 core screens only, API spec for the 8 core FRs |
| M2 | W5-6   | Spring Boot init (PostgreSQL, Flyway), Flutter + Next.js init, `docker-compose up` runs backend+web+db |
| M3 | W7-9   | Google Sign-In + donor register + FCM token registration end-to-end (feature 1) |
| M4 | W10-12 | Request create + ABO/Rh and distance matching + eligibility computation + request-alert push + accept/decline end-to-end (feature 2) |
| M5 | W13    | Donation history list + 56-day eligibility status + the single hospital web page (feature 3) |
| M6 | W14    | GPS via `geolocator`, Khmer/English i18n, Android build, iOS build (device/simulator only, DEC-006), bug fix |
| M7 | W15    | Test pass, signed AAB, **Flutter app published to Play Store internal testing** |

> Amended 2026-07-31 by DEC-001, DEC-002, DEC-003 (`docs/decisions.md`) — eligibility computation and
> request-alert push moved earlier so each milestone can satisfy its own acceptance criteria.
>
> **Rescheduled 2026-08-07 by DEC-004 (scope cut).** M3 and M4 get three weeks each, because that is
> where a project of this shape actually slips; the slack comes from collapsing the old M5 and M6.
> Eight FRs are deferred — see `docs/scope.md`. DEC-003's per-milestone metric capture is **withdrawn**
> with `FR-GLOBAL-002`: the five PRD metrics come from SQL `COUNT` queries against pilot data at demo
> time instead.
>
> **Amended 2026-08-27 by DEC-006 — iOS added to M6.** Build-only target: `flutter build ios`
> to simulator/device, no signing, no App Store/TestFlight, no Apple Developer account. Play Store
> internal testing (M7) is still the only store release in scope.

## 5. Team — responsibilities (Group 2)

| Member | Role | Owns |
|--------|------|------|
| **Nem Sothea** | Tech Lead / Flutter + PO (Senior) | Architecture, Flutter mobile app, FCM push, GPS/maps, Android build & Play Store release. Reviews all PRs. Co-PO with Sourn SAVOURN. Also holds Security overlay and CI (`.github/workflows/`). |
| **Moeun Nithvaraman** | Backend / Database (Senior) | Spring Boot API, PostgreSQL schema, Flyway migrations, auth, blood-type/distance matching logic. |
| **Suon Pisey** | Frontend (Senior) | Next.js web portal (hospital/admin), API client, forms, Khmer/English i18n. |
| **Sourn SAVOURN** | PO (Senior) | `docs/po/` — PRD, briefs, prototypes, FRs, changelog. Co-PO with Nem Sothea. |
| **Oun Sreynich** | QA (Senior) | Test plan, e2e/integration tests, milestone acceptance, bug tracking. |

> Note: original assignment says teams of 3; this team is 5 — confirm with the instructor.
>
> Amended 2026-08-07: the DevOps/Infra and PM roles were dropped. Moeun Nithvaraman moved to PO.
> `infra/` was removed. Tech Lead absorbs `docker-compose.yml`, CI (`.github/workflows/`), the deploy
> runbook and the release. DoD tracking moved to QA and stays there — it is the only gate outside
> Tech Lead. No deploy runbook exists yet; write one before M7. See `docs/team.md`.
>
> Amended 2026-08-17: three-way role rotation. Moeun Nithvaraman → Backend/Database,
> Suon Pisey → Frontend (Next.js), Sourn SAVOURN → PO (co-PO with Nem Sothea).
> Write scopes (R2) move with the roles; nothing else changes.

## 6. Course context

- **Track A (FieldLog):** each member's separate personal capstone — NOT this project.
- **Track B (this project):** the team's shared product.
- Team of 3, formed and posted in the class group by Monday.

## 7. Working with Capybara ADK

Drive the lifecycle with the orchestrator: `/capybara-adk:capybara <verb>`
(verbs: init · project · plan · dev · review · deploy · status).

Relevant skills:
- `dev-springboot-init`, `dev-springboot-api` — backend
- `dev-nextjs-init`, `dev-nextjs-page`, `dev-nextjs-component` — web portal
- `flutter-init`, `flutter-feature`, `flutter-screen`, `flutter-widget` — mobile app
- `po-project-init` — PRD + wireframes (M1)
- `dev-project-init` — DB schema, SQL, ERD, API spec (M1)
