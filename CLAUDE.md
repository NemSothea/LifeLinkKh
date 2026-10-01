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
- Exercises grade-worthy tech: authentication, push notifications, GPS, and a cloud database with
  server-side rules (Firestore + Security Rules + the portal's functions since ADR 0009/0010; PostgreSQL before).
- Scope fits a team of 3 across ~13 weeks of development.
- Clear success metrics: donors registered, requests matched, notifications delivered.

## 2. Tech stack

Built on the **Capybara ADK** (KOSIGN Agent Development Kit) —
https://capybara.kosign.dev/en/docs/overview

| Layer         | Technology |
|---------------|------------|
| Backend       | **Firebase** (project `lifelinkkh`, region `asia-southeast1`, **Spark plan**) — Firestore + Firebase Auth + FCM. The server logic (matching, pushes, approve/confirm, the app's create-request / respond / delete-account) runs as **the portal's functions** on the Next server, `frontend/src/server/` — ADR 0010 replaced the six Cloud Functions of ADR 0009 so no card is on the project |
| Database      | Cloud Firestore + Security Rules (`firebase/firestore.rules`, emulator-tested). Replaced PostgreSQL by ADR 0009 |
| Mobile app    | **Flutter** — donor/patient app, builds native Android → Play Store. iOS build target added (DEC-006): device/simulator build only, no App Store submission, no Apple Developer account. |
| Web portal    | Next.js (App Router, TypeScript, Tailwind CSS) on Vercel Hobby (`sin1`) — public board + admin portal (admin-only in v1, DEC-014); reads Firebase over REST from the Next server, and serves the functions at `/api/functions/{name}` with the Admin SDK (ADR 0010) |
| Local dev     | Firebase Emulator Suite (`cd firebase && npm run emulators:app` — Firestore, Auth; needs Java 21) + the portal (`npm run dev`), which the app also needs for its writes. No Docker |
| CI            | GitHub Actions — owned by Tech Lead; there is no infra role |
| Push          | Firebase Cloud Messaging (FCM) — `firebase_messaging` (Flutter) |
| Location      | `geolocator` (Flutter). **No map widget** — coordinates satisfy the GPS requirement; rendering a map is a week for no marks (DEC-004) |
| i18n          | Khmer + English (both clients) |

### Why this stack
- The app already depended on Firebase for identity (Auth) and delivery (FCM); ADR 0009 moved the
  third piece — storing and matching — there too, and dropped a server the team had to run itself
  (Docker, Flyway, its own JWT, a mounted service-account key, a tunnel before any phone could
  reach it). The original request (PostgreSQL + Next.js + Docker) was met through M2–M7; the
  change is a known course risk the ADR defense has to explain.
- **Flutter** builds a native Android app directly, satisfying the course Play Store
  requirement cleanly (no Capacitor / hybrid wrapper).
- Two clients share one Firebase project: Flutter for donors/requesters on mobile, Next.js for
  the public board and the admin on the web. The Security Rules judge both the same way.

## 3. Architecture

```
            Firebase (lifelinkkh, asia-southeast1)
     ┌──────────────────────────────────────────────┐
     │  Firestore + Security Rules   Firebase Auth   │
     │  FCM                                          │
     └──────────────────────────────────────────────┘
          ▲  Firebase SDK (reads)     ▲  REST (admin ID token) + Admin SDK (the functions)
          │                           │
     Flutter app ──── POST /api/functions/{name} ────> Next.js web portal, Vercel sin1
  (donors/requesters)   createRequest · respondToMatch    (public board + admin +
     → sideloaded APK   deleteAccount                      reviewRequest · confirmDonation)
```

Since ADR 0010 there are no Cloud Functions: the portal's server is the one place that writes
what a client must not, and the rules refuse those writes to every client.

Locally the whole Firebase side runs on the Emulator Suite (`firebase/README.md`); the portal
runs with `npm run dev` pointed at it, and the Flutter app with
`--dart-define=FIRESTORE_EMULATOR=… --dart-define=PORTAL_URL=…` (the portal must be up: the app
posts, answers and deletes through it). Setup: `docs/tech-lead/local-development.md`.

## 4. Milestones (course requirement: M1 → M7, from Week 3, M7 by Week 15)

> **Week numbering corrected 2026-09-21.** The lecture slides date Week 8 (mid-term demo day) to
> **29 Aug 2026**, which puts W13 at 3 Oct, W15 at 17 Oct and W16 (final pitches + ADR defense) at
> 24 Oct. On 2026-09-21 this project was in **Week 11, not Week 15** — every "Week 15" below, and
> the v2 pitch deck's "Week 15 of 16" footer, was written against a calendar four weeks ahead of
> the real one. The lecturer's own back half: W10 networking · W11 auth/JWT · W12 testing ·
> **W13 CI/CD and publishing (signing, Play Store internal)** · W14 platform channels · W15 Kotlin
> Multiplatform · W16 final pitches. M7 therefore lines up with **W13 ≈ 3 Oct**, not mid-September.

| Milestone | Week   | Deliverable |
|-----------|--------|-------------|
| M1 | W3-4   | ERD (done), wireframes for the 4 core screens only, API spec for the 8 core FRs |
| M2 | W5-6   | Spring Boot init (PostgreSQL, Flyway), Flutter + Next.js init, `docker-compose up` runs backend+web+db |
| M3 | W7-9   | Google Sign-In + donor register + FCM token registration end-to-end (feature 1) |
| M4 | W10-12 | Request create + ABO/Rh and distance matching + eligibility computation + request-alert push + accept/decline end-to-end (feature 2) |
| M5 | W13    | Donation history list + 56-day eligibility status + the single hospital web page (feature 3) |
| M6 | W14    | GPS via `geolocator`, Khmer/English i18n, Android build, iOS build (device/simulator only, DEC-006), bug fix |
| M7 | W15    | Test pass, signed AAB, **Flutter app published to Play Store internal testing** |
| M8 | W15+   | **Not graded — added by DEC-008.** Demo scenario: a scripted walkthrough (`docs/po/demo-script.md`) for explaining the app to someone seeing it for the first time — instructor, classmate, or pilot partner |

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
>
> **Grown after M7 on 2026-09-06 — not a milestone.** A public request board (DEC-009), portal
> staff sign-in replacing the hand-minted `PORTAL_DEV_JWT` (DEC-010), the staff lifecycle around it,
> and the mobile half of `FR-GLOBAL-001`. None is a new FR and none is graded; `docs/scope.md`'s
> "Grown after M7" section records what was added and the two debts it carries.
>
> **Resequenced 2026-09-23 by DEC-012 — the demo comes first, the store release after.** The M7
> row below keeps the course's own wording; the *order of work* changed. What happens on defense
> day is a live demo from one local machine — `docker compose` on a laptop, the app on an emulator
> or tethered device, the portal in a browser — and nothing in it touches the Play Store. The
> signed AAB and the internal-testing upload are done after the demo, and only if the store link
> is actually required. `docs/decisions.md` DEC-012 states the risk this accepts: if M7's clause is
> graded literally, a graded milestone is open on the day. Open the Play Console account now
> regardless — identity verification takes days and is the only part that cannot be compressed.
>
> **Added 2026-08-29 by DEC-008 — M8, demo scenario.** Not a course requirement (the course grades
> M1–M7 only) and not an FR — a narrative script for walking a first-time viewer through the app,
> distinct from `docs/demo-runbook.md` (the Tech Lead's own command-by-command runbook for standing
> the stack up before a demo). No milestone-boundary sign-off; it is a living doc, updated whenever
> the golden path changes.
>
> **Amended 2026-09-29 by ADR 0010 / DEC-018 — the six Cloud Functions moved into the portal's
> server on Vercel; `lifelinkkh` is on the free Spark plan with no card.** Not a milestone. The app
> calls `POST /api/functions/{name}` on the portal for its three writes; matching runs when the
> admin clicks Approve. `firebase/functions/` is gone; the handlers and their tests are
> `frontend/src/server/` and `frontend/test/server/`.
>
> **Amended 2026-09-26 by ADR 0009 / DEC-014 — Firebase replaces Spring Boot + PostgreSQL; the
> portal is admin-only.** Not a milestone and not a new FR. The rows above keep the wording they
> were graded against (M2's Spring Boot/Flyway/`docker-compose` deliverable was met and signed off
> on 2026-08-17). From phase 6 there is no `backend/`, no `docker-compose*.yml` and no Postgres:
> Firestore, Firebase Auth and three Cloud Functions do that work, and the demo DEC-012 describes
> runs on the Firebase emulators (or the real `lifelinkkh` project for real pushes) instead of
> `docker compose`. DEC-014 cut hospital-staff accounts from v1 — roles are DONOR and REQUESTER in
> the app and ADMIN on the portal — and Telegram sign-in was dropped with the move. The five PRD
> metrics now come from `cd firebase && npm run metrics` instead of SQL `COUNT` queries.

## 5. Team — responsibilities (Group 2)

| Member | Role | Owns |
|--------|------|------|
| **Nem Sothea** | Tech Lead / Flutter + PO (Senior) | Architecture, Flutter mobile app, FCM push, GPS/maps, Android build & Play Store release, Firebase project and deploys. Reviews all PRs. Co-PO with Sourn Savourn. Also holds Security overlay and CI (`.github/workflows/`). |
| **Moeun Nithvaraman** | Backend / Database (Senior) | Firestore data model and Security Rules (+ their emulator tests), Cloud Functions, seed data, auth, blood-type/distance matching logic. |
| **Suon Pisey** | Frontend (Senior) | Next.js web portal (public board + admin), Firebase REST client, forms, Khmer/English i18n. |
| **Sourn Savourn** | PO (Senior) | `docs/po/` — PRD, briefs, prototypes, FRs, changelog. Co-PO with Nem Sothea. |
| **Oun Sreynich** | QA (Senior) | Test plan, e2e/integration tests, milestone acceptance, bug tracking. |

> Note: original assignment says teams of 3; this team is 5 — confirm with the instructor.
>
> Amended 2026-08-07: the DevOps/Infra and PM roles were dropped. Moeun Nithvaraman moved to PO.
> `infra/` was removed. Tech Lead absorbs `docker-compose.yml`, CI (`.github/workflows/`), the deploy
> runbook and the release. DoD tracking moved to QA and stays there — it is the only gate outside
> Tech Lead. No deploy runbook exists yet; write one before M7. See `docs/team.md`.
>
> Amended 2026-08-17: three-way role rotation. Moeun Nithvaraman → Backend/Database,
> Suon Pisey → Frontend (Next.js), Sourn Savourn → PO (co-PO with Nem Sothea).
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
