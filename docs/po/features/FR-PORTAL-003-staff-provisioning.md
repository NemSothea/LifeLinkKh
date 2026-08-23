---
id: FR-PORTAL-003-staff-provisioning
title: Admin-managed staff accounts
area: PORTAL
status: accepted
priority: Must Have
owner: PO
brief_ref: docs/demo-runbook.md section 5
---

## Problem
The only way a hospital ever got portal access was `V8__portal_access.sql` — Tech Lead hand-editing a
SQL migration per staff member. That does not scale past the pilot's five seeded hospitals, and it
means the person actually accountable for who has access (an `ADMIN`) has no way to grant or review
it themselves. TM-AUTH-001 E1 already specified the right shape — "HOSPITAL and ADMIN are
provisioned by an existing admin" — the migration was a placeholder for it, not the design.

## Desired outcome
An `ADMIN`, from the portal, can see who currently has staff access and grant `HOSPITAL` (scoped to a
hospital) or `ADMIN` access to someone — without writing SQL, and without the person being granted
access doing anything beyond the sign-in they'd already do as a donor or requester.

## Why
Real onboarding for a pilot hospital cannot depend on a developer's laptop and `psql` access. This
closes that gap the same way the rest of auth already works: identity comes only from a verified
Google sign-in, an `ADMIN` decides what role it maps to.

## Scope
**In:**
- `GET /admin/users` — self-service accounts (`DONOR`/`REQUESTER`) an `ADMIN` could promote,
  identified by the display name captured at their sign-in.
- `GET /admin/staff` — current `HOSPITAL`/`ADMIN` accounts, with their hospital.
- `POST /admin/staff` — promotes an existing account to `HOSPITAL` (hospital required) or `ADMIN`
  (hospital must be absent). Refuses an account already on staff.
- Portal screen at `/portal/admin`, `ADMIN`-only, linked from the main portal page for `ADMIN`
  sessions only.
- `users.display_name`, captured from the verified Google ID token at every sign-in — the one new
  piece of stored data, and not email or phone.

**Out:**
- A self-service invite flow (a code or link sent to someone who has never signed in) — would need
  either storing an email (rejected — see the "why not email" note below) or a token/invite table,
  neither of which this pilot's five hospitals justify yet.
- Revoking or editing an existing staff grant — `POST /admin/staff` only promotes; there is no
  `DELETE` or role-downgrade endpoint yet.
- The portal's own Google Sign-In button (still `FR-PORTAL-001`'s open item) — this FR only covers
  who is *allowed* to have a session, not how they obtain one.

### Why not match by email
`GoogleTokenVerifier`'s own comment already rejected storing email: "we have no use for it, and
storing it would make it a breach asset." An admin-driven invite by email would have reopened that.
Requiring the person to sign in once first — creating an ordinary self-service account, the same
action every donor takes — gives the `ADMIN` a name to pick from instead, at no new PII cost.

## Acceptance criteria
- [x] An `ADMIN` session can list existing staff and self-service candidates.
- [x] Promoting a candidate to `HOSPITAL` without a `hospitalId` is refused (`HOSPITAL_ID_REQUIRED`).
- [x] Promoting a candidate to `ADMIN` with a `hospitalId` is refused (`HOSPITAL_ID_NOT_ALLOWED`).
- [x] Promoting an account already on staff is refused (`ALREADY_STAFF`), not silently re-applied.
- [x] A `HOSPITAL` or self-service JWT hitting `/admin/*` gets 403 before the controller runs
      (`SecurityConfig`, same shape as `/portal/**`).
- [x] A candidate with no `display_name` (an account from before this feature existed, never
      signed in since) is never shown — there is nothing to identify them by.
