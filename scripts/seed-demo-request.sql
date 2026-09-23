-- Dev-only: seeds three OPEN blood requests across three hospitals and three urgency
-- tiers (CRITICAL/URGENT/ROUTINE), two with an accepted donor and one still unmatched,
-- so the portal has a realistic-looking list to show at a demo instead of the empty
-- state or a single repeated card shape. Against hospitals seeded by
-- V7__seed_hospitals.sql. Not a Flyway migration — demo data, not schema.
-- See docs/demo-runbook.md section 3.
--
-- Timestamps are staggered on purpose. Every row used to be written at now(), which meant a
-- request was created, the donor notified and the donor's answer recorded in the same instant:
-- scripts/metrics.sql then reported a median time-to-first-acceptance of 0.0 minutes. A number
-- that cannot happen is worse than no number. The two accepted requests here answer in 12 and
-- 25 minutes, both inside the PRD's 60-minute window and straddling its 30-minute median target,
-- and the third is never answered — so metric 2 reads 2 of 3, not a clean 100%.
--
-- The request and match rows UPSERT rather than DO NOTHING, so re-running this refreshes their
-- ages. With DO NOTHING a database seeded weeks ago kept its original rows and its original
-- timestamps: on 2026-09-23 the board showed CRITICAL requests dated 6 September, and editing
-- the intervals above changed nothing until the rows were deleted by hand. Reference rows
-- (users, donor profiles) still DO NOTHING — they carry no age worth refreshing.
--
-- Usage:
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/seed-demo-request.sql

INSERT INTO users (id, firebase_uid, role, display_name)
VALUES ('11111111-1111-1111-1111-111111111111', 'DEMO-DONOR-SOK-DARA', 'DONOR', 'Sok Dara')
ON CONFLICT (firebase_uid) DO NOTHING;

INSERT INTO donor_profiles (id, user_id, full_name, blood_type, district_code, is_available)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Sok Dara',
    'O+',
    '1202',
    true
)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO users (id, firebase_uid, role, display_name)
VALUES ('33333333-3333-3333-3333-333333333333', 'DEMO-REQUESTER-CHEA-SREY', 'REQUESTER', 'Chea Srey')
ON CONFLICT (firebase_uid) DO NOTHING;

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone, created_at)
SELECT
    '44444444-4444-4444-4444-444444444444',
    '33333333-3333-3333-3333-333333333333',
    id,
    'O+',
    2,
    'CRITICAL',
    'OPEN',
    'Chea Srey',
    '+85512345678',
    now() - interval '2 hours'
FROM hospitals WHERE name = 'Calmette Hospital'
ON CONFLICT (id) DO UPDATE SET
    created_at = EXCLUDED.created_at,
    status     = EXCLUDED.status;

INSERT INTO request_matches (id, blood_request_id, donor_profile_id, notified_at, response, responded_at)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    '44444444-4444-4444-4444-444444444444',
    '22222222-2222-2222-2222-222222222222',
    now() - interval '2 hours' + interval '40 seconds',
    'ACCEPTED',
    now() - interval '2 hours' + interval '12 minutes'
)
ON CONFLICT (id) DO UPDATE SET
    notified_at  = EXCLUDED.notified_at,
    response     = EXCLUDED.response,
    responded_at = EXCLUDED.responded_at;

-- Second scenario: a rare-type (AB-) request at a different hospital, matched by an
-- O- donor (the universal donor, so the match reads correctly to anyone checking
-- compatibility by eye). Gives the portal list a second hospital and a second urgency
-- tier (URGENT, not CRITICAL) instead of one repeated shape.

INSERT INTO users (id, firebase_uid, role, display_name)
VALUES ('77777777-7777-7777-7777-777777777777', 'DEMO-DONOR-LY-RATANAK', 'DONOR', 'Ly Ratanak')
ON CONFLICT (firebase_uid) DO NOTHING;

INSERT INTO donor_profiles (id, user_id, full_name, blood_type, district_code, is_available)
VALUES (
    '88888888-8888-8888-8888-888888888888',
    '77777777-7777-7777-7777-777777777777',
    'Ly Ratanak',
    'O-',
    '1204',
    true
)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO users (id, firebase_uid, role, display_name)
VALUES ('99999999-9999-9999-9999-999999999999', 'DEMO-REQUESTER-VANN-SOPHEAK', 'REQUESTER', 'Vann Sopheak')
ON CONFLICT (firebase_uid) DO NOTHING;

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone, created_at)
SELECT
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-9999-9999-999999999999',
    id,
    'AB-',
    1,
    'URGENT',
    'OPEN',
    'Vann Sopheak',
    '+85511122233',
    now() - interval '50 minutes'
FROM hospitals WHERE name = 'National Pediatric Hospital'
ON CONFLICT (id) DO UPDATE SET
    created_at = EXCLUDED.created_at,
    status     = EXCLUDED.status;

INSERT INTO request_matches (id, blood_request_id, donor_profile_id, notified_at, response, responded_at)
VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '88888888-8888-8888-8888-888888888888',
    now() - interval '50 minutes' + interval '25 seconds',
    'ACCEPTED',
    now() - interval '50 minutes' + interval '25 minutes'
)
ON CONFLICT (id) DO UPDATE SET
    notified_at  = EXCLUDED.notified_at,
    response     = EXCLUDED.response,
    responded_at = EXCLUDED.responded_at;

-- Third scenario: ROUTINE, no donor matched yet — deliberately left empty (no
-- request_matches row) so the portal's "Nothing waiting on confirmation" state and the
-- 0-alerted/0-accepted counters have something real to show, not just the two already-
-- accepted rows above.

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone, created_at)
SELECT
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '99999999-9999-9999-9999-999999999999',
    id,
    'B+',
    3,
    'ROUTINE',
    'OPEN',
    'Vann Sopheak',
    '+85511122233',
    now() - interval '20 minutes'
FROM hospitals WHERE name = 'Khmer-Soviet Friendship Hospital'
ON CONFLICT (id) DO UPDATE SET
    created_at = EXCLUDED.created_at,
    status     = EXCLUDED.status;
