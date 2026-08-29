-- Dev-only: seeds three OPEN blood requests across three hospitals and three urgency
-- tiers (CRITICAL/URGENT/ROUTINE), two with an accepted donor and one still unmatched,
-- so the portal has a realistic-looking list to show at a demo instead of the empty
-- state or a single repeated card shape. Against hospitals seeded by
-- V7__seed_hospitals.sql. Not a Flyway migration — demo data, not schema.
-- See docs/demo-runbook.md section 3.
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

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone)
SELECT
    '44444444-4444-4444-4444-444444444444',
    '33333333-3333-3333-3333-333333333333',
    id,
    'O+',
    2,
    'CRITICAL',
    'OPEN',
    'Chea Srey',
    '+85512345678'
FROM hospitals WHERE name = 'Calmette Hospital'
ON CONFLICT (id) DO NOTHING;

INSERT INTO request_matches (id, blood_request_id, donor_profile_id, notified_at, response, responded_at)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    '44444444-4444-4444-4444-444444444444',
    '22222222-2222-2222-2222-222222222222',
    now(),
    'ACCEPTED',
    now()
)
ON CONFLICT (id) DO NOTHING;

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

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone)
SELECT
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-9999-9999-999999999999',
    id,
    'AB-',
    1,
    'URGENT',
    'OPEN',
    'Vann Sopheak',
    '+85511122233'
FROM hospitals WHERE name = 'National Pediatric Hospital'
ON CONFLICT (id) DO NOTHING;

INSERT INTO request_matches (id, blood_request_id, donor_profile_id, notified_at, response, responded_at)
VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '88888888-8888-8888-8888-888888888888',
    now(),
    'ACCEPTED',
    now()
)
ON CONFLICT (id) DO NOTHING;

-- Third scenario: ROUTINE, no donor matched yet — deliberately left empty (no
-- request_matches row) so the portal's "Nothing waiting on confirmation" state and the
-- 0-alerted/0-accepted counters have something real to show, not just the two already-
-- accepted rows above.

INSERT INTO blood_requests (id, created_by_user_id, hospital_id, patient_blood_type, units_needed, urgency, status, contact_name, contact_phone)
SELECT
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '99999999-9999-9999-9999-999999999999',
    id,
    'B+',
    3,
    'ROUTINE',
    'OPEN',
    'Vann Sopheak',
    '+85511122233'
FROM hospitals WHERE name = 'Khmer-Soviet Friendship Hospital'
ON CONFLICT (id) DO NOTHING;
