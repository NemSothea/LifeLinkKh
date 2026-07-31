# LifeLink KH (ជីវិត) — Blood Donor Matching App

> Track B team product for **Cross-Platform Mobile App Development** (16-week course).
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
| Mobile app    | **Flutter** — donor/patient app, builds native Android → Play Store |
| Web portal    | Next.js (App Router, TypeScript, Tailwind CSS) — hospital/admin portal |
| Infra         | Docker / docker-compose (postgres + backend + web) |
| Push          | Firebase Cloud Messaging (FCM) — `firebase_messaging` (Flutter) |
| Location      | `geolocator` / `google_maps_flutter` (Flutter) |
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
| M1 | W3-4   | PRD + wireframes, DB schema/ERD, API spec, repo + Docker skeleton |
| M2 | W5-6   | Spring Boot init (PostgreSQL, Flyway), Flutter + Next.js init, `docker-compose up` runs backend+web+db |
| M3 | W7-8   | Auth (phone/OTP) + donor register incl. FCM token registration: API, Flutter screen, web portal (feature 1) end-to-end |
| M4 | W9-10  | Urgent request create + matching by blood type/distance + 56-day eligibility computation + FCM request-alert push (feature 2) end-to-end |
| M5 | W11-12 | Donation history + donor eligibility status + eligibility reminder push (feature 3) |
| M6 | W13    | GPS/maps in Flutter, Khmer/English i18n, web portal polish, Android build |
| M7 | W14-15 | Test pass, signed AAB, **Flutter app published to Play Store internal testing** |

> M3–M5 rows amended 2026-07-31 by DEC-001, DEC-002, DEC-003 (`docs/pm/decisions.md`) — eligibility
> computation and request-alert push moved earlier so each milestone can satisfy its own acceptance
> criteria. From M3 onward, every milestone's Definition of Done also includes recording that
> feature's metric events (DEC-003).

## 5. Team — responsibilities

| Member | Role | Owns |
|--------|------|------|
| **Nem Sothea** | Tech Lead / Flutter + PO (Senior) | Architecture, Flutter mobile app, FCM push, GPS/maps, Android build & Play Store release. Reviews all PRs. Also acts as PO — owns `docs/po/` (PRD, briefs, prototypes, FRs). |
| **Suon Pisey** | Backend / Database (Senior) | Spring Boot API, PostgreSQL schema, Flyway migrations, auth, blood-type/distance matching logic. |
| **Sourn SAVOURN** | Frontend (Senior) | Next.js web portal (hospital/admin), API client, forms, Khmer/English i18n. |
| **Moeun Nithvaraman** | Infra (Senior) | Docker / docker-compose, CI, environments, release pipeline. |
| **Oun Sreynich** | QA (Senior) | Test plan, e2e/integration tests, milestone acceptance, bug tracking. |

> Note: original assignment says teams of 3; this team is 5 — confirm with the instructor.

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
