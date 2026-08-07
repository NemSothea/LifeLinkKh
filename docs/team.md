# Team — LifeLink KH (Group 2)

| Name | Primary role | Also | Owns (R2) |
|------|--------------|------|-----------|
| Nem Sothea | Tech Lead / Mobile | PO (co), Security | docs/tech-lead/, mobile/, architecture + ADRs, `docker-compose.yml`, CI (.github/workflows/), deploy runbook, Play Store release |
| Suon Pisey | Fullstack (Backend/DB) | — | backend/, docs/fullstack/ (specs, API contract), PostgreSQL + Flyway |
| Sourn SAVOURN | Fullstack (Frontend) | — | frontend/ (Next.js web portal), API client, i18n |
| Moeun Nithvaraman | PO | — | docs/po/ (PRD, briefs, prototypes, FRs), changelog |
| Oun Sreynich | QA | — | docs/qa/, test cases, bug registry, DoD sign-off |

## Role index (R2)
- **PO** — product defs (docs/po/). Moeun primary; Tech Lead co-holds and drives in tooling.
- **Fullstack** — backend/ + frontend/ + docs/fullstack/. Pisey (backend), Sourn (web).
- **Tech Lead** — docs/tech-lead/ (architecture, ADRs) + `docker-compose.yml` + CI + deploy runbook + release. Sothea.
- **Security** — overlay on Tech Lead (docs/security/). Sothea.
- **Mobile** — mobile/ + docs/mobile/. Sothea (Flutter).
- **QA** — docs/qa/. Sreynich.

> **No DevOps and no PM role, and `infra/` is removed.** Tech Lead absorbs everything those roles
> held: `docker-compose.yml`, CI (`.github/workflows/`), the deploy runbook, and the release.
> **DoD tracking stays with QA** — with Tech Lead also holding Security and co-PO, QA sign-off is the
> only gate outside one person, so it must not migrate.
> **Open gap:** no deploy runbook exists any more — needed before the M7 release.
> `docs/devops/` and `docs/pm/` were **deleted**. The two artefacts that outlived the PM role were
> relocated to the `docs/` root, because a decision register and a risk register belong to the project,
> not to a role: [`docs/decisions.md`](decisions.md) (DEC-001..003) and [`docs/risks.md`](risks.md).
> CR-DEVOPS records were not kept — recoverable from git history at `3e93e6b` if ever needed.

> Original assignment says teams of 3; this team is 5 — confirm with instructor.
