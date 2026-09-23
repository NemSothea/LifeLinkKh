-- LifeLink KH — will the demo request actually match anybody?
--
-- Run this BEFORE the audience is in the room. A request that matches nobody is not an error
-- anywhere in the product: the API answers 201, the portal shows the request, and the donor's
-- phone stays silent. FR-MATCH-002 (retry with a wider radius) is deferred, so there is no
-- second chance and nothing on screen explains the silence. This script turns that into a
-- sentence you can read before it happens.
--
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/preflight-match.sql
--
-- Against other values than the pinned golden path (docs/demo-runbook.md section 3):
--
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink \
--     -v patient_type="O+" -v hospital="National Pediatric Hospital" < scripts/preflight-match.sql
--
-- It mirrors DonorCandidateRepository.findCandidates by hand. Two deliberate differences:
--   * it does not exclude the requester's own donor profile, because it does not know who will
--     post the request — the runbook's trap list covers that one;
--   * it shows the donors that FAIL and why, which the repository has no reason to do.
-- If the matching rules change, this file is a second place that has to change. The constants
-- below are the ones to check: lifelink.matching.radius-km and EligibilityCalculator.COOLDOWN_DAYS.

\pset border 2
\pset null '—'

-- Defaults are the pinned golden path. -v on the command line overrides either one.
\if :{?patient_type}
\else
    \set patient_type 'AB+'
\endif

\if :{?hospital}
\else
    \set hospital 'Calmette Hospital'
\endif

\echo ''
\echo 'Pre-flight — patient type and hospital are shown in the rows. Anything not MATCH stays silent.'
\echo ''

WITH target AS (
    SELECT name, latitude, longitude
    FROM hospitals
    WHERE name = :'hospital'
),
donor AS (
    SELECT dp.full_name,
           dp.blood_type,
           d.name_en                AS district,
           dp.is_available,
           dp.last_donation_date,
           u.fcm_token,
           CASE WHEN dp.latitude IS NULL OR dp.longitude IS NULL THEN NULL
                ELSE 6371 * acos(least(1,
                         cos(radians(t.latitude)) * cos(radians(dp.latitude))
                           * cos(radians(dp.longitude) - radians(t.longitude))
                       + sin(radians(t.latitude)) * sin(radians(dp.latitude))
                     ))
           END                      AS distance_km,
           EXISTS (SELECT 1 FROM blood_compatibility bc
                    WHERE bc.donor_type = dp.blood_type
                      AND bc.recipient_type = :'patient_type') AS compatible
    FROM donor_profiles dp
    JOIN users u      ON u.id = dp.user_id
    JOIN districts d  ON d.code = dp.district_code
    CROSS JOIN target t
)
SELECT full_name                                            AS donor,
       blood_type                                           AS type,
       district,
       CASE WHEN distance_km IS NULL THEN 'no GPS'
            ELSE round(distance_km::numeric, 1) || ' km' END AS distance,
       CASE
           WHEN NOT compatible
               THEN 'no — ' || blood_type || ' cannot give to ' || :'patient_type'
           WHEN NOT is_available
               THEN 'no — donor is marked unavailable'
           WHEN last_donation_date > current_date - 56
               THEN 'no — in cooldown until '
                    || to_char(last_donation_date + 56, 'YYYY-MM-DD')
           WHEN distance_km IS NOT NULL AND distance_km > 10
               THEN 'no — outside the 10 km radius'
           WHEN fcm_token IS NULL
               THEN 'matched, but SILENT — this donor has no FCM token registered'
           ELSE 'MATCH — the alert fires'
       END                                                  AS verdict
FROM donor
ORDER BY (CASE
              WHEN NOT compatible THEN 3
              WHEN NOT is_available THEN 3
              WHEN last_donation_date > current_date - 56 THEN 3
              WHEN distance_km IS NOT NULL AND distance_km > 10 THEN 3
              WHEN fcm_token IS NULL THEN 2
              ELSE 1
          END),
         distance_km NULLS LAST,
         full_name;
