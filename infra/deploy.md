# Deploy Runbook — LifeLink KH

DevOps writes; Fullstack/Mobile read. CI: GitHub Actions. DB schema: Flyway migrations.

## Environments
| Env | Trigger | Notes |
|-----|---------|-------|
| local | `docker-compose up` | postgres + backend + web |
| dev | push to `main` | auto-deploy backend + web |
| play-internal | tagged release | Flutter AAB → Play Store internal testing (M7) |

## Pre-promotion checklist
- [ ] All DoD (R6) gates green for shipped FRs.
- [ ] **R5 security gate:** every auth/PII/secrets/integration change has a docs/security/reviews/ note.
- [ ] Flyway migrations reviewed; no destructive change without backup.
- [ ] Smoke checks pass (below).

## Smoke checks
- [ ] Backend `/health` 200.
- [ ] Web portal loads + login works.
- [ ] Flutter app: OTP login + create request + receive push.

## Rollback
- Backend/web: redeploy previous image tag.
- DB: Flyway `undo` / restore from nightly backup.
- Flutter: halt Play Store rollout; promote previous AAB.

## Secrets workflow
Stored in GitHub Actions secrets (FCM, SMS/OTP, Maps, DB). Never in git. Rotate on exposure.
