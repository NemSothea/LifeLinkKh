-- LifeLink KH — index coverage for the queries that actually run, and range checks on the
-- coordinates the whole matching feature rests on.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Nothing here changes a shape or a meaning. Every statement either makes an existing query
-- read fewer rows, or refuses a value that was already impossible in the real world.

-- ---------------------------------------------------------------------------
-- Indexes for the two request queries that had none
-- ---------------------------------------------------------------------------
-- PortalService.listRequests for a HOSPITAL account runs
-- findByStatusAndHospitalIdOrderByCreatedAtDesc. The only index that existed,
-- idx_blood_requests_status_created, is keyed on (status, created_at) — so a hospital with three
-- open requests still walked every OPEN request in the country and filtered by hospital
-- afterwards. Hospital first: it is the equality predicate that eliminates the most rows.
CREATE INDEX idx_blood_requests_hospital_status_created
    ON blood_requests (hospital_id, status, created_at DESC);

-- GET /requests/me — findByCreatedByUserIdOrderByCreatedAtDesc, which had no index at all.
CREATE INDEX idx_blood_requests_creator_created
    ON blood_requests (created_by_user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Foreign keys with no index behind them
-- ---------------------------------------------------------------------------
-- PostgreSQL indexes the *referenced* side of a foreign key (it is a primary or unique key) and
-- never the referencing side. Every one of these columns is a join target, and every DELETE on the
-- parent row has to scan the whole child table to prove no reference remains.
--
-- Not exhaustive by accident: donor_profiles.user_id already has a unique index, donations
-- (donor_profile_id, ...) and request_matches (blood_request_id, ...) are covered by an existing
-- index or unique constraint whose leading column is the FK, and donor_profiles.district_code has
-- idx_donor_profiles_district. Those are left alone rather than duplicated.
CREATE INDEX idx_donations_blood_request ON donations (blood_request_id);
CREATE INDEX idx_donations_hospital      ON donations (hospital_id);
CREATE INDEX idx_donations_confirmed_by  ON donations (confirmed_by_user_id);
CREATE INDEX idx_users_hospital          ON users (hospital_id);
CREATE INDEX idx_hospitals_district      ON hospitals (district_code);

-- ---------------------------------------------------------------------------
-- One index removed
-- ---------------------------------------------------------------------------
-- telegram_auth_challenges.session_token is declared UNIQUE, and PostgreSQL builds a unique index
-- to enforce that. V11 then created a second, plain index on the same single column — two B-trees
-- maintained on every insert, one of which the planner will never choose. V1 states this rule for
-- users(firebase_uid) and users(phone) explicitly ("already covered by their UNIQUE constraints
-- ... No duplicates here"); V11 is the one place that broke it.
DROP INDEX idx_telegram_auth_challenges_session_token;

-- ---------------------------------------------------------------------------
-- Coordinate range checks
-- ---------------------------------------------------------------------------
-- The one algorithm in this product — ADR 0003's distance sort — reads these columns, and
-- request_matches.distance_km is written once at match time and, per V6, "never recomputed". So a
-- latitude and longitude entered the wrong way round is not a display bug that a refresh fixes: it
-- is a permanently wrong distance on every match that donor is ever offered, and the value is
-- plausible enough that nothing downstream would flag it. NUMERIC(8,5) accepts 104.9 as a latitude
-- today; after this it cannot.
--
-- Phnom Penh sits near 11.55 N, 104.92 E, so a transposed pair puts latitude outside ±90 and this
-- catches it. A pair swapped between two points both inside range is not detectable here, and is
-- not claimed to be.
ALTER TABLE donor_profiles
    ADD CONSTRAINT donor_profiles_latitude_check
    CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90);

ALTER TABLE donor_profiles
    ADD CONSTRAINT donor_profiles_longitude_check
    CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180);

ALTER TABLE hospitals
    ADD CONSTRAINT hospitals_latitude_check  CHECK (latitude  BETWEEN -90 AND 90);

ALTER TABLE hospitals
    ADD CONSTRAINT hospitals_longitude_check CHECK (longitude BETWEEN -180 AND 180);
