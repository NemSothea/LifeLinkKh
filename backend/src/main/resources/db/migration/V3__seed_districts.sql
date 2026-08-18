-- LifeLink KH — district reference rows (M3)
-- Content: docs/po/reference/phnom-penh-districts.md  (PO owns the list)
-- Decision: docs/decisions.md DEC-005
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- Unblocks what V2 documented as a blocker: with the table empty, the foreign key
-- on donor_profiles.district_code made PUT /donors/me answer 422 for every code.
--
-- Codes 1201-1212 are the NCDD Phnom Penh gazetteer's khan codes, checked on
-- 2026-08-18 (library.ncdd.gov.kh/detail/9649), including the three post-2019 ones
-- that were the reason V2 refused to seed.
--
-- Codes 1213 and 1214 are PROVISIONAL and LifeLink-assigned. Boeng Keng Kang and
-- Kamboul were created by sub-decree 03 of 8 January 2019, after that gazetteer was
-- published, so there is no official code to copy. They ship rather than being
-- withheld because Boeng Keng Kang is one of the densest parts of the city and a
-- donor there needs a district to pick; DEC-005 has the full argument.
--
-- If an official code surfaces for either, the correcting migration must UPDATE
-- donor_profiles.district_code in the same transaction — the FK will not do it.
--
-- Khmer is the primary label: the app defaults to km (FR-GLOBAL-001) and a
-- Latin-only dropdown is unusable for most donors. The Latin column is our own
-- transliteration, not the gazetteer's, because it is UI copy.

INSERT INTO districts (code, name_km, name_en) VALUES
    ('1201', 'ចំការមន',      'Chamkar Mon'),
    ('1202', 'ដូនពេញ',       'Doun Penh'),
    ('1203', 'ប្រាំពីរមករា',   'Prampi Makara'),
    ('1204', 'ទួលគោក',       'Tuol Kouk'),
    ('1205', 'ដង្កោ',         'Dangkao'),
    ('1206', 'មានជ័យ',        'Mean Chey'),
    ('1207', 'រុស្សីកែវ',      'Russey Keo'),
    ('1208', 'សែនសុខ',       'Sen Sok'),
    ('1209', 'ពោធិ៍សែនជ័យ',  'Pou Senchey'),
    ('1210', 'ជ្រោយចង្វារ',    'Chroy Changvar'),
    ('1211', 'ព្រែកព្នៅ',      'Prek Pnov'),
    ('1212', 'ច្បារអំពៅ',      'Chbar Ampov'),
    -- provisional, see the header
    ('1213', 'បឹងកេងកង',     'Boeng Keng Kang'),
    ('1214', 'កំបូល',          'Kamboul');
