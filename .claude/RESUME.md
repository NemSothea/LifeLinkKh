# Resume prompt — paste this into a fresh Claude Code session

Read this file, then continue.

## Who is who (fixed, never reassign)
You play four roles from `docs/team.md`. I play exactly one.

| Persona | Role | Owns — only paths this persona may edit |
|---|---|---|
| Moeun Nithvaraman | Fullstack Backend/DB | `backend/`, `docs/fullstack/`, PostgreSQL schema, Flyway migrations |
| Suon Pisey | Fullstack Frontend | `frontend/`, API client, i18n |
| Sourn SAVOURN | PO | `docs/po/` (PRD, briefs, FRs, changelog) |
| Oun Sreynich | QA | `docs/qa/`, test cases, bug registry, DoD sign-off |

I am **Nem Sothea** — Tech Lead / Mobile / Security / release. You may act as me **only when I say so**;
otherwise propose and hand back. Mine: `mobile/`, `docs/tech-lead/`, `docs/security/`,
`docker-compose.yml`, `.github/workflows/`, `scripts/`, deploy runbook, Play Store release.

## Reply shape
1. Banner: `▌Moeun Nithvaraman — Fullstack (Backend/DB)`
2. Work only in that persona's paths.
3. Close with `→ Sothea: <the one decision I must make>` or `→ Sothea: nothing blocking.`

One persona per block. Personas disagree openly instead of silently picking a winner. Never claim a
check, test or sign-off passed without showing its output.

## Where the project stands (2026-08-10)
M2 merged to `main` (merge commit `1736157`, pushed):
- `backend/` — Spring Boot 3.5.6 / Java 21, `V1__init.sql` with 7 tables + 27 ABO/Rh rows, Spotless,
  JaCoCo 70 %, Testcontainers. `./mvnw verify` green.
- `frontend/` — Next 15.5.23, Tailwind 4, next-intl, `/` → `/km`, health page. lint + types + 6 tests green.
- `mobile/` — Flutter 3.44.6, `applicationId kh.lifelink.app`, Riverpod + go_router + Dio, km/en ARB.
  `flutter analyze` clean, 4 tests, debug APK builds.
- Standards: `docs/tech-lead/coding-standards.md`, `docs/security/asvs-baseline.md` (ASVS L1, ADR 0005),
  `docs/qa/test-strategy.md`. Commands: `/verify-all`, `/milestone-signoff`, `/fr-security-check`.

Run `bash scripts/verify-all.sh` first — it is the fastest true picture.

## What the first CI run taught us (fixed in `ab8b52d`)
The Testcontainers schema tests skip on this Mac (no Docker) but run in CI, and they immediately
caught `users.language` declared as `columnDefinition = "char(2)"` — Hibernate maps that to VARCHAR
while PostgreSQL reports `bpchar`, so `ddl-auto=validate` refused to start. Fixed with
`@JdbcTypeCode(SqlTypes.CHAR)`. Also: CI Node 20 → 22, and `npm ci` → `npm install` because the
macOS-generated lockfile omits Linux-only optional deps.

**Rule this proves:** until Docker is installed here, a green local `verify-all.sh` does not mean the
schema is right. Only CI can say that.

## Session of 2026-08-17 — M2 signed off. Read this section; the two below it are history.

Branch `chore/role-rotation-2026-08-17`, three commits, **not merged, not pushed**:
`ed2db08` role rotation docs · `d1f5efd` the three stack fixes · `8492425` QA evidence + bug registry.

Steps 1 and 2 below both pass now. `docker compose ps` shows all three services `healthy`;
`./mvnw verify` reports `SchemaIntegrationTest ... Skipped: 0`, 11 tests, coverage met;
`verify-all.sh` ends `All checks passed.` Full evidence: sign-off table at the end of
`docs/qa/test-strategy.md`. Step 3 is done. **Only step 4 (M3) is left.**

Three blockers had to be cleared first, all written up in `docs/qa/bugs/`:
`BUG-INFRA-001` host PostgreSQL 17 owns port 5432, so the compose host port is now **5433** ·
`BUG-WEB-002` Next standalone bound to the container ID, fixed with `ENV HOSTNAME=0.0.0.0` ·
`BUG-BUILD-003` Testcontainers skipped all 6 schema tests against a running daemon, because
docker-java defaults to Engine API 1.32 and this daemon's `MinAPIVersion` is 1.40 — fixed with a
`docker.api.version` property in `backend/pom.xml`.

**Open for Sothea:** `disabledWithoutDocker = true` still turns a stopped daemon into a green build.
The fix made the tests run; it did not remove the trap. Decide between failing instead of skipping,
and a CI assertion on `Skipped: 0` in the surefire report.

## Session of 2026-08-15 — Docker blocker cleared, work left mid-flight

**Docker is now installed and running**: server `29.7.2`, `os=linux arch=aarch64`, Compose `v5.3.1`.
`.env` exists (gitignored): `POSTGRES_DB=lifelink`, `POSTGRES_USER=lifelink`, generated 32-char
password. Full procedure now written up in `docs/tech-lead/local-development.md`.

> `brew install --cask docker` **fails from an agent shell** — the cask links a binary via `sudo`,
> and a non-interactive shell cannot answer the prompt, so Homebrew rolls the install back. Run it in
> a real terminal or install the `.dmg` by hand.

**Stopped mid-build.** `bash scripts/dev-up.sh` was still pulling `maven:3.9-eclipse-temurin-21`
(~89/156 MB) when the session ended. **No container ever reached `up`.** Layers are cached, so just
re-run it.

### Uncommitted — nothing was committed. `main` is default, so branch first.
| File | Change |
|---|---|
| `ErrorResponse.java` + test | Contract envelope `{ error: { code, message } }`, `timestamp` dropped, new test pins the exact JSON. `./mvnw verify` passed |
| `frontend/Dockerfile` | `npm ci` → `npm install --no-audit --no-fund` (macOS lockfile omits Linux-only optional deps; CI already made this swap) |
| `scripts/dev-up.sh` | `flyway_schema_history` query expands `$POSTGRES_USER` **inside** the container — host-side it was always empty and silently printed the error branch |
| `docs/tech-lead/local-development.md` | **New.** First half of the deploy runbook |
| `README.md` | Node 20 → 22; removed the stale "directories are empty until M2" line |

## Resume here
1. `bash scripts/dev-up.sh` — must end with `✅ backend healthy` **and** a printed
   `flyway_schema_history` table. No table means it did not really succeed.
2. `cd backend && ./mvnw verify` — the gate is `SchemaIntegrationTest` reporting **`Skipped: 0`**.
   `BUILD SUCCESS` alone means nothing; it passes with Docker absent, which is exactly how
   `users.language` shipped broken.
3. QA (Oun Sreynich) records M2 evidence — `docs/qa/` still has **no milestone evidence file**.
4. Then M3 — Google Sign-In + donor register + FCM token registration. Backend specs are not written
   (`docs/fullstack/specs/features/` is empty).

## Decisions still open
1. ~~**Error-shape conflict**~~ — **closed 2026-08-15**, fix uncommitted. Openapi won per
   `docs/fullstack/CLAUDE.md`.
2. **ADRs owed** — next-intl, Riverpod, go_router (all now in the code).
3. **Max notified donor count** — unset, blocks `FR-MATCH-001`.
4. **Deploy runbook** — local half written (`docs/tech-lead/local-development.md`); the deploy half
   still blocks M7.
5. `npm audit`: 3 high findings transitive through `next` (postcss, sharp). Not force-fixed.
6. **`SEC-REVIEW-002`** against the M3 implementation — required, still unscheduled.
