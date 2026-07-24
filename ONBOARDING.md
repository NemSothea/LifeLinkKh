# Onboarding — LifeLink KH

Welcome. This repo runs the **Capybara** multi-role framework. Read `docs/roles-and-flows.md`
and `docs/cheat-sheet.md` first.

## Day 1 — Orient
- Read root `CLAUDE.md` (product plan + governance) and `docs/po/prd.md` (requirements).
- Find your role in `docs/team.md`. Read your role guide `docs/<role>/CLAUDE.md` for your write scope (R2).
- Run `/capybara-adk:status` to see the current stage and next command.

## Day 2 — Your scope
- **PO:** open FRs in `docs/po/features/` (thin FR → prototype → finalize). Log every FR in `changelog.md`.
- **Fullstack (Pisey/Sourn):** specs in `docs/fullstack/specs/`, API in `docs/fullstack/api-contract/`. Build `backend/` + `frontend/`.
- **Tech Lead (Sothea):** architecture + ADRs in `docs/tech-lead/`. Sign off specs.
- **Security (overlay):** `docs/security/security-checklist.md` — run the R6 gate on auth/PII/secrets/integration changes.
- **Mobile (Sothea):** Flutter in `mobile/`. Request API changes via CR-MAPI.
- **QA (Sreynich):** bugs in `docs/qa/bugs/`, test cases keyed to spec sections. Sign off vs acceptance criteria.
- **DevOps (Moeun):** pipeline (`.github/workflows/`) + runbook `infra/deploy.md`.

## Day 3 — Ship a slice
- Pick a spec'd FR → `/capybara-adk:dev` → `/capybara-adk:review` → close per the Definition of Done (R6).
- Never edit another role's folder — file a change request (R4): CR-PO / CR-DEVOPS / CR-MAPI / CR-SEC.
- Cross-link IDs (R7) everywhere: `FR-`, `BUG-`, `adr/####`, `CR-`, `DEC-`.

## Security first (R5)
Auth, PII (phone/location/blood type), secrets, and external integrations are in scope.
Any change to those needs a threat model + review note before merge. See `docs/security/`.
