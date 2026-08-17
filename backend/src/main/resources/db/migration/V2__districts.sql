-- LifeLink KH — districts reference table (M3)
-- Spec: docs/fullstack/specs/features/donor-profile.md ("The schema gap that has to close first")
-- List: docs/po/reference/phnom-penh-districts.md  (PO owns the content)
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Why this table exists at all: openapi.yaml requires districtName on every
-- DonorProfile response and nothing in V1 could supply it. district_code was a
-- bare VARCHAR(16) with no table behind it, which accepts 'toul kork', 'TK' and
-- 'Toul  Kork' as three different districts — and a district-filtered matching
-- query then silently returns nothing.

CREATE TABLE districts (
    code       VARCHAR(16)  PRIMARY KEY,
    name_km    VARCHAR(80)  NOT NULL,
    name_en    VARCHAR(80)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE districts IS 'Phnom Penh khan. Reference data — seeded by migration, never by application code.';
COMMENT ON COLUMN districts.code IS 'National geocode: province 12 + two-digit district.';
COMMENT ON COLUMN districts.name_km IS 'Primary label. The app defaults to km (FR-GLOBAL-001); a Latin-only dropdown is unusable for most donors.';

-- The foreign key is the point of this migration. Adding it after donor rows
-- exist means cleaning data first.
ALTER TABLE donor_profiles
    ADD CONSTRAINT donor_profiles_district_fk
    FOREIGN KEY (district_code) REFERENCES districts (code);

-- ---------------------------------------------------------------------------
-- NO SEED ROWS. This is deliberate and it is a blocker, not an omission.
--
-- docs/po/reference/phnom-penh-districts.md carries the 14 districts and says
-- plainly: do not seed while any row is marked unverified. Five codes
-- (1210-1214, the districts renumbered after the 2019 reorganisation) are still
-- unverified against an official NCDD/MoI list.
--
-- district_code lands in donor_profiles rows, so a wrong code becomes a data
-- migration rather than an edit — which is exactly why PO's rule is worth
-- obeying instead of seeding "the nine safe ones" and calling it progress.
--
-- Consequences while this stands, both known and accepted:
--   * PUT /donors/me rejects every districtCode with 422 (the FK holds).
--   * The local stack has no district list to demo.
--   * Tests insert their own district rows, which they would do anyway.
--
-- Unblocks as V3__seed_districts.sql once PO marks all 14 verified.
-- ---------------------------------------------------------------------------
