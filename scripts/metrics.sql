-- LifeLink KH — the five PRD success metrics, straight out of the database.
--
-- Source of the targets: docs/po/prd.md section 1 ("Success Metrics").
-- Why this file exists: DEC-003 was withdrawn by DEC-004, which cut per-milestone event
-- instrumentation (FR-GLOBAL-002) and promised these numbers would come from SQL at demo
-- time instead. docs/risks.md line 102 carries the consequence: without this file the
-- defense has five targets and no way to say a single real number against them.
--
-- Run it against the demo stack:
--
--   docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/metrics.sql
--
-- Read the `sample` column before quoting any percentage out loud. Three requests where two
-- were accepted inside an hour is 67%, and it means nothing. The honest sentence at a defense
-- is "the query is real, the pilot data is not yet" — not a percentage with no denominator.

\pset border 2
\pset null '—'

WITH
-- Every district in `districts` is a Phnom Penh khan (V2's table comment), so a donor row IS
-- a Phnom Penh donor. No province filter exists because no province column does.
donors AS (
    SELECT
        count(*)                                                              AS total,
        min(created_at)                                                       AS first_seen,
        count(*) FILTER (
            WHERE created_at < (SELECT min(created_at) FROM donor_profiles) + interval '1 month'
        )                                                                     AS first_month
    FROM donor_profiles
),

-- One row per request, carrying the first ACCEPTED response it ever got. LEFT JOIN on purpose:
-- a request nobody accepted still counts in the denominator, which is the whole point of
-- metric 2. FR-MATCH-002 (retry with a wider radius) is deferred, so those rows stay unaccepted.
--
-- CANCELLED and EXPIRED requests are excluded, and this is a methodology choice worth being able
-- to defend out loud: the metric asks how often a live need reaches a donor. A requester who
-- withdrew their own request was never waiting for an acceptance, and counting it as a failure
-- measures rehearsal habits rather than the product. The count excluded is printed in metric 2's
-- note so the exclusion is never silent.
request_acceptance AS (
    SELECT
        r.id,
        r.created_at,
        min(m.responded_at) FILTER (WHERE m.response = 'ACCEPTED') AS first_accepted_at
    FROM blood_requests r
    LEFT JOIN request_matches m ON m.blood_request_id = r.id
    WHERE r.status NOT IN ('CANCELLED', 'EXPIRED')
    GROUP BY r.id, r.created_at
),

excluded AS (
    SELECT count(*) AS cancelled_or_expired
    FROM blood_requests
    WHERE status IN ('CANCELLED', 'EXPIRED')
),

acceptance AS (
    SELECT
        count(*)                                                                  AS requests,
        count(*) FILTER (
            WHERE first_accepted_at IS NOT NULL
              AND first_accepted_at <= created_at + interval '60 minutes'
        )                                                                         AS within_hour,
        count(*) FILTER (WHERE first_accepted_at IS NOT NULL)                     AS ever_accepted,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY extract(epoch FROM (first_accepted_at - created_at)) / 60.0
        ) FILTER (WHERE first_accepted_at IS NOT NULL)                            AS median_minutes
    FROM request_acceptance
),

-- "Hospital-verified" is confirmed_by_user_id, not the row existing. A donation row with no
-- confirming user is a self-report, and FR-DONATION-001 deliberately does not trust one.
donations_confirmed AS (
    SELECT
        count(*)                                              AS rows_total,
        count(*) FILTER (WHERE confirmed_by_user_id IS NOT NULL) AS verified
    FROM donations
),

-- request_matches.notified_at is set when the FCM send SUCCEEDS (V1 column comment) — that is
-- "Firebase accepted it", not "the phone showed it". True delivery rate lives in Firebase's own
-- reporting, not in this database. Say that out loud rather than presenting this as delivery.
push AS (
    SELECT
        count(*)                                          AS matches,
        count(*) FILTER (WHERE notified_at IS NOT NULL)   AS notified
    FROM request_matches
)

SELECT * FROM (
    SELECT 1 AS n,
           'Registered donors (Phnom Penh)'                    AS metric,
           '>= 200 in first month'                             AS target,
           to_char(first_month, 'FM999990') || ' in first month'
             || ' · ' || to_char(total, 'FM999990') || ' all time'  AS actual,
           to_char(total, 'FM999990') || ' donor rows'          AS sample,
           CASE WHEN first_seen IS NULL THEN 'no donors registered yet'
                ELSE 'pilot clock starts at the first donor row: '
                     || to_char(first_seen, 'YYYY-MM-DD') END   AS note
    FROM donors

    UNION ALL
    SELECT 2,
           'Requests accepted within 60 min',
           '>= 70%',
           CASE WHEN requests = 0 THEN NULL
                ELSE to_char(100.0 * within_hour / requests, 'FM990.0') || '%' END,
           to_char(within_hour, 'FM999990') || ' of ' || to_char(requests, 'FM999990') || ' requests',
           to_char(ever_accepted, 'FM999990') || ' accepted at any point · '
             || to_char((SELECT cancelled_or_expired FROM excluded), 'FM999990')
             || ' cancelled/expired requests excluded from both'
    FROM acceptance

    UNION ALL
    SELECT 3,
           'Median time to first acceptance',
           '< 30 minutes',
           CASE WHEN median_minutes IS NULL THEN NULL
                ELSE to_char(median_minutes, 'FM999990.0') || ' min' END,
           to_char(ever_accepted, 'FM999990') || ' accepted requests',
           'median over accepted requests only — requests nobody answered cannot have a time'
    FROM acceptance

    UNION ALL
    SELECT 4,
           'Hospital-verified donations',
           '>= 50 in the pilot',
           to_char(verified, 'FM999990'),
           to_char(verified, 'FM999990') || ' of ' || to_char(rows_total, 'FM999990') || ' donation rows',
           'verified = confirmed_by_user_id is set; an unconfirmed row is a self-report'
    FROM donations_confirmed

    UNION ALL
    SELECT 5,
           'Push send-success rate',
           '>= 95%',
           CASE WHEN matches = 0 THEN NULL
                ELSE to_char(100.0 * notified / matches, 'FM990.0') || '%' END,
           to_char(notified, 'FM999990') || ' of ' || to_char(matches, 'FM999990') || ' matches',
           'FCM accepted the send — NOT proof the device displayed it; true delivery is Firebase''s report'
    FROM push
) AS metrics
ORDER BY n;
