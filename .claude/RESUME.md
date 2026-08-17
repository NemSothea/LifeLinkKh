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

## Current state — 2026-08-17, late session. **Read this section. Everything below it is history.**

`main` is clean and pushed. M2 is signed off. **M3 is half built: the backend exists, the client does not.**

Last five commits on `main`:
`3a9b1f4` PO finalized the two M3 FRs (phone dropped, district list written) ·
`c83d527` the two M3 build specs ·
`55003c6` M3 backend — Google Sign-In, session JWT, donor profile ·
`078f66c` the three M3 auth env vars into compose ·
`1ac5579` Flutter rebuilt to the course architecture (`lib/src/`, ADR 0006).

**What the M3 backend actually shipped** (`55003c6`): `POST /auth/google`, `POST /auth/fcm-token`,
`PUT /donors/me`, `GET /donors/me`, `V2__districts.sql`, `JwtService` (HS256, claims `sub`/`role`/`iat`/`exp`),
`SignInRateLimiter` (Bucket4j, per-IP), `EligibilityCalculator`, `FirebaseGoogleTokenVerifier`.
11 auth/donor unit tests plus the schema tests.

**The four gaps that still stand between here and M3 sign-off:**

1. **Mobile has no M3 code at all.** `pubspec.yaml` carries no `firebase_core`, `google_sign_in`,
   `firebase_messaging`, and no secure storage. Sign-in screen, donor profile form, router guard, FCM
   registration, and the auth interceptor ADR 0007 now specifies are all unwritten. Biggest chunk left.
2. **`SEC-REVIEW-002` is still unscheduled** against the implementation. R5 requires Security sign-off
   and the backend merged without it.
3. **QA gap, specific.** `TC-AUTH-001` lists six non-negotiable tests. `AuthServiceTest` has eleven
   tests but **#6 is absent** — nothing asserts that no log line carries the ID token, the JWT, or an
   email. #2 (a token whose `aud` is another Firebase project is rejected) is only covered indirectly,
   by `aTokenTheVerifierRejectsCreatesNoAccount`.
4. **The Firebase project does not exist.** Register the Android app, add the **debug SHA-1**
   (Google Sign-In fails *silently* without it), produce the service-account JSON. Sothea's, external
   lead time, and nothing in M3 verifies end-to-end until it lands. The backend answers
   503 `AUTH_PROVIDER_UNCONFIGURED` in the meantime, by design.
   **The plumbing for it is now in place** — `docs/tech-lead/local-development.md` Step 5 is the
   procedure, `secrets/` plus three filename patterns are gitignored, `docker-compose.firebase.yml`
   mounts the key read-only, and `dev-up.sh` adds that overlay by itself when `.env` names a key.
   Success signal: `POST /api/auth/google` with a junk token answers **401 instead of 503**.

**Closed this session:** ADR 0007 settles the JWT lifetime question the build spec left open —
one hour, expiry repaired by silent Firebase re-auth plus a one-shot retry, no refresh table, no
revocation list. It also names **`DELETE /auth/fcm-token`** as owed to Backend/DB before M3 sign-off:
`FcmTokenRequest.fcmToken` is `@NotBlank`, so a signed-out device currently cannot stop receiving pushes.

## History — where the project stood at 2026-08-10
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

## History — M2 sign-off, earlier on 2026-08-17

Branch `chore/role-rotation-2026-08-17`, three commits — **since merged into `main` as `430f83d`**:
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
1. `bash scripts/verify-all.sh` — fastest true picture. The gate inside it is
   `SchemaIntegrationTest` reporting **`Skipped: 0`**; `BUILD SUCCESS` alone means nothing, it passes
   with Docker absent, which is exactly how `users.language` shipped broken.
2. Pick one of the four gaps above. They are ordered by how much they unblock, not by size:
   the Firebase project (4) is the only one with external lead time, so starting it early costs
   nothing and starting it late stalls everything.
3. The mobile M3 build (gap 1) is buildable and unit-testable **now**, against a mocked auth
   surface — it does not have to wait for Firebase. Its contract is ADR 0007: secure storage, 401
   triggers re-auth, single-flight, one retry, `/auth/google` 401 lands on the sign-in route.
4. `DELETE /auth/fcm-token` (owed to Backend/DB per ADR 0007) is small and blocks sign-out being
   correct. Cheap to clear alongside the QA test gap.

## Decisions still open
1. ~~**Error-shape conflict**~~ — **closed 2026-08-15**. Openapi won per `docs/fullstack/CLAUDE.md`.
2. ~~**JWT lifetime and expiry behaviour**~~ — **closed 2026-08-17**, ADR 0007.
3. **ADRs owed** — next-intl only. Riverpod and go_router were discharged by ADR 0006.
4. **Max notified donor count** — unset, blocks `FR-MATCH-001` at M4.
5. **Deploy runbook** — local half written (`docs/tech-lead/local-development.md`); the deploy half
   still blocks M7.
6. `npm audit`: 3 high findings transitive through `next` (postcss, sharp). Not force-fixed.
7. **`SEC-REVIEW-002`** against the M3 implementation — required, still unscheduled.
8. **`disabledWithoutDocker = true`** still turns a stopped daemon into a green build. `BUG-BUILD-003`
   made the tests run; it did not remove the trap. Fail instead of skip, or a CI assertion on
   `Skipped: 0` in the surefire report — undecided.
