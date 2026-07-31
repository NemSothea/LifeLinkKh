# Briefs

Pre-FR thinking. A brief is where a problem gets understood **before** it becomes a
numbered feature in [`../features/`](../features/index.md).

## What a brief is

A brief answers three questions and nothing else:

1. **Problem** — what user pain exists today.
2. **Why now** — why this matters this milestone and not later.
3. **Open questions** — what we don't know yet.

A brief does **not** contain scope, acceptance criteria, API shapes, screen layouts, or
estimates. Those belong in the FR (`../features/`) after the brief is settled.

## Where a brief sits in the PO flow

Per `../CLAUDE.md`:

```
brief (Problem / Why)  →  prototype (../prototypes/)  →  finalize FR (Scope + acceptance criteria)
```

- A brief may be discarded. That is a success — it means we learned the feature wasn't needed.
- A brief that survives gets a prototype, then an FR. The FR's `brief_ref:` frontmatter
  points back here.
- One brief can spawn more than one FR (e.g. a matching brief splitting into
  `FR-MATCH-…` and `FR-NOTIFY-…`).

## Naming

`BRIEF-<AREA>-<###>-<slug>.md`

Areas match R7 (`docs/cheat-sheet.md`):
`AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL GLOBAL SECURITY MOBILE`

Numbering is per-area and independent from FR numbers. Next number lives in
[`roadmap.md`](roadmap.md) — bump it when you claim one.

## File shape

```markdown
---
id: BRIEF-<AREA>-<###>-<slug>
title: <short title>
area: <AREA>
milestone: M<n>
status: open   # open | prototyping | promoted | dropped
owner: PO
fr_ref: <FR id once promoted, or blank>
---

## Problem
<user pain today, with evidence if we have it>

## Why now
<what breaks or is lost if we defer this>

## Open questions
- [ ] <question blocking scope>
```

## Rules

- PO writes here. Nobody else. (Write-scope rule, `../CLAUDE.md`.)
- Every brief that gets promoted to an FR needs a `../changelog.md` entry (What + Why).
- A brief never references a file under `backend/`, `frontend/`, `mobile/`, or
  `docs/fullstack/`. If you need to, the brief is really a spec — hand it to Fullstack.
- Status `dropped` briefs stay in the repo. Deleting them loses the reasoning.

## Related

- [`../prd.md`](../prd.md) — FR-01..FR-12 already scoped; briefs are for what comes *after* those.
- [`../features/index.md`](../features/index.md) — FR registry.
- [`../prototypes/`](../prototypes/) — next step for a surviving brief.
- Root `CLAUDE.md` section 4 — M1..M7 milestone table (single source of truth for dates).
