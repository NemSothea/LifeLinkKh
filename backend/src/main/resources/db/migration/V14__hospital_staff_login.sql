-- LifeLink KH — a login for the seeded HOSPITAL account.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- V13 gave the seeded ADMIN row a username and left the HOSPITAL row without one, which
-- made half the product untestable: the two roles differ in what they can see and do
-- (own hospital vs every hospital, "Manage staff" or not), and only one of them could
-- sign in to demonstrate it.
--
-- Its own migration rather than an edit to V13: Flyway records a checksum per file, so
-- changing an applied migration makes the next start fail rather than apply the change.
--
-- ⚠ DEVELOPMENT CREDENTIAL, same as V13's. The password is 'qwer12324!' — the same one,
-- deliberately: one dev credential to remember, and the same single line in
-- docs/demo-runbook.md section 9 changes both. It is safe only while every account in
-- this pilot is team-created test data (docs/scope.md, FR-SECURITY-001's note).
UPDATE users
SET username      = 'calmette',
    display_name  = COALESCE(display_name, 'Calmette Staff'),
    password_hash = '$2a$10$FVA4wDUhCik15HDbg9w6rezF9lK5TORoiXnHX3FVDtkT8I/cokAKi'
WHERE role = 'HOSPITAL'
  AND firebase_uid = 'SEED-REPLACE-WITH-REAL-GOOGLE-SUB-HOSPITAL-STAFF';
