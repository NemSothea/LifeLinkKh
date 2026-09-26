---
description: Check one FR's code against the ASVS baseline and the non-negotiable security tests
argument-hint: "FR-DONOR-001"
---

FR: $ARGUMENTS

1. Read `docs/security/asvs-baseline.md` (ASVS Level 1, ADR 0005) and the
   "Non-negotiable security tests" section of `docs/qa/test-strategy.md`.
2. Read that FR's document in `docs/po/features/` and find its implementation in `firebase/`
   (`firestore.rules`, `functions/src/`), `frontend/` or `mobile/`.
3. Check it against every baseline control row that names this FR, plus these four regardless:
   - no document or response a donor-facing client can read carries another donor's `lat`, `lng`,
     `geohash` or an unrounded distance (ADR 0003)
   - a client cannot give itself `ADMIN` (or any role) — roles are custom claims set only by the
     admin seed, plus an `admins/{uid}` record no client can write
   - identity comes only from `request.auth.uid`; a document written for another uid is refused
   - the requester's contact (`requests/{id}/private/contact`) is readable only by the creator and
     a donor who accepted

Output one table: `| Control | Pass / Fail / Not yet built | Evidence (file:line) |`.

Hard rules:
- Every verdict MUST cite `file:line`. No citation means `unknown`, not pass.
- MUST NOT fix anything. Report only.
- MUST NOT invent an ASVS requirement ID.
