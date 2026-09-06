-- LifeLink KH — a way to switch a portal account off without deleting the person.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Revoking access to a *promoted* account is just a role change: put them back to DONOR
-- and they keep the mobile account they signed up with. A **portal-only** account has no
-- such place to go — it exists only to sign in at the portal, so "not staff any more"
-- would leave a row with a username, a password and no usable role.
--
-- Deleting the row is not the answer either, and this is the reason the column exists:
-- `donations.confirmed_by_user_id` and `blood_requests.created_by_user_id` reference
-- users, so a staff account that has confirmed a donation is part of the audit trail for
-- that donation. Deleting it either fails on the foreign key or destroys the record of
-- who confirmed what. The account is switched off; the history it created stays.
--
-- NULL means active. A timestamp, not a boolean, because "when did this stop" is the
-- question anyone asks afterwards and a boolean cannot answer it.

ALTER TABLE users ADD COLUMN deactivated_at TIMESTAMPTZ;

COMMENT ON COLUMN users.deactivated_at IS
    'When portal access was revoked. NULL = active. AuthService.signInWithPassword refuses any account with a value here, using the same answer as a wrong password.';

CREATE INDEX idx_users_active_staff ON users (role) WHERE deactivated_at IS NULL;
