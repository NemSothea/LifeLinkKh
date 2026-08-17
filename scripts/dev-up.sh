#!/usr/bin/env bash
# Bring up the local stack and report the truth about what came up.
# Local development only — the M2 backend has no authentication.
# Owner: Tech Lead. First half of the deploy runbook the M7 release still needs.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null 2>&1; then
    echo "❌ docker is not installed. Install Docker Desktop, then re-run."
    echo "   Until then: M2 acceptance cannot be signed off, and the backend"
    echo "   integration tests skip instead of running."
    exit 1
fi

if [ ! -f .env ]; then
    echo "❌ .env missing. Copy .env.example to .env and fill it in."
    echo "   .env is gitignored and MUST NEVER be committed."
    exit 1
fi

# Firebase service-account key: mounted only when .env names one. Grepped out of
# .env rather than read from the environment, because docker compose reads .env
# for its own substitution but never exports those names into this shell.
compose_files=(-f docker-compose.yml)
cred_path=$(sed -n 's/^[[:space:]]*GOOGLE_APPLICATION_CREDENTIALS[[:space:]]*=[[:space:]]*//p' .env | tail -n1)
if [ -n "$cred_path" ]; then
    if [ ! -f "$cred_path" ]; then
        echo "❌ GOOGLE_APPLICATION_CREDENTIALS is set in .env but no file is there:"
        echo "   $cred_path"
        echo "   Use an absolute path. Bind-mounting a missing file makes Docker create"
        echo "   a directory at that path, and the backend then reads a directory as JSON."
        exit 1
    fi
    compose_files+=(-f docker-compose.firebase.yml)
    echo "🔑 Firebase service account will be mounted read-only"
else
    echo "⏭  no GOOGLE_APPLICATION_CREDENTIALS in .env — POST /auth/google will answer"
    echo "   503 AUTH_PROVIDER_UNCONFIGURED. Everything else serves normally."
fi

# frontend/ is scaffolded at M2 step 3. Until then `web` has nothing to build.
services=(postgres backend)
if [ -f frontend/package.json ] && [ -f frontend/Dockerfile ]; then
    services+=(web)
else
    echo "⏭  web skipped — frontend/ is not scaffolded yet"
fi

echo "Starting: ${services[*]}"
docker compose "${compose_files[@]}" up -d --build "${services[@]}"

echo "Waiting for health…"
for _ in $(seq 1 40); do
    unhealthy=$(docker compose ps --format '{{.Service}} {{.Health}}' \
        | awk '$2 != "healthy" && $2 != "" {print $1}' || true)
    [ -z "$unhealthy" ] && break
    sleep 3
done

docker compose ps

echo
if curl -fsS http://127.0.0.1:8080/api/health >/dev/null 2>&1; then
    echo "✅ backend healthy — http://127.0.0.1:8080/api/health"
else
    echo "❌ backend did not answer /api/health. Logs:"
    docker compose logs --tail=40 backend
    exit 1
fi

echo "   Flyway applied:"
# Expanded inside the container, not here. docker compose reads .env for its own
# substitution but never exports those names back to this shell, so a host-side
# ${POSTGRES_USER} is always empty — it would silently connect as the fallback role
# and print the error branch instead of the migration table QA signs off against.
# The postgres container already has both names in its environment.
docker compose exec -T postgres sh -c \
    'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
     -c "SELECT version, description, success FROM flyway_schema_history;"' \
    || echo "   (could not query flyway_schema_history — is the postgres service up?)"
