-- A donor's answer can now be queued on the device and replayed. The server has to be able to
-- recognise a reply it has already applied — FR-REQUEST-002, offline-first.
-- Spec: docs/mobile/local-db-and-sync.md ("Sync strategy, per entity")
-- Never edited after merge. A mistake here is fixed by a new V<n> migration.
--
-- The mobile app writes an accept or decline to SQLite first and sends it when it has signal
-- (commit 997eafc). Sending is not the risky part; retrying is. If the POST reaches the server,
-- the server commits, and the response is lost on the way back — a dropped connection, a timeout,
-- the phone leaving signal between request and reply — the queued write is still on the device and
-- the sync engine sends it again. Without a key to recognise, that second arrival is
-- indistinguishable from a donor answering twice, and today it would answer 409 ALREADY_RESPONDED
-- to a donor who did nothing wrong and whose acceptance DID land. The donor's app would then clear
-- the pending badge with an error, and a hospital counting on them would never learn they accepted.
--
-- The client generates the key once, when it queues the write, and replays it unchanged on every
-- retry (MatchSyncDao.saveLocalResponse). So: same key on the same match means "this is the reply I
-- already sent", and the server returns the answer it stored rather than recording a second one.
--
-- Nullable because every response predating this migration has no key, and because a client with a
-- live connection has nothing to replay — it sends no key and gets the ordinary path.
ALTER TABLE request_matches
    ADD COLUMN idempotency_key VARCHAR(64);

-- Scoped to the match, not global: the key only has to distinguish this donor's replies to this
-- match from each other, and a device generates it locally with no coordination. Two devices
-- producing the same 16 random bytes for two different matches is not a collision worth a global
-- constraint.
--
-- Partial, because NULL is the normal state: every match that has not been answered, and every
-- answer that arrived over a live connection, leaves this column empty, and a plain UNIQUE index
-- would still index all of them.
CREATE UNIQUE INDEX ux_request_matches_idempotency
    ON request_matches (id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;

COMMENT ON COLUMN request_matches.idempotency_key IS
    'Client-generated key for a queued offline response, replayed on every retry. NULL for a '
    'response sent over a live connection. See docs/mobile/local-db-and-sync.md.';
