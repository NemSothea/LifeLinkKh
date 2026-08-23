# Product Changelog (forward signal)

Every new/changed FR gets an entry. What + Why are mandatory.

## 2026-08-23 — `FR-AUTH-004`'s Telegram backend built; Facebook's scope narrowed
- **What:** The half of `FR-AUTH-004` buildable without a real bot token is done: `TM-AUTH-002`
  (threat model), `V11__telegram_auth.sql`, `TelegramAuthService`/`Controller` (start/webhook/verify,
  OTP expiry + resend cooldown + rate-limiting), and `SEC-REVIEW-002` (pass-with-conditions, 19
  tests). Also corrected Facebook's scope: it needs no separate backend verifier — Firebase Auth
  handles it as a federated provider, so the existing Google ID-token verification already covers
  it once Facebook is enabled in the Firebase console. `FR-AUTH-004`'s acceptance criteria updated
  to match both.
  **Why:** Sothea asked "what's next" while waiting on the Meta Developer App review and the
  Telegram bot — both his own account-level actions, neither needing code. The Telegram OTP system
  was fully buildable behind `TelegramBotClient`'s seam without the real token (same reasoning
  `GoogleTokenVerifier` already demonstrated: fake the seam, build and test everything behind it).
  Building it now rather than waiting keeps the M7 sequencing plan from `changelog.md`'s earlier
  2026-08-23 entry on schedule instead of idle.

## 2026-08-23 — `FR-AUTH-004` (Facebook/Telegram sign-in) reversed from deferred to active
- **What:** `FR-AUTH-004` (Facebook and Telegram sign-in for donors) was written and deferred to
  post-M7 earlier today. Reversed same day: status moves `requested` → `accepted`, work starts now,
  not after M7.
  **Why:** Sothea (PO): most of Cambodia signs in with Facebook and Telegram day to day, more than
  Google in a lot of the target donor population — Google-only is a real sign-up barrier, not a
  theoretical one. The M7 timeline risk named at deferral time has not gone away (Meta App Review's
  timeline is still outside the team's control; Telegram is still a bot-OTP system to build, not a
  button), so scope is split: account-level setup (Meta Developer App + review submission, a
  Telegram bot via BotFather) starts immediately since it is Sothea's own action and touches no
  code; the actual client/backend integration is sequenced around M7 rather than raced against it.
  See `FR-AUTH-004` for the split and `ADR 0002`'s addendum for the auth-design reasoning.

## 2026-08-17 — the two M3 FRs finalized; phone dropped from the donor profile
- **What:** `FR-AUTH-003` and `FR-DONOR-001` had `<to be filled after prototyping>` in both Scope and
  Acceptance criteria. Both are now filled from their frozen prototypes, so M3 has something
  signable. `FR-DONOR-001`'s stale location blocker is struck — ADR 0003 answered it on 2026-08-07.
  **Phone number is removed** from `FR-DONOR-001`'s scope and from `prd.md` FR-02's required fields,
  and FR-02's "GPS or district" is tightened to "district required, GPS optional".
  **Why:** Definition of Done step 1 is a signed spec, and a placeholder cannot be signed — this was
  the actual thing blocking M3, not any code. Phone went unverified the moment ADR 0002 replaced
  phone OTP with Google Sign-In, and M3–M4 coordination runs over FCM push, so the app would never
  read the field. Collecting it would be inventing data.
  **Flagged:** dropping phone means nothing guarantees a donor is reachable by voice — the carried
  risk already named in `FR-AUTH-003`. If `FR-REQUEST-002`'s accept flow needs a callable number,
  phone comes back as a lazy step at acceptance only (ADR 0002, mitigation 2), as a **new FR**.
  Do not reopen `FR-DONOR-001` for it.

## 2026-08-17 — Phnom Penh district list written
- **What:** New [`reference/phnom-penh-districts.md`](reference/phnom-penh-districts.md) — 14 districts
  with Khmer labels and national geocodes, plus the seeding rules (own Flyway migration, Khmer as the
  primary label, sorted by name not code, no "other" option in the pilot).
  **Why:** `district_code` is the required half of a donor's location and the only location another
  user ever sees (ADR 0003), and the list behind that dropdown did not exist anywhere. The wireframe
  did not need it; the build cannot start without it.
  **Flagged:** the codes for the five districts renumbered after the 2019 reorganisation
  (`1210`–`1214`) are **unverified** and marked ⚠️ in the file. They must be checked against an
  official NCDD/MoI list before the seed migration is written. `district_code` lands in
  `donor_profiles` rows, so fixing it after donors exist is a data migration, not an edit.

## 2026-08-07 — scope cut to a buildable core (DEC-004)
- **What:** Eight FRs deferred (`FR-REQUEST-003/004/005`, `FR-MATCH-002`, `FR-NOTIFY-002`,
  `FR-PORTAL-002`, `FR-GLOBAL-002`, `FR-SECURITY-001`), each with a banner and a per-FR reason.
  `FR-PORTAL-001` trimmed to one open-requests page; GPS is `geolocator` only, no map widget.
  Milestone table rewritten — M3 and M4 get three weeks each. New [`../scope.md`](../scope.md) records
  what was cut and why. DEC-003 withdrawn with `FR-GLOBAL-002`.
  **Why:** 19 FRs across 7 milestones does not fit 13 part-time weeks. The cut was made against what
  the course grades — auth, push, GPS, relational DB, Play Store release — not against how interesting
  each feature is. Cutting evenly would have left every feature at 60% and no working core loop to
  demo. Deferred documents are kept deliberately: they are the defence's future-work section, and a
  documented cut answers "why isn't X here" better than a half-built X.
  **Flagged:** `FR-SECURITY-001` (account and data deletion) is a privacy obligation, not a feature.
  Deferring it is only defensible while the pilot uses team-created test accounts, and it must be
  built before any real donor uses the app.

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
- **What:** Reassigned three FR milestones per DEC-001/002/003 (`../decisions.md`):
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
