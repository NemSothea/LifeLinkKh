-- Admin-driven staff provisioning (TM-AUTH-001 E1) — an ADMIN promotes an existing DONOR/REQUESTER
-- account to HOSPITAL/ADMIN through the app, replacing V8's hand-run migration as the only way in.
-- Spec: docs/fullstack/api-contract/web/contract.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.

-- The identifier an ADMIN uses to find the right account in a list of otherwise-anonymous rows.
-- From the verified Google ID token's display name (GoogleTokenVerifier.VerifiedIdentity),
-- captured at every sign-in. Not email, not phone — GoogleTokenVerifier's own comment already
-- flags email as an unnecessary breach asset for this system, and a display name serves the one
-- purpose this needs (telling two people apart in a list) without that cost.
ALTER TABLE users ADD COLUMN display_name VARCHAR(120) NULL;

COMMENT ON COLUMN users.display_name IS
    'From the verified Google ID token, refreshed on every sign-in. NULL for any account created before this column existed, until that person signs in again.';
