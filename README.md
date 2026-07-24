# LifeLink KH (ជីវិត) — Blood Donor Matching App

Connecting patients and families who urgently need blood with nearby eligible
voluntary donors in Cambodia — replacing the slow, ad-hoc Facebook-post approach
hospitals use today.

> **Track B team product** · Cross-Platform Mobile App Development (16-week course).
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
| Location   | Google Maps / geolocator |
| Infra      | Docker · docker-compose · GitHub Actions |

## Repository layout

```
backend/    Spring Boot + PostgreSQL API
frontend/   Next.js web portal (hospital/admin)
mobile/     Flutter app (donors/patients)
infra/      Deploy runbook (docs only; pipeline in .github/workflows/)
docs/       Capybara multi-role docs (see below)
.capybara/  Framework state — brief.md, setup.md, validate.sh
```

## Getting started

> Prerequisites: Docker + docker-compose, JDK 17+, Node 20+, Flutter SDK.

```bash
# Backend + web portal + database
docker-compose up          # → API on :8080, web on :3000, postgres on :5432

# Flutter app (device or emulator, against the local API)
cd mobile && flutter run
```

_(Concrete run commands land as `/capybara-adk:dev` scaffolds each module.)_

---

## Team

| Name | Role |
|------|------|
| Nem Sothea | Tech Lead / Mobile (Flutter) |
| Suon Pisey | Backend / Database |
| Sourn SAVOURN | Frontend (Next.js) |
| Moeun Nithvaraman | DevOps / Infra |
| Oun Sreynich | QA |

See [`docs/team.md`](docs/team.md).

## Milestones (M1 → M7)

| # | Week | Deliverable |
|---|------|-------------|
| M1 | W3-4 | PRD, wireframes, DB schema/ERD, API spec, Docker skeleton |
| M2 | W5-6 | Backend + web + Flutter init; `docker-compose up` runs the stack |
| M3 | W7-8 | Auth (OTP) + donor register end-to-end |
| M4 | W9-10 | Urgent request + matching |
| M5 | W11-12 | History + cooldown + FCM push |
| M6 | W13 | GPS/maps, Khmer/English i18n, Android build |
| M7 | W14-15 | **Published to Play Store internal testing** |

Full plan in [`CLAUDE.md`](CLAUDE.md).

## Development framework

This repo runs the **Capybara** multi-role framework (KOSIGN ADK). Start here:

- [`ONBOARDING.md`](ONBOARDING.md) — Day 1/2/3 for new contributors
- [`docs/roles-and-flows.md`](docs/roles-and-flows.md) — who owns what + how work flows
- [`docs/cheat-sheet.md`](docs/cheat-sheet.md) — lifecycle, IDs, Definition of Done
- [`docs/po/prd.md`](docs/po/prd.md) — product requirements

Lifecycle: `init → project → plan → dev → review → deploy`. Check status any time with
`/capybara-adk:status`.

## License

Course project — not for production use.
