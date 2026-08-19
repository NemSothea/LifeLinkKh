-- The distance that ranked this donor, kept.
-- Spec: docs/fullstack/specs/features/request-and-matching.md
--
-- The mobile contract puts distanceKm on the request inside a donor's match (Match.request), so
-- GET /matches/me has to answer it. There were two ways: recompute from the donor's current
-- coordinates on every read, or store what was computed at match time.
--
-- Stored, because recomputing answers a different question. Distance is a fact ABOUT THE MATCH —
-- how far away this donor was when they were chosen. A donor who has since driven across the city
-- would see their alert list re-rank itself under them, and the ordering they were notified in
-- would no longer be reconstructible for the pilot's own metrics.
--
-- NUMERIC(4,1) holds 0.0 to 999.9 in 0.5 steps, which is the rounded form ADR 0003 mandates and
-- far more range than a 10 km radius needs. Nullable: a donor with no coordinates matches anyway
-- and has no distance, which is the same NULL that sorts them last in the matching query.

ALTER TABLE request_matches ADD COLUMN distance_km NUMERIC(4,1) NULL;

COMMENT ON COLUMN request_matches.distance_km IS 'Rounded to 0.5 km at match time (ADR 0003). NULL when the donor had no coordinates. Never recomputed.';
