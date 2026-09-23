-- LifeLink KH — take the known password out of the repository.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- V13/V14/V15 seeded portal passwords and V16 unified them, so since 6 September every one of
-- the four portal accounts — including the ADMIN that can grant portal access and confirm
-- donations — has been openable by anyone who can read this repository. docs/scope.md carried
-- that as a debt with an expiry: before this app holds one real donor's record.
--
-- This migration is the expiry arriving. It replaces each seeded digest with a BCrypt hash of a
-- random value generated inside the database, which no one has ever seen and nobody holds. The
-- rows keep a syntactically valid hash (users_password_pair_check requires one next to a
-- username) and become impossible to sign in to.
--
-- The passwords now come from the environment instead: PortalPasswordBootstrap reads
-- PORTAL_ADMIN_PASSWORD and PORTAL_STAFF_PASSWORD at startup and writes the digests. A fresh
-- `docker compose up` with neither variable set produces a portal nobody can sign in to, which
-- is the correct failure: an unreachable portal is a smaller problem than a public admin.
--
-- The WHERE clause matches only the four V16 digests on purpose. An environment where someone
-- already rotated a password by hand (docs/demo-runbook.md section 9's UPDATE) keeps what they
-- set; this only takes away the credential that shipped in the repository.

UPDATE users
SET password_hash = crypt(gen_random_uuid()::text || gen_random_uuid()::text, gen_salt('bf', 10))
WHERE username IN ('soborey', 'calmette', 'tepi', 'july')
  AND password_hash IN (
      '$2a$10$CHysYN0OLfEHlX0gCZOLMueylnz9636ifITflt0XaGR12ueSvKtQO',  -- soborey, V16
      '$2a$10$bwoF0RI62hp/xKCcrcPn4.CfYkkbJeddoLHpOojKGKaiL4qy84lUi',  -- calmette, V16
      '$2a$10$A3nmX4gU2esYsiMoRXpxyOgvVmMTRiePZB40QvUdcM3yLasXeQcBO',  -- tepi, V16
      '$2a$10$kdTruDEwKBrXp6Q/.X39QOVPkf7tzgVhERxmfwsrizd2Q65/hw9fq'   -- july, V16
  );

COMMENT ON COLUMN users.password_hash IS
    'BCrypt digest, never the password. Set from the environment at startup (PortalPasswordBootstrap) or by an ADMIN action; never seeded with a known value, never echoed by any endpoint, never logged.';
