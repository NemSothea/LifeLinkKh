-- Gives a hospital a district, so Hospital.districtName in the mobile contract has a source.
-- Spec: docs/fullstack/specs/features/request-and-matching.md
--
-- Nullable on purpose. The column is added while `hospitals` is still empty (nothing has ever
-- seeded it), and a NOT NULL on an empty table that a later seed must satisfy is the same
-- constraint stated less clearly. The contract already marks districtName optional — only `id`
-- and `name` are required on Hospital — so a hospital without a district still serialises.
--
-- The foreign key is the point, for the same reason it was on donor_profiles: without it
-- district_code is free text that accepts "1204", "Toul Kork" and " 1204" as three districts.

ALTER TABLE hospitals ADD COLUMN district_code VARCHAR(16) NULL;

ALTER TABLE hospitals
    ADD CONSTRAINT hospitals_district_fk
    FOREIGN KEY (district_code) REFERENCES districts (code);

COMMENT ON COLUMN hospitals.district_code IS 'Nullable — hospitals are seeded in V5, after this column exists. References districts(code).';
