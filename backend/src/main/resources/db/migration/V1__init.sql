-- LifeLink KH — initial schema (M2)
-- Spec: docs/fullstack/specs/foundation/backend-spring.md ("Initial schema — V1__init.sql")
-- ERD:  docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- users — identity. Credential is the Google `sub` (ADR 0002, TM-AUTH-001 S1).
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    phone        VARCHAR(20)  NULL UNIQUE,
    role         VARCHAR(16)  NOT NULL,
    language     CHAR(2)      NOT NULL DEFAULT 'km',
    fcm_token    TEXT         NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT users_role_check     CHECK (role IN ('DONOR', 'REQUESTER', 'HOSPITAL', 'ADMIN')),
    CONSTRAINT users_language_check CHECK (language IN ('km', 'en'))
);

COMMENT ON COLUMN users.firebase_uid IS 'Google sub from the verified ID token. Written server-side only, never from a request body.';
COMMENT ON COLUMN users.phone IS 'E.164. UNVERIFIED since auth moved off OTP (ADR 0002).';

-- ---------------------------------------------------------------------------
-- donor_profiles — donor-only attributes. 1:0..1 with users.
-- latitude/longitude MUST NEVER appear in an API response (ADR 0003).
-- ---------------------------------------------------------------------------
CREATE TABLE donor_profiles (
    id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID         NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
    full_name          VARCHAR(120) NOT NULL,
    blood_type         VARCHAR(3)   NOT NULL,
    last_donation_date DATE         NULL,
    is_available       BOOLEAN      NOT NULL DEFAULT true,
    district_code      VARCHAR(16)  NOT NULL,
    latitude           NUMERIC(8,5) NULL,
    longitude          NUMERIC(8,5) NULL,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT donor_profiles_blood_type_check
        CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);

COMMENT ON COLUMN donor_profiles.last_donation_date IS 'NULL = never donated. Cache of MAX(donations.donated_on); donations wins on disagreement.';
COMMENT ON COLUMN donor_profiles.district_code IS 'The only location value ever returned to another user (ADR 0003).';
COMMENT ON COLUMN donor_profiles.latitude IS 'Distance ranking only. Never returned by any API. Nullable on purpose — donor may decline GPS.';
COMMENT ON COLUMN donor_profiles.longitude IS 'Distance ranking only. Never returned by any API.';

