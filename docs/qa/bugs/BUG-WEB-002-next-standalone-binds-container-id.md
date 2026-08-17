---
id: BUG-WEB-002
title: web container never becomes healthy — Next standalone binds to the container ID
area: WEB
severity: high
status: closed
found_in: M2 verification, commit 38eff57 (fixed in d1f5efd)
reported_by: QA
---
## Steps to reproduce
1. `bash scripts/dev-up.sh`
2. `docker compose ps`

## Expected
`web` reaches `healthy`, like `postgres` and `backend`.

## Actual
`web  Up 2 minutes (unhealthy)`, failing streak 12 and climbing. Every probe:

```
curl: (7) Failed to connect to 127.0.0.1:3000 after 0 ms: Could not connect to server
```

The container log looks perfectly fine, which is what makes this one deceptive:

```
   ▲ Next.js 15.5.23
   - Local:        http://4080bc7301b3:3000
 ✓ Ready in 63ms
```

## Notes
`4080bc7301b3` is the container ID, not a hostname anyone chose. Docker sets `HOSTNAME` to the
container ID by default, and the standalone server reads exactly that:

```js
// .next/standalone/server.js:9
const hostname = process.env.HOSTNAME || '0.0.0.0'
```

So Next binds only to the address that name resolves to — the container's eth0 IP. `127.0.0.1`
inside the container is not listening, which is precisely what the compose healthcheck curls.

`curl http://127.0.0.1:3000/` **from the host** returns `307` throughout, so browsing the app hides
the fault entirely. Only the healthcheck sees it. Left alone this would have surfaced later as
`depends_on: condition: service_healthy` refusing to start anything behind `web`.

Fixed with `ENV HOSTNAME=0.0.0.0` in `frontend/Dockerfile`.
