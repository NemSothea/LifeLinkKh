-- Who the donor calls after accepting.
-- Spec: docs/fullstack/specs/features/request-and-matching.md · CR-MAPI-003
--
-- RequesterContact in the mobile contract requires a displayName and a phone, and at M3 nothing
-- could produce either: the display name arrives inside the Google ID token and is never stored,
-- and the phone field was dropped from sign-up when auth moved to Google Sign-In (ADR 0002).
-- A donor who accepted would have been shown an empty contact card — the one screen the whole
-- accept flow exists to reach.
--
-- The contact belongs to the REQUEST, not to the account, and that is the better answer anyway:
-- the person posting may be posting for someone else, and the number that matters is the one
-- answering at the hospital tonight, not the one attached to a Google login.
--
-- NOT NULL with no default. blood_requests is empty — M4 is the first code that writes it — so
-- there is no existing row to back-fill and a default would only let a future insert omit the
-- one field the accept flow depends on.

ALTER TABLE blood_requests ADD COLUMN contact_name  VARCHAR(120) NOT NULL;
ALTER TABLE blood_requests ADD COLUMN contact_phone VARCHAR(20)  NOT NULL;

COMMENT ON COLUMN blood_requests.contact_name IS 'Shown to a donor only after their match response is ACCEPTED (TM-AUTH-001 I1).';
COMMENT ON COLUMN blood_requests.contact_phone IS 'UNVERIFIED — nothing verifies phone numbers in this build (ADR 0002). Revealed only after acceptance.';
