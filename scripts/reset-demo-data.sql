-- LifeLink KH — wipe the transactional data and leave the reference data standing.
--
-- DEV AND DEMO ONLY. This deletes every donation, match, request, donor profile and
-- donor/requester account in the database it is pointed at. It is irreversible and it does not
-- ask. Never run it against anything but a local stack.
--
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/reset-demo-data.sql
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/seed-demo-request.sql
--
-- Why this exists: a laptop that has been rehearsed on for a month accumulates the rehearsals.
-- On 2026-09-23 the demo database held 54 requests, 48 of them cancelled leftovers pointed at the
-- same hospital, and scripts/metrics.sql read 5.6% against a 70% target because of it. The board
-- also showed "urgent" requests three weeks old. Neither is a bug; both look like one from the
-- back of a room.
--
-- What SURVIVES, because it is reference data seeded by migrations and not by a demo:
--   districts · hospitals · blood_compatibility · portal staff accounts (HOSPITAL / ADMIN users)
--
-- After this runs the portal is legitimately empty. Seed immediately, or run the golden path —
-- docs/demo-runbook.md section 6 says it in the other direction: never open a cold portal in
-- front of an audience.

BEGIN;

DELETE FROM donations;
DELETE FROM request_matches;
DELETE FROM blood_requests;
DELETE FROM donor_profiles;

-- Staff sign in with these rows (V13-V16), so role is the line, not "everything".
DELETE FROM users WHERE role IN ('DONOR', 'REQUESTER');

COMMIT;

SELECT 'requests'   AS table, count(*) AS remaining FROM blood_requests
UNION ALL SELECT 'matches',    count(*) FROM request_matches
UNION ALL SELECT 'donations',  count(*) FROM donations
UNION ALL SELECT 'donors',     count(*) FROM donor_profiles
UNION ALL SELECT 'staff users (kept)', count(*) FROM users WHERE role IN ('HOSPITAL', 'ADMIN')
UNION ALL SELECT 'hospitals (kept)',   count(*) FROM hospitals
UNION ALL SELECT 'districts (kept)',   count(*) FROM districts;
