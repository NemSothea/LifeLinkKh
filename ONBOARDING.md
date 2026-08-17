# Onboarding — LifeLink KH

Welcome. This repo runs the **Capybara** multi-role framework. Read `docs/roles-and-flows.md`
and `docs/cheat-sheet.md` first.

## Day 1 — Orient
- Read root `CLAUDE.md` (product plan + governance) and `docs/po/prd.md` (requirements).
- Find your role in `docs/team.md`. Read your role guide `docs/<role>/CLAUDE.md` for your write scope (R2).
- Run `/capybara-adk:status` to see the current stage and next command.

## Day 2 — Your scope
- **PO (Sourn, co-held by Sothea):** briefs in `docs/po/briefs/`, wireframes in `docs/po/prototypes/`, FRs in `docs/po/features/` (brief → prototype → finalize). Log every FR in `changelog.md`.
- **Fullstack (Moeun/Pisey):** specs in `docs/fullstack/specs/`, API in `docs/fullstack/api-contract/`. Build `backend/` + `frontend/`.
- **Tech Lead (Sothea):** architecture + ADRs in `docs/tech-lead/`. Sign off specs. Also owns CI (`.github/workflows/`) — there is no DevOps role and no `infra/` directory.
- **Security (overlay):** `docs/security/security-checklist.md` — run the R6 gate on auth/PII/secrets/integration changes.
- **Mobile (Sothea):** Flutter in `mobile/`. Request API changes via CR-MAPI.
- **QA (Sreynich):** bugs in `docs/qa/bugs/`, test cases keyed to spec sections. Sign off vs acceptance criteria. Also tracks Definition of Done (the old PM overlay).

## Day 3 — Ship a slice
- Pick a spec'd FR → `/capybara-adk:dev` → `/capybara-adk:review` → close per the Definition of Done (R6).
- Never edit another role's folder — file a change request (R4): CR-PO / CR-MAPI / CR-SEC. (CR-DEVOPS is retired with the role; old records stay readable.)
- Cross-link IDs (R7) everywhere: `FR-`, `BUG-`, `adr/####`, `CR-`, `DEC-`.

## Before your first commit
- `git config core.hooksPath .githooks` — **required**. The hook is opt-in per clone, so without this
  the capybara validate and Java format checks silently do nothing.
- `cp .env.example .env` and fill it in. `.env` is gitignored and must never be committed.
- `bash scripts/verify-all.sh` — runs every scaffolded client's checks. `bash scripts/dev-up.sh`
  brings up the local stack (needs Docker installed).
- Read `docs/tech-lead/coding-standards.md` before writing code, `docs/qa/test-strategy.md` before
  writing tests, and `docs/security/asvs-baseline.md` (ASVS Level 1, ADR 0005) before touching auth,
  PII or secrets.

## Security first (R5)
Auth, PII (phone/location/blood type), secrets, and external integrations are in scope.
Any change to those needs a threat model + review note before merge. See `docs/security/`.
