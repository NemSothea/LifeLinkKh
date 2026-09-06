-- LifeLink KH — username + password sign-in for portal staff.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Why this exists, given ADR 0002 deliberately moved authentication OFF credentials:
-- it moved *donor and requester* authentication off them, because a donor should not
-- hold a password for an app they open three times a year, and because Firebase already
-- proves that identity for free. Portal staff are a different population: a handful of
-- named hospital accounts that must be reachable from a desktop browser with no Firebase
-- Web app registered and no phone in the loop. Until now the answer was PORTAL_DEV_JWT,
-- a token pasted into .env by hand — which is not a login, has no owner, and cannot be
-- revoked from inside the product.
--
-- Scope is deliberately narrow, and the narrowness is the security argument:
--   * Only HOSPITAL and ADMIN accounts may ever hold a password (enforced in
--     AuthService.signInWithPassword, which refuses any other role even if a row somehow
--     carries one).
--   * There is no self-service sign-up, no password reset and no "remember me". An
--     ADMIN grants access; a forgotten password is a new hash set by a migration.
--   * Nothing about donor or requester authentication changes.

ALTER TABLE users ADD COLUMN username      VARCHAR(64) UNIQUE;
ALTER TABLE users ADD COLUMN password_hash VARCHAR(100);

COMMENT ON COLUMN users.username IS
    'Portal sign-in name. NULL for every donor and requester — they authenticate through Google or Telegram and never hold one.';
COMMENT ON COLUMN users.password_hash IS
    'BCrypt digest, never the password. Written only by a migration or an ADMIN action; never echoed by any endpoint, never logged.';

-- Both halves or neither: a row with a username and no hash would be an account nobody
-- can sign in to that still occupies the unique name.
ALTER TABLE users ADD CONSTRAINT users_password_pair_check
    CHECK ((username IS NULL AND password_hash IS NULL)
        OR (username IS NOT NULL AND password_hash IS NOT NULL));

-- V11 declared what counts as a credential. A username/password pair is now a third one,
-- and without this line a staff account that has only a password would violate the
-- constraint that says every user must be able to prove who they are.
ALTER TABLE users DROP CONSTRAINT users_has_a_credential_check;
ALTER TABLE users ADD CONSTRAINT users_has_a_credential_check
    CHECK (firebase_uid IS NOT NULL
        OR telegram_chat_id IS NOT NULL
        OR username IS NOT NULL);

-- ---------------------------------------------------------------------------
-- The bootstrap ADMIN
-- ---------------------------------------------------------------------------
-- V8 seeded an ADMIN row whose firebase_uid is the literal string
-- 'SEED-REPLACE-WITH-REAL-GOOGLE-SUB-ADMIN' — a row, not a person, and one nobody could
-- ever sign in as. This gives that row a way in rather than creating a second admin.
--
-- ⚠ DEVELOPMENT CREDENTIAL. The password below is 'qwer12324!', known to anyone who can
-- read this repository, and it is seeded so a fresh clone has a working portal login on
-- the first `docker compose up`. It is safe only because every account in this pilot is
-- team-created test data (docs/scope.md, FR-SECURITY-001's note).
--
-- BEFORE THIS APP HOLDS ONE REAL DONOR'S DATA: change it. See
-- docs/demo-runbook.md section 9 for the one-line UPDATE that does it.
UPDATE users
SET username      = 'soborey',
    display_name  = COALESCE(display_name, 'Soborey'),
    password_hash = '$2a$10$/p14LfkEsoXRFKGRaXxNfONY/BljmQIM84kjUDLadMELQ0KQcIxTK'
WHERE role = 'ADMIN'
  AND firebase_uid = 'SEED-REPLACE-WITH-REAL-GOOGLE-SUB-ADMIN';
