-- LifeLink KH — two more HOSPITAL staff accounts, requested 2026-09-06.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Why a migration and not the Manage staff page: that page promotes someone who has
-- *already signed in* on the mobile app — it exists to grant portal access to a known
-- person, and its candidate list is built from users who have a display_name to pick by
-- (AdminService.listCandidates). These two are portal-only accounts with no Google
-- identity and no mobile history, so there is nobody to promote. Creating them here is the
-- same bootstrap path V8 used for the first admin.
--
-- firebase_uid is left NULL, unlike V8's placeholder strings: since V13 a username and
-- password satisfy users_has_a_credential_check on their own, so there is no longer any
-- reason to write a fake Google sub that could never authenticate.
--
-- Assigned to different hospitals on purpose. A HOSPITAL account sees only its own
-- hospital's requests (PortalService.listRequests), so two staff at the same hospital
-- would be indistinguishable in use; these two make the scoping visible — `tepi` sees the
-- Transfusion Center's long list, `july` sees one request at Khmer-Soviet Friendship.
-- One UPDATE each changes it if you want them elsewhere.
--
-- ⚠ DEVELOPMENT CREDENTIALS. Both passwords are 'qwer1234!' — note this is NOT the
-- 'qwer12324!' V13 and V14 seeded, so all four accounts are not one guess apart. Hashed
-- individually: BCrypt salts per row, so two accounts sharing a password do not share a
-- digest, and cracking one tells an attacker nothing about the other.
--
-- BEFORE THIS APP HOLDS ONE REAL DONOR'S DATA: change every seeded password. See
-- docs/demo-runbook.md section 9.

INSERT INTO users (username, password_hash, role, display_name, hospital_id)
SELECT
    'tepi',
    '$2a$10$3VFUEaIrdPSaNBAa5j6J/.dda1rT/pyNubkUkZnHoclV/hP9OE3R6',
    'HOSPITAL',
    'Tepi',
    id
FROM hospitals
WHERE name = 'National Blood Transfusion Center'
ON CONFLICT (username) DO NOTHING;

INSERT INTO users (username, password_hash, role, display_name, hospital_id)
SELECT
    'july',
    '$2a$10$uEgBYusAAyZ7XOGdXwXz6OEeUdUZkzAnutc9Gx0unHLOjV0WkdbPW',
    'HOSPITAL',
    'July',
    id
FROM hospitals
WHERE name = 'Khmer-Soviet Friendship Hospital'
ON CONFLICT (username) DO NOTHING;
