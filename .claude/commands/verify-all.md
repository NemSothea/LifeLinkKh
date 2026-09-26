---
description: Run every client's checks and report pass/fail per client
---

Run `bash scripts/verify-all.sh`.

Then report, in this shape and nothing more:

```
firebase  ✅ | ❌   (rules tests · functions unit · functions emulator)
web       ✅ | ❌ | ⏭ not scaffolded   (lint · types · vitest)
mobile    ✅ | ❌ | ⏭ not scaffolded   (flutter analyze · flutter test)
```

Rules:
- Quote only the shortest decisive failing line for anything that failed. Never paste a full log.
- A SKIPPED test is NOT a pass. If any test skipped, say how many and why.
- The rules and Functions emulator tests start the Firebase emulator, which needs Java 21. A
  Java version error is an environment failure — report it as that, not as a test failure.
- Do not fix anything. Report only.