-- ---------------------------------------------------------------------------
-- hospitals — public locations, so full precision is permitted.
-- ---------------------------------------------------------------------------
CREATE TABLE hospitals (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(160)  NOT NULL,
    address       TEXT          NULL,
    contact_phone VARCHAR(20)   NULL,
    latitude      NUMERIC(9,6)  NOT NULL,
    longitude     NUMERIC(9,6)  NOT NULL,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- blood_requests — start of the core loop.
-- status EXPIRED is a KNOWN DEAD VALUE at M2: FR-04 lists it, but the expiry
-- rule is undecided, so nothing in this schema can set it. See the spec's
-- "Blocked schema decisions". Resolve before M4 in V<n>__add_request_expiry.sql.
-- ---------------------------------------------------------------------------
CREATE TABLE blood_requests (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by_user_id  UUID        NOT NULL REFERENCES users (id),
    hospital_id         UUID        NOT NULL REFERENCES hospitals (id),
    patient_blood_type  VARCHAR(3)  NOT NULL,
    units_needed        SMALLINT    NOT NULL,
    urgency             VARCHAR(16) NOT NULL,
    status              VARCHAR(16) NOT NULL DEFAULT 'OPEN',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT blood_requests_blood_type_check
        CHECK (patient_blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    CONSTRAINT blood_requests_units_check   CHECK (units_needed > 0),
    CONSTRAINT blood_requests_urgency_check CHECK (urgency IN ('CRITICAL', 'URGENT', 'ROUTINE')),
    CONSTRAINT blood_requests_status_check  CHECK (status IN ('OPEN', 'FULFILLED', 'CANCELLED', 'EXPIRED'))
);

-- ---------------------------------------------------------------------------
-- request_matches — the match is the thing that has state (notified, answered).
-- ---------------------------------------------------------------------------
CREATE TABLE request_matches (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    blood_request_id UUID        NOT NULL REFERENCES blood_requests (id) ON DELETE CASCADE,
    donor_profile_id UUID        NOT NULL REFERENCES donor_profiles (id) ON DELETE CASCADE,
    notified_at      TIMESTAMPTZ NULL,
    response         VARCHAR(16) NULL,
    responded_at     TIMESTAMPTZ NULL,
    CONSTRAINT request_matches_unique_pair UNIQUE (blood_request_id, donor_profile_id),
    CONSTRAINT request_matches_response_check
        CHECK (response IN ('ACCEPTED', 'DECLINED', 'WITHDRAWN'))
);

COMMENT ON COLUMN request_matches.notified_at IS 'Set when the FCM send succeeds (FR-NOTIFY-001).';
COMMENT ON COLUMN request_matches.response IS 'WITHDRAWN has no FR yet — PRD section 7 error flow only.';

-- ---------------------------------------------------------------------------
-- donations — sole source of truth for the 56-day cooldown.
-- ---------------------------------------------------------------------------
CREATE TABLE donations (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_profile_id      UUID        NOT NULL REFERENCES donor_profiles (id),
    hospital_id           UUID        NOT NULL REFERENCES hospitals (id),
    blood_request_id      UUID        NULL REFERENCES blood_requests (id),
    donated_on            DATE        NOT NULL,
    confirmed_by_user_id  UUID        NULL REFERENCES users (id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN donations.blood_request_id IS 'Nullable per FR-08 — a walk-in donation has no originating request.';
COMMENT ON COLUMN donations.donated_on IS 'Source of truth for the 56-day cooldown (FR-DONOR-002).';

-- ---------------------------------------------------------------------------
-- blood_compatibility — 27 valid (recipient, donor) pairs, ADR 0004.
-- Whole blood / red cells ONLY. Plasma and platelet compatibility differ and
-- this table MUST NOT be reused for them.
-- Seed data must be verified against a clinical source during review.
-- ---------------------------------------------------------------------------
CREATE TABLE blood_compatibility (
    recipient_type VARCHAR(3) NOT NULL,
    donor_type     VARCHAR(3) NOT NULL,
    PRIMARY KEY (recipient_type, donor_type),
    CONSTRAINT blood_compatibility_recipient_check
        CHECK (recipient_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    CONSTRAINT blood_compatibility_donor_check
        CHECK (donor_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);

INSERT INTO blood_compatibility (recipient_type, donor_type) VALUES
    ('O-',  'O-'),
    ('O+',  'O-'), ('O+',  'O+'),
    ('A-',  'O-'), ('A-',  'A-'),
    ('A+',  'O-'), ('A+',  'O+'), ('A+',  'A-'), ('A+',  'A+'),
    ('B-',  'O-'), ('B-',  'B-'),
    ('B+',  'O-'), ('B+',  'O+'), ('B+',  'B-'), ('B+',  'B+'),
    ('AB-', 'O-'), ('AB-', 'A-'), ('AB-', 'B-'), ('AB-', 'AB-'),
    ('AB+', 'O-'), ('AB+', 'O+'), ('AB+', 'A-'), ('AB+', 'A+'),
    ('AB+', 'B-'), ('AB+', 'B+'), ('AB+', 'AB-'), ('AB+', 'AB+');

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
-- users(firebase_uid) and users(phone) are already covered by their UNIQUE
-- constraints — PostgreSQL builds a unique index for each. No duplicates here.
CREATE INDEX idx_donor_profiles_blood_type_available ON donor_profiles (blood_type, is_available);
CREATE INDEX idx_donor_profiles_district            ON donor_profiles (district_code);
CREATE INDEX idx_blood_requests_status_created      ON blood_requests (status, created_at DESC);
CREATE INDEX idx_request_matches_donor             ON request_matches (donor_profile_id);
CREATE INDEX idx_donations_donor_donated_on        ON donations (donor_profile_id, donated_on DESC);

-- No spatial index at M2. A computed ordering is fine at pilot size (ADR 0003).
