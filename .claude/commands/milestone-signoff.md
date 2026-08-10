---
description: Run a milestone's checks and record the QA evidence row
argument-hint: "M2 | M3 | M4 | M5 | M6 | M7"
---

Milestone: $ARGUMENTS

1. Read root `CLAUDE.md` section 4 for that milestone's deliverable, and
   `docs/qa/test-strategy.md` for the layers its FRs require.
2. Run the checks that apply. Include `bash scripts/verify-all.sh`.
3. Append one row to the sign-off table at the end of `docs/qa/test-strategy.md`:
   milestone, date, evidence (the command run and its result), verdict.

Hard rules:
- MUST NOT write a pass verdict without command output to back it. No output means
  `not signed — <what is missing>`.
- A skipped test is not a pass. Say so in the evidence column.
- Manual checks (push receipt on a device, GPS acquisition) MUST be recorded as manual results that
  I confirmed — never inferred.
- MUST NOT edit any other section of the file, and MUST NOT touch code to make a check pass.
