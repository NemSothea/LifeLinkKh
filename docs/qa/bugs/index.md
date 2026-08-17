# Bug Registry
next: 004

| ID | Title | Area | Severity | Status |
|----|-------|------|----------|--------|
| [BUG-INFRA-001](BUG-INFRA-001-postgres-port-5432-occupied.md) | `docker compose up` aborts — host PostgreSQL owns port 5432 | INFRA | blocker | closed |
| [BUG-WEB-002](BUG-WEB-002-next-standalone-binds-container-id.md) | web container never becomes healthy — Next standalone binds to the container ID | WEB | high | closed |
| [BUG-BUILD-003](BUG-BUILD-003-testcontainers-skips-with-docker-running.md) | `SchemaIntegrationTest` skips with Docker running — build passes testing nothing | BUILD | blocker | closed |

All three were found during M2 verification on 2026-08-17 and closed in `d1f5efd`.
`BUG-BUILD-003` carries a follow-up for Tech Lead that is deliberately not tracked as a bug.
