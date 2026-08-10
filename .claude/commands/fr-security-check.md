---
description: Check one FR's code against the ASVS baseline and the non-negotiable security tests
argument-hint: "FR-DONOR-001"
---

FR: $ARGUMENTS

1. Read `docs/security/asvs-baseline.md` (ASVS Level 1, ADR 0005) and the
   "Non-negotiable security tests" section of `docs/qa/test-strategy.md`.
2. Read that FR's document in `docs/po/features/` and find its implementation in `backend/`,
   `frontend/` or `mobile/`.
3. Check it against every baseline control row that names this FR, plus these four regardless:
   - no response body contains donor `latitude`, `longitude`, or an unrounded distance (ADR 0003)
   - self-service sign-up cannot produce `HOSPITAL` or `ADMIN` — rejected, never downgraded
   - a `firebase_uid` in a request body is ignored; identity comes only from the verified token
   - donor contact details are absent until that donor has accepted

Output one table: `| Control | Pass / Fail / Not yet built | Evidence (file:line) |`.

Hard rules:
- Every verdict MUST cite `file:line`. No citation means `unknown`, not pass.
- MUST NOT fix anything. Report only.
- MUST NOT invent an ASVS requirement ID.
