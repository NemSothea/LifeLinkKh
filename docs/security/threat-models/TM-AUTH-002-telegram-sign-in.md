---
id: TM-AUTH-002
feature: FR-AUTH-004-additional-sign-in-providers
date: 2026-08-23
author: Security (Tech Lead overlay)
adr_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Assets

Same as `TM-AUTH-001` (donor PII, user accounts, backend JWT signing key, role assignment), plus:

| Asset | Why it matters |
|---|---|
| Telegram bot token | Whoever holds it can send messages as the LifeLink bot to any chat — including OTP codes meant for someone else. |
| Webhook secret token | The only thing distinguishing a real Telegram update from anyone on the internet POSTing to the same URL. |
| A challenge's OTP code | A 6-digit code is the entire identity proof for the ~5 minutes it's valid. |

## Trust boundaries

```
[Flutter app]                     UNTRUSTED — starts a challenge, submits a code
        │  HTTPS: POST /auth/telegram/start, /verify
        ▼
[Spring Boot API]                 trusted, must treat every inbound claim as hostile
        ▲  HTTPS: POST /auth/telegram/webhook
        │
[Telegram Bot API servers]        trusted third party, but the webhook URL is public —
                                   anything can POST to it claiming to be Telegram
        │
[Telegram user's device]          proves control of the chat by reading the OTP and
                                   typing it back into the Flutter app — not into Telegram
```

The boundary Google's model doesn't have: **the webhook is a second unauthenticated inbound path**,
not just the app's own two calls. Google Sign-In only ever has the client asserting things to us;
here, anyone on the internet can also assert things to us *as if they were Telegram*, and that
channel is the one that decides who receives the OTP.

## Threats (STRIDE)

### S1 — Forged webhook call (Spoofing) — **critical**
The webhook URL is public. Without verification, anyone can `POST` a fabricated Telegram Update —
any `chat_id`, any `session_token` guessed or leaked — and the backend would mint and send a real OTP
to an attacker-controlled chat for someone else's in-flight sign-in attempt.

### S2 — Client-supplied `chat_id` (Spoofing) — **critical**
If any endpoint the *app* calls (`/start`, `/verify`) ever accepted a `chat_id` field instead of
deriving it solely from the webhook-established challenge row, a client could claim any Telegram
identity outright — the direct equivalent of Google's S1.

### S3 — OTP brute force (Spoofing) — **high**
A 6-digit code is a 1,000,000-value space. With no attempt cap and no expiry, it is trivially
guessable within the code's validity window.

### T1 — Timing attack on code comparison (Tampering) — **low**
A non-constant-time string comparison of the submitted code against the stored hash leaks timing
information proportional to matching prefix length.

### E1 — Client-chosen role (Elevation of privilege) — **critical**
Identical to `TM-AUTH-001` E1 — the same self-service allow-list (`DONOR`/`REQUESTER` only) must
apply at challenge creation, or the Google-only version of this rule would exist while a second
front door skips it entirely.

### I1 — OTP code or session token in logs (Information disclosure) — **medium**
The raw code, the session token, or the bot token itself, ending up in application logs, error
responses, or a crash report.

### D1 — Challenge flood / verify flood (Denial of service) — **medium**
Unlimited `/auth/telegram/start` calls create unlimited pending challenges (rows, and — if reached —
Telegram API sends); unlimited `/verify` calls against one challenge is `S3` restated as a resource
question.

## Mitigations

| ID | Mitigation | Where |
|---|---|---|
| S1 | Verify the `X-Telegram-Bot-Api-Secret-Token` header on every webhook call against
`lifelink.telegram.webhook-secret`, configured on Telegram's side via `setWebhook`'s `secret_token`
parameter. Any mismatch — including a missing header — is a 401 before the payload is even parsed. | `TelegramAuthController.webhook` |
| S2 | `chat_id` is written to a challenge row **only** from an already-authenticated webhook call (S1). No endpoint the app calls accepts a `chat_id`, ever. | `TelegramAuthService` |
| S3 | 6 attempts per challenge, tracked in the row itself (`attempt_count`), independent of any per-IP limiter — the cap must hold even from a single IP the rate limiter has already let through. 5-minute expiry from the moment the code is sent, not from when the challenge was created. | `V11__telegram_auth.sql`, `TelegramAuthService.verify` |
| T1 | `MessageDigest.isEqual` (constant-time) on the SHA-256 hash, never `String.equals` on the raw code. | `TelegramAuthService` |
| E1 | Same server-side allow-list as `TM-AUTH-001` E1 — self-service may only request `DONOR` or `REQUESTER`; enforced at `/start`, ignored (not honoured, not rejected) for a returning `chat_id`. | `TelegramAuthService.start` |
| I1 | Logs carry the internal user UUID and challenge UUID only — never the code, the session token, or the bot token. Same rule as `TM-AUTH-001` I2. | `TelegramAuthService` |
| D1 | `/start` and `/verify` are both rate-limited per IP via the same `FixedWindowLimiter` primitive `SignInRateLimiter` already uses, as separate instances with their own allowance. A resend (a repeat `/start` deep-link open for an unconsumed challenge) is additionally cooled down at the row level so one impatient user can't cause a flood of real Telegram API sends. | `TelegramAuthController`, `TelegramAuthService` |

## Residual risk

- **The bot token and webhook secret are both single points of compromise.** Either leaking lets an
  attacker impersonate the bot or the webhook caller respectively. Same class of risk as the JWT
  signing key in `TM-AUTH-001` — mitigated by keeping both out of committed files, same as every
  other secret in this project (`.env`, never `.env.example`).
- **Telegram account compromise equals app account compromise.** Inherent to delegated identity via
  a chat the user controls — the same trade `TM-AUTH-001` already accepts for Google. Telegram's own
  2FA is the control; this project adds none.
- **A donor who deletes Telegram, or blocks the bot, loses their only credential** the same way a
  Google account deletion would — no recovery flow exists for either provider.
