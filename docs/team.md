# Team — LifeLink KH

| Name | Primary role | Also | Owns (R2) |
|------|--------------|------|-----------|
| Nem Sothea | Tech Lead / Mobile | PO (co), Security | docs/tech-lead/, mobile/, architecture + ADRs, CI (.github/workflows/), Play Store release |
| Suon Pisey | Fullstack (Backend/DB) | — | backend/, docs/fullstack/ (specs, API contract), PostgreSQL + Flyway |
| Sourn SAVOURN | Fullstack (Frontend) | — | frontend/ (Next.js web portal), API client, i18n |
| Moeun Nithvaraman | PO | — | docs/po/ (PRD, briefs, prototypes, FRs), changelog |
| Oun Sreynich | QA | — | docs/qa/, test cases, bug registry, DoD sign-off |

## Role index (R2)
- **PO** — product defs (docs/po/). Moeun primary; Tech Lead co-holds and drives in tooling.
- **Fullstack** — backend/ + frontend/ + docs/fullstack/. Pisey (backend), Sourn (web).
- **Tech Lead** — docs/tech-lead/ (architecture, ADRs) + CI (.github/workflows/). Sothea.
- **Security** — overlay on Tech Lead (docs/security/). Sothea.
- **Mobile** — mobile/ + docs/mobile/. Sothea (Flutter).
- **QA** — docs/qa/. Sreynich.

> **No DevOps and no PM role, and `infra/` is removed.** `docker-compose.yml` is Fullstack
> (`docs/fullstack/specs/foundation/infra-docker.md`); CI (`.github/workflows/`) is Tech Lead.
> DoD tracking that PM used to carry is now QA's, alongside sign-off.
> **Open gap:** no deploy runbook exists any more — needed before the M7 release.
> `docs/devops/` and `docs/pm/` stay in the repo as read-only history — existing
> DEC-### and CR-DEVOPS records are still cited by FRs and specs, so nothing there was deleted.

> Original assignment says teams of 3; this team is 5 — confirm with instructor.
