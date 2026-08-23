-- Dev-only: seeds one OPEN blood request with an accepted donor, against the seeded
-- Calmette Hospital (V7__seed_hospitals.sql), so the portal has something to show at a
-- demo instead of the empty state. Not a Flyway migration — demo data, not schema.
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
