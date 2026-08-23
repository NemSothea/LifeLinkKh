-- One donor cannot be confirmed twice against the same request (M5) — FR-PORTAL-001.
-- Spec: docs/fullstack/api-contract/web/contract.md ("Confirm a donation")
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- PortalService.confirmDonation guards this with a check-then-insert
-- (existsByDonorProfileIdAndBloodRequestId, then save) and nothing backed it at the database
-- level. Under read-committed isolation two confirm-donation calls for the same match arriving
-- close together — a double-click, a retried request, two staff tabs — can both pass the
-- existence check before either commits, producing two donations rows for one donor against one
-- request. That inflates the count confirm-donation uses to decide FULFILLED and shows the donor
-- a duplicate entry in their own history.
--
-- NULL blood_request_id is unaffected: Postgres treats each NULL as distinct for uniqueness
-- purposes, so a donor's separate walk-in donations (FR-08, no originating request) are never
-- blocked by this constraint — only a second confirmation against the same real request is.
ALTER TABLE donations
    ADD CONSTRAINT donations_donor_request_uniq UNIQUE (donor_profile_id, blood_request_id);
