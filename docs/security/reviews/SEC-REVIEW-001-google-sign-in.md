---
id: SEC-REVIEW-001
feature: FR-AUTH-003-google-sign-in
date: 2026-08-07
verdict: pass-with-conditions
reviewer: Security (Tech Lead overlay)
threat_model: ../threat-models/TM-AUTH-001-google-sign-in.md
---

## Scope reviewed

The R5 auth change dated 2026-08-07: phone OTP replaced by Google Sign-In. This is a **specification
review only** — no authentication code exists yet (`backend/` is empty; auth lands at M3). Reviewed
artefacts:

- `docs/tech-lead/adr/0002-auth-google-sign-in.md`
- `docs/po/features/FR-AUTH-003-google-sign-in.md`
- `docs/po/prd.md` FR-01, §2.1, §5, §7, §8
- `docs/security/security-checklist.md` (auth section)
- `docs/fullstack/specs/foundation/backend-spring.md` (`users` table, M2 security posture)

## Findings

**F1 — `users` schema still models phone as the credential. Blocking for M3.**
`backend-spring.md` defines `users.phone VARCHAR(20) NOT NULL UNIQUE` and has no column for the
Google subject identifier. Under Google Sign-In there is nothing to key an account on, and `NOT NULL`
on a field the user is no longer required to prove — or supply — cannot be satisfied at sign-up.
Required: add `firebase_uid VARCHAR(128) NOT NULL UNIQUE`, make `phone` nullable (retaining `UNIQUE`,
which permits multiple NULLs in PostgreSQL). Owner: Fullstack. Must land in `V1__init.sql` before it
merges — a merged migration is never edited (`backend-spring.md`).

**F2 — E1 (client-chosen role) is a product rule with no enforcement recorded anywhere.**
`prd.md` §2.1 states hospital and admin accounts are admin-provisioned, but neither FR-AUTH-003 nor
FR-DONOR-001 has an acceptance criterion asserting the server rejects a self-selected privileged role.
An unenforced rule in prose is not a control. Required: an explicit criterion on FR-AUTH-003 and a QA
test case attempting sign-up as `ADMIN`.

**F3 — S1/S2 are correctly named in FR-AUTH-003 and the PRD criteria.**
FR-01's amended acceptance criteria require server-side verification of signature, audience, issuer
and expiry, and explicitly reject client-supplied identifiers. This is the right shape and needs no
change. Verification must use the Firebase Admin SDK, not a hand-rolled parse — recorded as a
mitigation for T1 in the threat model.

**F4 — `users.fcm_token` comment is stale.** It reads "populated at M5"; DEC-002 moved token
registration to M3. Cosmetic, but it is the kind of drift that puts a column on the wrong milestone's
checklist. Owner: Fullstack.

**F5 — Residual: unverified phone number is a product risk carried into M4.**
Accepted, documented in three places, with FCM-in-app coordination as the mitigation. Not a reason to
fail this review, but `FR-AUTH-003` must not be closed while `FR-REQUEST-002`'s accept flow still
assumes a callable number.

**F6 — M2's permissive `SecurityConfig` remains acceptable.** All-requests-permitted with no auth is
sound for a local-only compose stack (`infra-docker.md` binds to `127.0.0.1`), and M3 replaces the
class wholesale. It must never reach a deployed environment — unchanged from the existing spec.

## Verdict & conditions

**pass-with-conditions.** The design is sound and materially reduces attack surface versus phone OTP:
code generation, expiry windows, brute-force defence and resend abuse all leave our codebase.

Conditions, all before M3 auth code merges:

1. **F1** — `users` gains `firebase_uid NOT NULL UNIQUE`; `phone` becomes nullable. Blocking.
2. **F2** — FR-AUTH-003 gains a role-allow-list acceptance criterion; QA writes the privilege-escalation test case. Blocking.
3. **F4** — `fcm_token` milestone comment corrected to M3.
4. A second review (`SEC-REVIEW-002`) runs against the actual M3 implementation. This review covers
   the specification only and cannot clear code that does not exist.

> Sign-off note: PO, Tech Lead and Security are all currently held by Nem Sothea, so this review is
> not independent of the decision it reviews. QA sign-off remains the only independent gate — the
> `FR-AUTH-003` conditions above are written so QA can verify them without re-deriving the reasoning.
