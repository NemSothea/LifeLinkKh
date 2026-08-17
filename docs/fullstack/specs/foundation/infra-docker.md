---
id: SPEC-FOUNDATION-INFRA-DOCKER
owner: Tech Lead
status: draft
milestone: M2
---

# Foundation Spec — Docker Compose (local development)

Scope of this spec: the `docker-compose.yml` that makes `docker compose up` run the database,
backend, and web portal together at M2. Milestone dates are in root `CLAUDE.md` section 4 — not
repeated here.

**Local development only.** This compose file is not a deployment artifact. The M2 backend has no
authentication (`backend-spring.md`), so exposing it beyond localhost would publish an open API over
donor phone numbers and blood types.

## Ownership

`docker-compose.yml` at the repo root is owned by **Tech Lead**.

> **Resolved 2026-08-07.** The DevOps role was dropped and Tech Lead absorbed everything it held
> (`docs/team.md`), so the old two-roles-claim-one-file contradiction is gone. This spec stays in
> `docs/fullstack/` because Fullstack builds against it, but the file itself is Tech Lead's.

CI (`.github/workflows/`), the deploy runbook and the release are also **Tech Lead**. `infra/` was
removed and no runbook exists — one must be written before M7.

## Services

Three services. No others at M2 — no cache, no reverse proxy, no mail catcher, no admin UI.

### `postgres`

| Setting | Value |
|---|---|
| Image | `postgres:16-alpine` — pin the minor at init |
| Published port | `5433:5432`, bound to `127.0.0.1` only — host side is 5433 because a host PostgreSQL install already owns 5432 and Docker fails the whole `up` rather than picking another port. Inside the network the DB is still `postgres:5432`. |
| Volume | named volume `lifelink_pgdata` → `/var/lib/postgresql/data` |
| Healthcheck | `pg_isready -U $POSTGRES_USER -d $POSTGRES_DB`, 5 s interval, 10 retries |
| Env vars (names only) | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` |

A **named volume, not a bind mount** — bind-mounting Postgres data into the repo risks committing
the data directory and breaks on macOS file permissions.

`pgcrypto` is required for `gen_random_uuid()` (see `backend-spring.md`). Enable it in
`V1__init.sql` via `CREATE EXTENSION IF NOT EXISTS pgcrypto;`, not by patching the image.

### `backend`

| Setting | Value |
|---|---|
| Build | `./backend`, multi-stage Dockerfile (Maven build stage → JRE 21 runtime stage) |
| Published port | `8080:8080`, bound to `127.0.0.1` only |
| Depends on | `postgres`, condition `service_healthy` |
| Healthcheck | HTTP GET on `/api/health`, 10 s interval, 12 retries, 30 s start period |
| Env vars (names only) | `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `SPRING_PROFILES_ACTIVE` |

`depends_on: service_healthy` is not optional. Without it the backend starts before Postgres accepts
connections, Flyway fails, and the container exits — the single most common first-run failure.

The datasource host is the **service name** `postgres`, not `localhost`. Compose provides DNS between
services; `localhost` inside the backend container is the backend itself.

Multi-stage build keeps the Maven toolchain out of the runtime image. A single-stage build produces an
image several hundred MB larger for no benefit.

### `web`

| Setting | Value |
|---|---|
| Build | `./frontend`, multi-stage Dockerfile (`npm ci` + build → runtime) |
| Published port | `3000:3000`, bound to `127.0.0.1` only |
| Depends on | `backend`, condition `service_healthy` |
| Healthcheck | HTTP GET on `/`, 10 s interval, 12 retries |
| Env vars (names only) | `API_BASE_URL` |

Inside Compose, `API_BASE_URL` points at `http://backend:8080/api`. The Flutter app is **not** a
Compose service — it runs on a device or emulator and reaches the published host port instead, via
`http://10.0.2.2:8080/api` on the Android emulator (see `mobile-flutter.md`).

## Startup order

```
postgres (healthy)  →  backend (healthy)  →  web
```

Each arrow is a `service_healthy` condition, not a bare `depends_on`. Bare `depends_on` waits only
for the container to start, which is not the same as the service being usable.

## Environment variables

All values live in a root `.env` file that is **gitignored and never committed**. The repo commits a
`.env.example` listing variable names with empty or obviously-fake values.

`docker-compose.yml` references variables by interpolation (`${POSTGRES_PASSWORD}`) and contains no
literal credential, password, or connection string. Per `docs/security/security-checklist.md`,
secrets are referenced by name only. The R5 secret set for this project — Firebase (Auth + FCM) and
Maps keys — is **not needed at M2** and must not be added to the compose file speculatively.

Every port binds to `127.0.0.1`. Docker's default `0.0.0.0` binding can bypass a host firewall and
publish an unauthenticated M2 backend to the local network.

## Deferred to later milestones

| Deferred | Owner |
|---|---|
| CI pipeline (`.github/workflows/`) | Tech Lead |
| Staging and production environments, image registry, deploy automation | Tech Lead |
| Firebase / Maps secret injection | Fullstack + Security, at the milestone that needs them |
| Nightly Postgres backup (`prd.md` §5 availability target) | Tech Lead |
| Observability, log aggregation, metrics | not scoped for this course project |

## Done when

- [ ] `docker-compose.yml` exists at the repo root defining exactly `postgres`, `backend`, and `web`.
- [ ] `.env.example` lists every variable named in this spec; `.env` is in `.gitignore`.
- [ ] `docker compose up` from a clean state (`docker compose down -v`) brings all three services to
      healthy with no manual step.
- [ ] `docker compose ps` shows all three as `healthy`.
- [ ] `curl http://127.0.0.1:8080/api/health` returns 200.
- [ ] `http://127.0.0.1:3000` renders the portal showing the live health result.
- [ ] `docker compose down` then `up` preserves database rows — the named volume works.
- [ ] `docker compose down -v` then `up` re-applies `V1__init.sql` cleanly from scratch.
- [ ] `grep` finds no password, key, or connection-string literal in `docker-compose.yml`.
- [ ] `docker compose port backend 8080` shows a `127.0.0.1` binding, not `0.0.0.0`.

## Follow-ups this spec does not resolve

- **A deploy runbook must be written.** `infra/` was deleted with the DevOps role; the M7 release
  has no documented promotion path. Tech Lead owns it.
- Postgres and image minor versions must be pinned and recorded here at init. **Still open as of
  2026-08-10:** `docker-compose.yml` uses `postgres:16-alpine` and the Dockerfile uses
  `maven:3.9-eclipse-temurin-21` / `eclipse-temurin:21-jre`. Docker is not installed on the build
  machine, so no tag has been pulled and no minor could be verified — pinning a minor that turns out
  not to exist fails the first run. Pin all three on the first successful `docker compose up` and
  record them here.
- `GET /api/health` must exist in both API contracts — the backend and web healthchecks both depend
  on it.
