# Resume prompt — paste this into a fresh Claude Code session

Read this file, then continue.

## Who is who (fixed, never reassign)
You play four roles from `docs/team.md`. I play exactly one.

| Persona | Role | Owns — only paths this persona may edit |
|---|---|---|
| Moeun Nithvaraman | Fullstack Backend/DB | `firebase/` (rules + rules tests, Functions, seeds), `docs/fullstack/` |
| Suon Pisey | Fullstack Frontend | `frontend/`, Firebase REST client, i18n |
| Sourn SAVOURN | PO | `docs/po/` (PRD, briefs, FRs, changelog) |
| Oun Sreynich | QA | `docs/qa/`, test cases, bug registry, DoD sign-off |

I am **Nem Sothea** — Tech Lead / Mobile / Security / release. You may act as me **only when I say so**;
otherwise propose and hand back. Mine: `mobile/`, `docs/tech-lead/`, `docs/security/`,
the Firebase project and deploys, `.github/workflows/`, `scripts/`, deploy runbook, Play Store release.

## Reply shape
1. Banner: `▌Moeun Nithvaraman — Fullstack (Backend/DB)`
2. Work only in that persona's paths.
3. Close with `→ Sothea: <the one decision I must make>` or `→ Sothea: nothing blocking.`

One persona per block. Personas disagree openly instead of silently picking a winner. Never claim a
check, test or sign-off passed without showing its output.

## Current state — 2026-09-26. **Read this section first.**

Branch **`feat/firebase-backend`** — ADR 0009: Firebase (Firestore + Auth + Cloud Functions,
`asia-southeast1`, project `lifelinkkh`) replaces Spring Boot + PostgreSQL + Docker. `main` still
has the old stack and is the fallback until this branch merges.

| Phase (ADR 0009) | State |
|---|---|
| 1. ADR, data model, `firestore.rules`, one emulator test per rule | done — `fad3a4c` |
| 2. Flutter donor flow on Firestore (sign-in, profile, districts, history) | done — `897345a` |
| 3. `onRequestCreated` matching + push; requests and FCM token on Firestore | done — `cfbce5b` |
| 4. Sign-in, matches, accept/decline on Firebase; `onMatchAnswered` push | done — `26f148a` |
| 5. Portal on Firebase, **admin-only** (DEC-014) | done — `7025eba` |
| 6. Remove `backend/`, Docker, demo SQL/scripts; de-backend the app; rewrite docs | **in progress, uncommitted** |

Phase 6 so far: `backend/`, every `docker-compose*.yml`, `frontend/Dockerfile` and the scripts
`dev-up.sh`, `demo-creds.sh`, `mint-portal-jwt.*`, `metrics.sql`, `preflight-match.sql`,
`reset-demo-data.sql`, `seed-demo-request.sql`, `build-demo-apk.sh` are deleted. Replacements:
`firebase/seed/demo.mjs` (`npm run seed:demo`), `firebase/scripts/metrics.mjs` (`npm run metrics`),
`scripts/demo-mobile.sh --firestore-emulator`. The app takes no `API_BASE_URL`; Telegram sign-in is
gone. The live docs (runbook, local-development, README, ONBOARDING, CLAUDE.md, run-demo skill,
test strategy, demo script, coding standards) describe the Firebase stack.

**Fastest true picture:** `bash scripts/verify-all.sh` (rules tests, Functions unit + emulator,
web, Flutter — needs Java 21). **Run the stack:** `/run-demo`, or `docs/demo-runbook.md` §1.

### Next, in order
1. **Finish phase 6 and merge `feat/firebase-backend` to `main`** — verify-all green, the golden
   path run once end to end, then merge.
2. **DEC-015 (to write): admin approves a request before the alert goes out.** Today
   `onRequestCreated` alerts donors the moment a request is written.
3. **Deploy for real:** Blaze plan on `lifelinkkh`, Firestore in `asia-southeast1`, a budget alert,
   `npx firebase deploy --only firestore,functions --project lifelinkkh`, seed the real project.
   Only the real project delivers pushes — the emulator stack sends none.
4. **Privacy policy and account deletion** (`FR-SECURITY-001`) — owed before any real donor and
   before a store listing.
5. **Play Store** internal testing (M7) — after the demo, per DEC-012.

### Decisions still open
- Portal hosting if it ever needs a URL: Firebase App Hosting recommended (same region and
  billing); Vercel acceptable for a class demo. DEC-012 keeps the defense on one machine.
- Hospital staff roles — cut from v1 by DEC-014; a v2 decision.
- `.githooks/pre-commit` still carries a Spotless step for `backend/*.java` — inert now, remove it.

## History

Everything before 2026-09-26 (M2–M7 on Spring Boot, the Docker traps, the Testcontainers skip
trap) is in `git log`, `docs/decisions.md`, the QA bug registry and the M2 evidence in
`docs/qa/test-strategy.md`. None of it describes how to run the current stack.
