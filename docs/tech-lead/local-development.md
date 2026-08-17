# Local development — running the stack

**Owner: Tech Lead.** This is the first half of the deploy runbook M7 still needs. It covers getting
`postgres + backend + web` running on a developer machine, and nothing about deploying anywhere real.

> **Local development only.** Every port binds to `127.0.0.1` on purpose. The M2 backend has no
> authentication, and Docker's default `0.0.0.0` binding can bypass a host firewall and publish an
> unauthenticated API over donor phone numbers and blood types to the local network.

---

## Prerequisites

| Tool | Version | Why this version |
|---|---|---|
| Docker Desktop | Compose v2+ | `docker compose`, not `docker-compose` |
| JDK | **21** | Matches `backend/Dockerfile` and the Maven toolchain |
| Node | **22** | Node 20 trips `EBADENGINE` on deps requiring `>=22`. Both CI and `frontend/Dockerfile` pin 22 |
| Flutter SDK | 3.44+ | Mobile only — not a Compose service |

---

## Step 1 — Docker Desktop

```bash
brew install --cask docker
```

**Run that in a real terminal, not through an agent or a script.** The cask links
`docker-credential-osxkeychain` into `/usr/local/bin` via `sudo`, and a non-interactive shell cannot
answer the password prompt — Homebrew then rolls the whole install back:

```
sudo: a terminal is required to read the password
```

Then **launch Docker Desktop once from Applications** and wait for the whale icon to stop animating.
Installing the cask does not start the daemon, and Testcontainers needs the daemon, not the binary.

Manual `.dmg` install (drag `Docker.app` to `/Applications`) works equally well and avoids the `sudo`
problem entirely — Docker Desktop asks for privileges through its own GUI prompt on first launch.

Confirm:

```bash
docker info --format 'server={{.ServerVersion}} os={{.OSType}} arch={{.Architecture}}'
docker compose version
```

---

## Step 2 — `.env`

```bash
cp .env.example .env
```

Then fill it in. **`.env` is gitignored (`.gitignore:5`) and MUST NEVER be committed.**

These two values are a **shared team convention** — use them as-is so everyone's stack, scripts and
troubleshooting notes line up:

```
POSTGRES_DB=lifelink
POSTGRES_USER=lifelink
```

`POSTGRES_PASSWORD` is **per-developer**. Generate your own; never share it, never paste it into a
document, an issue, or a chat message. It is local-only, so it does not need to be memorable:

```bash
LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32
```

`SPRING_PROFILES_ACTIVE=local` stays as shipped.

Firebase (Auth + FCM) secrets are **not** needed before M3 and must not be added speculatively —
see `docs/security/security-checklist.md`.

### Why `POSTGRES_DB` and `POSTGRES_USER` are written down and the password is not

They are not credentials — they are the schema and role names that `docker-compose.yml`, the Flyway
migrations and the connection URL all have to agree on. Documenting them prevents a developer from
picking `lifelink_dev`, getting a stack that starts fine, and then losing an hour to a connection
error nobody else can reproduce. The password is the only secret in the file.

---

## Step 3 — Bring the stack up

```bash
bash scripts/dev-up.sh
```

The script starts `postgres` and `backend`, adds `web` once `frontend/` is scaffolded, waits for
health, then prints the applied Flyway migrations. **The first run is slow** — the backend image
compiles Maven from scratch and the frontend image runs a full `npm install` plus `next build`.

Success looks like `✅ backend healthy` followed by a `flyway_schema_history` table. That table is
the evidence QA signs the milestone against, so if it does not print, the run did not succeed —
regardless of what the health line says.

Ports, all on `127.0.0.1`: API `:8080` (context path `/api`), web `:3000`, postgres **`:5433`**.

Postgres is deliberately not on 5432. A host PostgreSQL install (`/Library/PostgreSQL/17` on this
Mac) already listens there, and Docker fails the whole `up` with `bind: address already in use`
rather than picking another port. The container still listens on 5432 internally and the backend
reaches it at `postgres:5432` over the compose network — only host clients use 5433:

```bash
psql -h 127.0.0.1 -p 5433 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

Tear down with `docker compose down`. Add `-v` only if you want the database wiped — that drops the
`lifelink_pgdata` volume and every row in it.

---

## Step 4 — The step that actually decides the milestone

```bash
cd backend && ./mvnw verify
```

`SchemaIntegrationTest` must report **`Skipped: 0`**.

Those six tests are the only thing that proves the Flyway migrations and the JPA entities agree, and
they run through Testcontainers — so **without a running Docker daemon they silently skip and the
build still says `BUILD SUCCESS`.** A green `verify-all.sh` on a machine with no Docker does not mean
the schema is right.

This is not hypothetical. It is exactly how `users.language` shipped broken: declared as
`columnDefinition = "char(2)"`, which Hibernate maps to `VARCHAR` while PostgreSQL reports `bpchar`,
so `ddl-auto=validate` refused to start the application. Local runs skipped the test and passed; CI
ran it and caught it. Fixed in `ab8b52d` with `@JdbcTypeCode(SqlTypes.CHAR)`.

Still seeing `Skipped: 6` means Testcontainers cannot reach the daemon — go back to Step 1.

---

## The Flutter app

Not a Compose service. It runs on a device or emulator and reaches the published host port:

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`--dart-define=API_BASE_URL` is **required** — the app fails fast with a clear error rather than
falling back to a default host. `10.0.2.2` is the Android emulator's alias for your machine.

---

## Troubleshooting

Each of these has actually happened on this project.

| Symptom | Cause | Fix |
|---|---|---|
| `sudo: a terminal is required to read the password` | Cask install ran without a TTY | Re-run `brew install --cask docker` in a real terminal, or install the `.dmg` by hand |
| `hdiutil: attach failed - Resource busy` | Two installs running at once, both mounting the same DMG | Wait for the first to finish. Run the install once |
| `Skipped: 6` in `SchemaIntegrationTest` | Docker daemon not running | Launch Docker Desktop, wait for the whale, re-run |
| Backend container exits right after start | Flyway ran before Postgres accepted connections | Already handled — `depends_on: condition: service_healthy`. If you edit Compose, keep it |
| `npm ci` fails in the frontend image | Lockfile generated on macOS arm64; npm omits Linux-only optional packages (`@emnapi/*`, `@swc/helpers`) that a Linux image then demands | Already handled — the Dockerfile and CI both use `npm install`. Revisit if npm fixes cross-platform optional resolution |
| `(could not query flyway_schema_history …)` | `${POSTGRES_USER}` expanded in the host shell, where Compose never exports it | Already handled — `dev-up.sh` expands it inside the container instead |

---

## Related

- [`docs/fullstack/specs/foundation/infra-docker.md`](../fullstack/specs/foundation/infra-docker.md) — Compose service spec
- [`docs/qa/test-strategy.md`](../qa/test-strategy.md) — what QA needs before signing a milestone
- [`docs/security/security-checklist.md`](../security/security-checklist.md) — secret handling
- `docker-compose.yml`, `scripts/dev-up.sh`, `scripts/verify-all.sh` — owned by Tech Lead
