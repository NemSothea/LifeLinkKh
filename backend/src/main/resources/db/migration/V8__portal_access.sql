-- Hospital portal access (M4/M5) — FR-PORTAL-001.
-- Spec: docs/fullstack/api-contract/web/contract.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- "Hospital staff see requests for their own hospital" (contract.md) has no schema behind it:
-- users has a role but nothing ties a HOSPITAL account to a hospital row. Nullable, like
-- hospitals.district_code in V4 — ADMIN and every DONOR/REQUESTER row legitimately has none.
ALTER TABLE users ADD COLUMN hospital_id UUID NULL REFERENCES hospitals (id);

COMMENT ON COLUMN users.hospital_id IS
    'Which hospital a HOSPITAL-role account is staff for. NULL for every other role, and for ADMIN (sees all hospitals).';

-- Seed one HOSPITAL account and one ADMIN account so the portal has someone to sign in as.
--
-- firebase_uid below is a PLACEHOLDER, not a real Google `sub`. POST /auth/google matches an
-- existing account by firebase_uid and returns its stored role (TM-AUTH-001 E1) — there is no
-- endpoint that promotes a self-serve account to HOSPITAL/ADMIN, by design, so the only way in is
-- a row that already has the right firebase_uid before that person's first sign-in. Nobody's real
-- Google `sub` is knowable at migration-write time.
--
-- UPDATE this row's firebase_uid to the real staff member's Google `sub` before any demo that
-- needs portal sign-in — the same "provisional, fix with one UPDATE" shape as the hospital
-- district codes in V7. Contract.md flags the seeding path itself as an unreviewed privileged
-- path (residual risk in TM-AUTH-001); this comment is that flag landing in the migration that
-- actually does it.
INSERT INTO users (firebase_uid, role, hospital_id) VALUES
    ('SEED-REPLACE-WITH-REAL-GOOGLE-SUB-HOSPITAL-STAFF', 'HOSPITAL',
     (SELECT id FROM hospitals WHERE name = 'Calmette Hospital')),
    ('SEED-REPLACE-WITH-REAL-GOOGLE-SUB-ADMIN', 'ADMIN', NULL);
