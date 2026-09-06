-- LifeLink KH — one password for all four seeded portal accounts.
-- ERD: docs/tech-lead/data-model.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- V13/V14 seeded 'qwer12324!' and V15 seeded 'qwer1234!' — one stray digit apart, which is
-- exactly the kind of difference nobody notices until they are staring at "Wrong username
-- or password" for an account they know exists. It cost real time on 2026-09-06. All four
-- are now 'qwer1234!'.
--
-- Four separate digests for one password, on purpose. BCrypt salts per row, so identical
-- passwords must still produce different hashes; pasting one digest into all four rows
-- would throw that away and let a single crack open every account.
--
-- ⚠ STILL A DEVELOPMENT CREDENTIAL, and now a single one for the whole portal — which
-- makes rotating it before real use more important, not less. docs/demo-runbook.md
-- section 9 has the procedure. Nothing here changes the rule that this must happen before
-- this app holds one real donor's record (docs/scope.md, FR-SECURITY-001).

UPDATE users SET password_hash = '$2a$10$CHysYN0OLfEHlX0gCZOLMueylnz9636ifITflt0XaGR12ueSvKtQO'
WHERE username = 'soborey';

UPDATE users SET password_hash = '$2a$10$bwoF0RI62hp/xKCcrcPn4.CfYkkbJeddoLHpOojKGKaiL4qy84lUi'
WHERE username = 'calmette';

UPDATE users SET password_hash = '$2a$10$A3nmX4gU2esYsiMoRXpxyOgvVmMTRiePZB40QvUdcM3yLasXeQcBO'
WHERE username = 'tepi';

UPDATE users SET password_hash = '$2a$10$kdTruDEwKBrXp6Q/.X39QOVPkf7tzgVhERxmfwsrizd2Q65/hw9fq'
WHERE username = 'july';
