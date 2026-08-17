---
id: BUG-BUILD-003
title: SchemaIntegrationTest skips with Docker running — build passes testing nothing
area: BUILD
severity: blocker
status: closed
found_in: M2 verification, commit 38eff57 (fixed in d1f5efd)
reported_by: QA
---
## Steps to reproduce
1. Docker Engine 29.7.2 running; `docker ps` works.
2. `cd backend && ./mvnw verify`

## Expected
`SchemaIntegrationTest` runs its 6 tests: `Skipped: 0`.

## Actual
```
Tests run: 6, Failures: 0, Errors: 0, Skipped: 6 -- in kh.lifelink.api.schema.SchemaIntegrationTest
Tests run: 11, Failures: 0, Errors: 0, Skipped: 6
BUILD SUCCESS
```

Testcontainers, mid-run:

```
o.t.d.DockerClientProviderStrategy : Could not find a valid Docker environment. Please check configuration.
	UnixSocketClientProviderStrategy: failed with exception BadRequestException (Status 400: {"ID":"","Containers":0,...})
	DockerDesktopClientProviderStrategy: failed with exception BadRequestException (Status 400: ...)
```

## Notes
This is the highest-severity finding of M2 even though nothing is visibly broken. **`BUILD SUCCESS`
was printed while the schema was never asserted** — the identical blind spot that let the broken
`users.language` column reach `main` (fixed in `ab8b52d`). `@Testcontainers(disabledWithoutDocker =
true)` turns a missing runtime into a skip, and a skip into a green build.

The socket is fine; the API version is not. Probed directly:

```
$ curl -s --unix-socket ~/.docker/run/docker.sock http://localhost/version
ApiVersion 1.55   MinAPIVersion 1.40

$ curl -s --unix-socket ~/.docker/run/docker.sock http://localhost/v1.32/info
{"ID":"","Containers":0,...}          # hollow stub, HTTP 400

$ curl -s --unix-socket ~/.docker/run/docker.sock http://localhost/v1.44/info
{"ID":"e804fdda-...","Containers":3,...}   # real
```

docker-java 3.4.2 (shaded inside Testcontainers 1.21.3) defaults to Engine API **1.32**, below this
daemon's `MinAPIVersion 1.40`. The daemon answers 400, and Testcontainers reads any failed ping as
"no Docker here".

`DOCKER_API_VERSION=1.44` in the environment does **not** help — that variable is read by the Docker
CLI, not by docker-java. docker-java reads the `api.version` *system property*, and it has to reach
the forked Surefire JVM. Fixed in `backend/pom.xml`: a `docker.api.version` property (default
`1.44`, i.e. Docker 25.0+) passed through `maven-surefire-plugin`'s `systemPropertyVariables`.
Override with `-Ddocker.api.version=1.43` on an older engine.

**Open, for Tech Lead — not blocking M2.** The fix makes the tests run here; it does not remove the
trap. `disabledWithoutDocker = true` still means a developer with Docker stopped, or a future
Engine that moves `MinAPIVersion` past 1.44, gets a green build proving nothing. Two candidates:
fail the build instead of skipping when the tests are required, or add a CI step that asserts
`Skipped: 0` in the surefire report. Neither is QA's to choose.
