# Product Changelog (forward signal)

Every new/changed FR gets an entry. What + Why are mandatory.

## 2026-08-07 — donor location precision and compatibility rule decided
- **What:** [ADR 0003](../tech-lead/adr/0003-donor-location-precision.md) accepted — `donor_profiles`
  gains `district_code NOT NULL` plus nullable `NUMERIC(8,5)` coordinates that **no API response ever
  returns**; displayed distance is rounded to 0.5 km and location is shown as a district name.
  [ADR 0004](../tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md) accepted — a seeded 27-row
  `blood_compatibility` table. `FR-MATCH-001` drops from two blockers to one (max notified count).
  Schema updated in `../fullstack/specs/foundation/backend-spring.md`; ERD in
  `../tech-lead/data-model.md`.
  **Why:** the exact-coordinates-versus-district-centroid framing was a false choice — centroids make
  the PRD's "nearby" promise decorative, exact exposed coordinates publish a home location next to a
  blood type. Storing both at different precisions and never returning the precise one keeps ranking
  accurate while bounding exposure to one of 14 districts. Coordinates stay nullable so that declining
  the GPS permission does not exclude a willing donor — otherwise consent is coerced.
  **Sign-off caveat:** decided by Nem Sothea as Tech Lead while also holding PO and Security. Moeun
  Nithvaraman is primary PO and did not sign it. After `V1__init.sql` merges, reversing this costs a
  second migration.

## 2026-08-07 — auth acceptance criteria hardened by security review
- **What:** `SEC-REVIEW-001` (`../security/reviews/SEC-REVIEW-001-google-sign-in.md`) returned
  **pass-with-conditions** on the Google Sign-In change. Added three control criteria to
  `FR-AUTH-003` and one to `prd.md` FR-01: identity only from the verified token's `sub`; verify
  signature + `aud` + `iss` + expiry; self-service sign-up limited to `DONOR`/`REQUESTER`. QA case
  `TC-AUTH-001` written to verify all of them.
  **Why:** `prd.md` §2.1 already said hospital and admin accounts are admin-provisioned, but no FR
  asserted the server enforces it — a donor could have self-promoted to `ADMIN` on first sign-in and
  gained requester contact details. A rule stated only in prose is not a control. These are stated
  ahead of prototyping because they are security behaviour, not UX, and do not depend on a wireframe.

## 2026-08-07 — auth mechanism changed to Google Sign-In
- **What:** `prd.md` FR-01 changed from "Phone Authentication (OTP)" to "Authentication (Google
  Sign-In)". New [`FR-AUTH-003-google-sign-in`](features/FR-AUTH-003-google-sign-in.md) (`accepted`,
  Must Have, M3) supersedes `FR-AUTH-001-phone-otp-auth`; `FR-AUTH-002-otp-resend-cooldown` is
  `retired` — never approved, never built. Both old FRs kept as history with banners so existing
  cross-references still resolve. Also amended: `prd.md` §2.1 scope, §5 security row, §7 onboarding
  and error flows, §8 assumptions/dependencies/risks, §9 glossary; `features/index.md`;
  `../tech-lead/architecture.md`; ADR 0001's auth clause; `../security/security-checklist.md`;
  `prototypes/roadmap.md` (`AUTH-otp-signin` → `AUTH-google-signin`); root `CLAUDE.md` M3 row.
  Decision recorded in [ADR 0002](../tech-lead/adr/0002-auth-google-sign-in.md).
  **Why:** SMS costs money per message, on the one code path every user must cross before the app does
  anything, and the cheap local providers want a registered business the team does not have. Google
  Sign-In is free *and* less code — no code generation, expiry window, send rate-limiting,
  brute-force defence, or resend cooldown to write and get right. The Firebase SDK is already a
  dependency for FCM at M3.
  **Carried risk:** donor phone numbers are no longer verified, and the core loop assumes an accepted
  request can reach a human. Mitigation is to coordinate through FCM push in-app rather than by phone
  call — that lands in `FR-REQUEST-002` and `FR-NOTIFY-001`, and is recorded there and in the new
  FR's "carried risk" section. FR-AUTH-003 must not be closed while `FR-REQUEST-002` still assumes a
  verified phone.

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
