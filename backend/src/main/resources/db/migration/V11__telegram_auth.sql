-- Telegram sign-in (FR-AUTH-004, TM-AUTH-002) — a second front door alongside Google, donors only.
-- Spec: docs/security/threat-models/TM-AUTH-002-telegram-sign-in.md
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.

-- The credential for a Telegram-authenticated account — analogous to firebase_uid for Google.
-- NULL for every other account. Written only from an already-verified webhook call
-- (TM-AUTH-002 S2), never from a client-supplied value.
ALTER TABLE users ADD COLUMN telegram_chat_id BIGINT UNIQUE;

COMMENT ON COLUMN users.telegram_chat_id IS
    'Telegram chat id — the Telegram equivalent of firebase_uid. NULL for every Google-authenticated account.';

-- `firebase_uid NOT NULL` assumed exactly one identity provider would ever exist. A
-- Telegram-only account has no Google identity at all, so the column has to become nullable —
-- the same shape phone already has (nullable, UNIQUE, which permits any number of NULLs in
-- PostgreSQL). The CHECK below is what stops that relaxation from producing an account with
-- *no* credential at all.
ALTER TABLE users ALTER COLUMN firebase_uid DROP NOT NULL;

ALTER TABLE users ADD CONSTRAINT users_has_a_credential_check
    CHECK (firebase_uid IS NOT NULL OR telegram_chat_id IS NOT NULL);

-- One row per sign-in attempt, from the moment the app asks for a deep link until the code is
-- verified or the row is abandoned. Short-lived by design — nothing here is a durable record of
-- who signed in (that is `users`), only of one attempt in flight.
CREATE TABLE telegram_auth_challenges (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    session_token  VARCHAR(64)  NOT NULL UNIQUE,
    role           VARCHAR(16)  NOT NULL,
    chat_id        BIGINT       NULL,
    otp_hash       VARCHAR(64)  NULL,
    display_name   VARCHAR(120) NULL,
    attempt_count  SMALLINT     NOT NULL DEFAULT 0,
    otp_sent_at    TIMESTAMPTZ  NULL,
    expires_at     TIMESTAMPTZ  NULL,
    consumed_at    TIMESTAMPTZ  NULL,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT telegram_auth_challenges_role_check
        CHECK (role IN ('DONOR', 'REQUESTER'))
);

COMMENT ON COLUMN telegram_auth_challenges.session_token IS
    'Opaque, unguessable, generated server-side — never derived from anything client-supplied.';
COMMENT ON COLUMN telegram_auth_challenges.role IS
    'Validated against the self-service allow-list at creation (TM-AUTH-002 E1) — never re-validated or honoured for a returning chat_id.';
COMMENT ON COLUMN telegram_auth_challenges.chat_id IS
    'Written only once, from a webhook call whose secret-token header has already been verified (TM-AUTH-002 S1/S2).';
COMMENT ON COLUMN telegram_auth_challenges.otp_hash IS
    'SHA-256 of the 6-digit code, never the code itself. Compared with MessageDigest.isEqual, never String.equals (TM-AUTH-002 T1).';
COMMENT ON COLUMN telegram_auth_challenges.display_name IS
    'From the webhook message''s from.first_name, carried here until verify() applies it to the user row — the same field Google sign-in refreshes on every sign-in, never email or phone.';
COMMENT ON COLUMN telegram_auth_challenges.attempt_count IS
    'Caps brute force independent of any per-IP rate limiter (TM-AUTH-002 S3) — this must hold even from one IP the limiter already let through.';

CREATE INDEX idx_telegram_auth_challenges_session_token ON telegram_auth_challenges (session_token);

-- Evicted by a scheduled job, same shape as FixedWindowLimiter's own eviction — a stale challenge
-- row is not sensitive enough to need synchronous cleanup, only eventual.
CREATE INDEX idx_telegram_auth_challenges_created_at ON telegram_auth_challenges (created_at);
