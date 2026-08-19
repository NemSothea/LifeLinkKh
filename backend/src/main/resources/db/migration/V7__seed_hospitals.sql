-- LifeLink KH — hospital reference rows (M4)
-- Content: docs/po/reference/phnom-penh-hospitals.md  (PO owns the list)
-- Spec:    docs/fullstack/specs/features/request-and-matching.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Unblocks the whole M4 flow. POST /requests requires a hospital_id, GET /hospitals
-- returned an empty dropdown, and nothing had ever written a row to this table.
--
-- THE COORDINATES ARE THE PART THAT MATTERS. They are the origin point for every
-- distance in FR-MATCH-001 — the matching query measures each donor from the hospital
-- named on the request. A hospital pinned in the wrong place silently ranks the wrong
-- donors first and the query still returns 25 plausible-looking rows. Every value below
-- comes from the OpenStreetMap Nominatim hospital object, checked on 2026-08-19, and
-- three of the five cross-check against Wikipedia to within ~50 m.
--
-- district_code is the opposite: display only. Nothing in matching reads it — it feeds
-- Hospital.districtName on the request form. Two rows are marked provisional below and
-- ship anyway, because a wrong label costs a one-line UPDATE and no donor row carries a
-- hospital district for it to cascade into.
--
-- Names are English only. hospitals has one name column, unlike districts. That gap is
-- real and is documented in the PO reference file for M6 with FR-GLOBAL-001; it is a
-- schema AND contract change, so it is not smuggled in here.
--
-- contact_phone is NULL throughout. Nothing in M4 reads it and an unchecked switchboard
-- number from a scraped directory is what the reference file exists to keep out.

INSERT INTO hospitals (name, address, latitude, longitude, district_code) VALUES
    ('Calmette Hospital',
     'Preah Monivong Boulevard (93), Sangkat Srah Chak, Khan Doun Penh',
     11.581329, 104.915690, '1202'),

    -- District PROVISIONAL only in the sense that 1213 is itself LifeLink-assigned:
    -- OSM places this campus in Sangkat Tumnob Tuek, which moved to Khan Boeng Keng Kang
    -- under sub-decree 03 of 8 January 2019, and no official code for that khan exists
    -- (DEC-005). A second OSM entry for the same hospital reports Khan Mean Chey — that
    -- is Street 271 running through the boundary, not a contradiction.
    ('Khmer-Soviet Friendship Hospital',
     'Yothapol Khemarak Phoumin Boulevard (271), Sangkat Tumnob Tuek',
     11.545289, 104.903984, '1213'),

    ('Preah Kossamak Hospital',
     'Sangkat Tuek L''ak Ti Bei, Khan Tuol Kouk',
     11.564010, 104.890378, '1204'),

    ('National Pediatric Hospital',
     '100, Confederation de la Russie Boulevard, Sangkat Tuek L''ak Ti Muoy',
     11.568123, 104.896826, '1204'),

    -- District GENUINELY DISPUTED. OSM puts it in Sangkat Boeng Tumpun 1, Khan Mean Chey;
    -- public directories give the address as Khan Boeng Keng Kang. It sits ~120 m from the
    -- KSFH campus on the far side of Street 271, so both readings are defensible. Seeded as
    -- what the mapped object says. Correcting it is one UPDATE.
    ('National Blood Transfusion Center',
     'Street 271, Sangkat Boeng Tumpun Ti Muoy',
     11.544034, 104.904658, '1206');
