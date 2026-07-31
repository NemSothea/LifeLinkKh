# Product Changelog (forward signal)

Every new/changed FR gets an entry. What + Why are mandatory.

## 2026-07-31 — feature registry populated
- **What:** Created 19 thin FRs in `features/` and rebuilt `features/index.md` with per-area number
  counters and the full registry. Twelve are `prd.md` FR-01..FR-12 transcribed to R7 IDs with
  `status: accepted`; seven are new, `status: requested`, each closing a gap citable in `prd.md`:
  account and data deletion (§6), success-metric event capture (§1 + FR-11), OTP resend cooldown (§7),
  duplicate-request warning (§7), donor withdrawal (§7), request expiry (FR-04's dead `expired`
  status), and no-donors-found handling (§7). Scope and acceptance criteria are deliberately unfilled
  — the twelve link to their `prd.md` section instead of restating criteria.
  **Why:** The registry was empty at `next: 001`, so no feature had an R7 ID and nothing could be
  planned, tested, or signed off against an identifier. Writing them thin follows the PO flow in
  `CLAUDE.md` (brief → prototype → finalize) and keeps acceptance criteria in one place rather than
  forking them between `prd.md` and 19 files. The seven additions are prose promises the PRD made and
  never turned into requirements — an unimplemented promise is worse than no promise, because users
  act on it. Mapping also surfaced two scheduling conflicts and one FR overlap, recorded in
  `features/index.md`.
- **What:** Reassigned three FR milestones per DEC-001/002/003 (`../pm/decisions.md`):
  `FR-DONOR-002` eligibility computation to M4, `FR-NOTIFY-001` request push to M4 with token
  registration at M3, `FR-GLOBAL-002` capture to M3–M5 with the dashboard at M6. Root `CLAUDE.md`
  section 4 amended to match.
  **Why:** As scheduled, M4 could not satisfy its own acceptance criteria — matching required an
  eligibility check that arrived a milestone later, and `prd.md` FR-04 required a notification that
  arrived a milestone later still. Leaving it would have forced QA to waive criteria to hit a date,
  and QA sign-off is the only independent gate this project has.

## 2026-07-31
- **What:** Added `briefs/` and renamed `prototype/` → `prototypes/`, each with a README and
  a scoped roadmap. Updated the PO write-scope in `CLAUDE.md` to match.
  **Why:** The PO flow (brief → prototype → FR) had no home for the brief step, and no
  schedule saying which briefs and screens are due by which milestone. The roadmaps link to
  root `CLAUDE.md` section 4 rather than copying the M1–M7 table, so dates have one owner.

## 2026-07-24
- **What:** Framework initialized; PRD authored (docs/po/prd.md).
  **Why:** Establish the product scope and multi-role workspace before building.
