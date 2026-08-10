---
description: Run every client's checks and report pass/fail per client
---

Run `bash scripts/verify-all.sh`.

Then report, in this shape and nothing more:

```
backend  ✅ | ❌ | ⏭ not scaffolded
web      ✅ | ❌ | ⏭ not scaffolded
mobile   ✅ | ❌ | ⏭ not scaffolded
```

Rules:
- Quote only the shortest decisive failing line for anything that failed. Never paste a full log.
- A SKIPPED test is NOT a pass. If any test skipped, say how many and why (Docker absent skips the
  backend integration tests).
- Do not fix anything. Report only.
