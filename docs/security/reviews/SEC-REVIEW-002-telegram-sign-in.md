---
id: SEC-REVIEW-002
feature: FR-AUTH-004-additional-sign-in-providers
date: 2026-08-23
verdict: pass-with-conditions
reviewer: Security (Tech Lead overlay)
threat_model: ../threat-models/TM-AUTH-002-telegram-sign-in.md
---

## Scope reviewed

The Telegram OTP backend — everything buildable before the real bot exists (`FR-AUTH-004`'s own
split): migration `V11__telegram_auth.sql`, `TelegramConfig`, `TelegramAuthChallenge`/repository,
`TelegramAuthService`, `TelegramAuthController`, `TelegramRateLimiter`, `HttpTelegramBotClient`,
`TM-AUTH-002`, and `TelegramAuthServiceTest` (13 cases, `TelegramBotClient` faked).

**Not reviewed, because it doesn't exist yet:** a real bot token, a real webhook registered with
Telegram, and therefore an end-to-end run of `HttpTelegramBotClient` against the real Telegram Bot
API. `SEC-REVIEW-003` covers that once the bot exists.

## Findings

**F1 — S1 (forged webhook) is closed the way the threat model requires.** `TelegramAuthController
.webhook` checks `X-Telegram-Bot-Api-Secret-Token` via `TelegramConfig.verifyWebhookSecret`
(constant-time, `MessageDigest.isEqual`) before touching the body at all, and returns 401 on any
mismatch including a missing header. **Resolved during this review**: added
`TelegramAuthControllerTest` (6 cases) proving this at the HTTP layer — a missing header, a wrong
header, and a genuine call are all asserted, plus that `start`/`verify` are reachable unauthenticated
and rate-limited.

**F2 — S2 (client-supplied chat_id) does not exist as a code path.** No DTO the app calls
(`TelegramStartRequest`, `TelegramVerifyRequest`) has a `chat_id` field. `chatId` is written to a
challenge exactly once, inside `recordOtpSent`, called only from the webhook handler. Confirmed by
reading every write site — there is only one.

**F3 — S3 (OTP brute force) has two independent controls, correctly independent of each other.**
The per-challenge `attempt_count` cap (6) is a database column checked in `verify()` regardless of
caller IP; `TelegramRateLimiter`'s per-IP window is a separate, unrelated allowance. Tested:
`verify_locks_out_after_six_wrong_attempts`. One gap: the rate limiter's own numbers
(10 starts/10 min, 20 verifies/10 min) are not derived from anything — they're the same order of
magnitude as `SignInRateLimiter`'s defaults, chosen by analogy, not by a modelled attack cost.
**Non-blocking** — revisit if a real bot ever shows abuse.

**F4 — T1 (timing attack) is closed.** `MessageDigest.isEqual` on the SHA-256 hex digest, not
`String.equals`. Same pattern the webhook secret check uses (F1).

**F5 — E1 (client-chosen role) mirrors `TM-AUTH-001` exactly.** `SELF_SERVICE_ROLES = {DONOR,
REQUESTER}`, checked in `start()`, ignored (not re-validated, not rejected) for a returning
`chat_id` in `verify()`. Tested: `start_rejects_a_non_self_service_role`,
`verify_ignores_the_challenge_role_for_a_returning_chat_id`.

**F6 — I1 (secrets in logs) holds under inspection.** `TelegramAuthService` logs the internal user
UUID and an outcome string only. `HttpTelegramBotClient` logs an HTTP status code on failure,
explicitly never the response body — the comment there is correct that Telegram echoes the request
on some 4xx responses, which would otherwise put the OTP text in the log. No log line in either
class references `code`, `otpHash`, `sessionToken`, or the bot token.

**F7 — schema change is bigger than the feature name suggests, and it's correct.** Adding Telegram
as a credential required relaxing `users.firebase_uid` from `NOT NULL` to nullable — a
Google-only assumption baked into the original schema. `users_has_a_credential_check` (`firebase_uid
IS NOT NULL OR telegram_chat_id IS NOT NULL`) is the right replacement invariant: it was verified
this CHECK constraint, not application code, is what would reject an account with neither.

**F8 — the resend cooldown is real, not cosmetic.** `recordOtpSent` is a no-op inside the cooldown
window (`otpSentAt` within 30s), meaning a second `/start` deep-link open by an impatient user
costs nothing — confirmed both directions:
`recordOtpSent_respects_the_resend_cooldown` and `recordOtpSent_resends_once_the_cooldown_has_passed`.

## Verdict & conditions

**pass-with-conditions.** The design closes every threat `TM-AUTH-002` names as critical or high,
and the test suite exercises the security-relevant branches directly rather than only the happy
path, at both the service and HTTP layers. Conditions, none blocking this stage but both before
`SEC-REVIEW-003`:

1. Once a real bot token exists: confirm `HttpTelegramBotClient` actually gets a 200 from Telegram
   for a real `sendMessage` call, and confirm `setWebhook`'s `secret_token` parameter was actually
   set to the same value `TELEGRAM_WEBHOOK_SECRET` holds — a mismatch here fails closed (every
   webhook call gets 401) rather than open, but it would look like "Telegram sign-in is broken,"
   not like a security finding, so it is worth checking explicitly rather than discovering it from
   a support complaint.
2. `SEC-REVIEW-003` re-reviews against the real bot, per `TM-AUTH-002`'s own scope note.
