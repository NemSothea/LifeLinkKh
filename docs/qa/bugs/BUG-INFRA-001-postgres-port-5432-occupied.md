---
id: BUG-INFRA-001
title: docker compose up aborts — host PostgreSQL owns port 5432
area: INFRA
severity: blocker
status: closed
found_in: M2 verification, commit 38eff57 (fixed in d1f5efd)
reported_by: QA
---
## Steps to reproduce
1. Have any host PostgreSQL installed and running (here: `/Library/PostgreSQL/17`, listening `*:5432`).
2. `bash scripts/dev-up.sh`

## Expected
Three containers reach `healthy`.

## Actual
No container starts. Compose aborts the whole `up` on the first one:

```
Error response from daemon: ports are not available: exposing port TCP 127.0.0.1:5432 -> 127.0.0.1:0: listen tcp4 127.0.0.1:5432: bind: address already in use
```

Note it does **not** fall back to another port — the entire stack fails, including `backend` and
`web`, which have nothing to do with the conflict.

## Notes
Diagnosing this is slower than it looks: `lsof -nP -iTCP:5432 -sTCP:LISTEN` prints nothing, because
the listener runs as the `postgres` user and lsof only shows the caller's own processes without
`sudo`. `netstat -an -p tcp | grep 5432` does show it.

Fixed by moving the host side of the mapping to `5433` (`docker-compose.yml`). Nothing in the stack
used the host port — the backend reaches the DB at `postgres:5432` over the compose network. Only
host `psql`/GUI clients change: `psql -h 127.0.0.1 -p 5433`.

Rejected alternative: stopping the host PostgreSQL 17. It would keep the repo unchanged, but breaks
whatever else on that machine depends on it, and each developer would have to do it again.
