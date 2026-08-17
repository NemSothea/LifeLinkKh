# LifeLink KH (ជីវិត) — Blood Donor Matching App

Connecting patients and families who urgently need blood with nearby eligible
voluntary donors in Cambodia — replacing the slow, ad-hoc Facebook-post approach
hospitals use today.

> **Group 2** · Track B team product · Cross-Platform Mobile App Development (16-week course).
> Course milestone **M7** = published to Google Play internal testing by Week 15.

---

## Why

Cambodia faces chronic blood shortages. When a patient needs blood fast, there is no
systematic way to alert compatible donors nearby. LifeLink KH sends **instant,
location-aware push alerts** to matching donors' phones — something a website cannot do.

## What it does

1. **Donor register** — blood type, location, last-donation date, with an automatic
   56-day eligibility check.
2. **Urgent request broadcast** — a family or hospital posts a need; the app push-notifies
   matching donors filtered by ABO/Rh compatibility and distance.
3. **Donation history + eligibility reminder** — tracks the 56-day cooldown and reminds a
   donor when they can give again.

## Users

- **Donor / Requester** → Flutter mobile app (Android, Play Store).
- **Hospital staff / Admin** → Next.js web portal.

---

## Architecture

```
                 Spring Boot API  ──>  PostgreSQL (Flyway migrations)
                     ▲        ▲
        REST/HTTPS   │        │   REST/HTTPS
        Flutter app ─┘        └─ Next.js web portal
     (donors/patients)          (hospitals/admin)
      → Play Store
```

| Layer      | Tech |
|------------|------|
| Backend    | Spring Boot · PostgreSQL · Flyway · Spring Security (JWT) |
| Web portal | Next.js (App Router, TypeScript, Tailwind) |
| Mobile     | Flutter (native Android → Play Store) |
| Push       | Firebase Cloud Messaging (FCM) |
| Location   | geolocator (no map widget — see `docs/scope.md`) |
| Local dev  | Docker · docker-compose (postgres + backend + web) |
| CI         | GitHub Actions (owned by Tech Lead) |

## Repository layout

```
backend/            Spring Boot + PostgreSQL API        (scaffolded at M2)
frontend/           Next.js web portal, hospital/admin  (scaffolded at M2)
mobile/             Flutter app, donors/patients        (scaffolded at M2)
.github/workflows/  CI pipeline (owned by Tech Lead)
docker-compose.yml  postgres + backend + web, local dev only (owned by Tech Lead)
docs/               Capybara multi-role docs (see below)
.capybara/          Framework state — brief.md, setup.md, validate.sh
```

## Getting started

> Prerequisites: Docker Desktop (Compose v2), **JDK 21**, **Node 22**, Flutter SDK.
> Node 20 trips `EBADENGINE` — CI and both Dockerfiles pin 22.

```bash
cp .env.example .env       # then fill it in — see the runbook. NEVER commit .env
bash scripts/dev-up.sh     # → API on :8080, web on :3000, postgres on :5432
                           #   all bound to 127.0.0.1

# Flutter app (device or emulator, against the local API)
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

**Full runbook — install, `.env` values, and every failure we have actually hit:
[`docs/tech-lead/local-development.md`](docs/tech-lead/local-development.md).** Read it before your
first run. `POSTGRES_DB` and `POSTGRES_USER` are a shared team convention documented there; only
`POSTGRES_PASSWORD` is yours alone.

Use `scripts/dev-up.sh` rather than a bare `docker compose up` — it waits for health and then prints
the applied Flyway migrations, which is the evidence QA signs each milestone against.

`--dart-define=API_BASE_URL` is **required** — the app fails fast with a clear error rather than
falling back to a default host. `10.0.2.2` is the Android emulator's alias for your machine, where
Compose publishes the backend.

Layer-by-layer setup, including the Flyway schema and the Compose service definitions, is specified in
[`docs/fullstack/specs/foundation/`](docs/fullstack/specs/foundation/).

_(All three code directories were scaffolded at M2 — see `docs/decisions.md`.)_

---

## Team — Group 2

| Name | Role |
|------|------|
| Nem Sothea | Tech Lead / Mobile (Flutter) · also PO, Security |
| Moeun Nithvaraman | Backend / Database |
| Suon Pisey | Frontend (Next.js) |
| Sourn SAVOURN | PO |
| Oun Sreynich | QA |

See [`docs/team.md`](docs/team.md) for write scopes (R2) and the acting-role overlays.

> There is no separate DevOps/Infra role, and `infra/` has been removed. CI
> Tech Lead absorbs all of it: `docker-compose.yml`, CI (`.github/workflows/`), the deploy runbook,
> and the Play Store release. **QA keeps Definition-of-Done tracking**, so one signature on a merge
> still comes from outside Tech Lead. No deploy runbook exists yet — needed before M7.

> Tech Lead also holding Security, and co-holding PO, collapses Definition of Done step 1 toward
> self-approval — Sourn as second PO restores an independent product-sign-off voice, but QA remains
> the only independent gate on Security. Logged in [`docs/risks.md`](docs/risks.md).

## Milestones

M1 → M7, ending with the Flutter app published to Play Store internal testing by Week 15.

The milestone table lives in **[`CLAUDE.md`](CLAUDE.md) section 4 and nowhere else** — it is not
copied here. Milestone assignments change (see [`docs/decisions.md`](docs/decisions.md)), and a
second copy would silently go stale.

## Development framework

This repo runs the **Capybara** multi-role framework (KOSIGN ADK). Start here:

- [`ONBOARDING.md`](ONBOARDING.md) — Day 1/2/3 for new contributors
- [`docs/roles-and-flows.md`](docs/roles-and-flows.md) — who owns what + how work flows
- [`docs/cheat-sheet.md`](docs/cheat-sheet.md) — lifecycle, IDs, Definition of Done

**Picking up work — start here:**

| File | What it holds |
|---|---|
| [`docs/po/features/index.md`](docs/po/features/index.md) | **Feature registry** — all 19 FRs with area, priority, status, milestone, and which are blocked |
| [`docs/po/prd.md`](docs/po/prd.md) | Product requirements and acceptance criteria for FR-01..FR-12 |
| [`docs/fullstack/specs/foundation/`](docs/fullstack/specs/foundation/) | Per-layer M2 build specs, each with a binary done-when checklist |
| [`docs/po/briefs/roadmap.md`](docs/po/briefs/roadmap.md) | Product decisions still open, and the milestone each one blocks |
| [`docs/po/prototypes/roadmap.md`](docs/po/prototypes/roadmap.md) | Which screens get wireframed by which milestone |
| [`docs/decisions.md`](docs/decisions.md) | Decisions taken (DEC), with rationale |
| [`docs/risks.md`](docs/risks.md) | Open risks and agreed mitigations |
| [`docs/tech-lead/adr/`](docs/tech-lead/adr/) | Architecture decision records |

Lifecycle: `init → project → plan → dev → review → deploy`. Check status any time with
`/capybara-adk:status`.
## Google Drive
### Cross-Platform Mobile Application Development ៖ https://drive.google.com/drive/folders/1hdO18bbErVAlMxPNut1zn1_rcU6RVyFu?usp=drive_link

## License

Course project — not for production use.
