---
id: FR-AUTH-004-additional-sign-in-providers
title: Facebook and Telegram sign-in for donors
area: AUTH
status: accepted
priority: Must Have
owner: PO
brief_ref: ../../tech-lead/adr/0002-auth-google-sign-in.md
---

## Problem
Google Sign-In is the only way in. ADR 0002 named Telegram as the fallback "if Google Sign-In proves
unacceptable for donor sign-up," and left that as an open question rather than a build item. Facebook
was never evaluated at all. Google-only is a real sign-up barrier for this donor population — Facebook
and Telegram both see more everyday use in Cambodia than Google does.

## Desired outcome
A donor who does not want to use a Google account can sign up with Facebook or through a Telegram
bot instead, and reach the same `DONOR`/`REQUESTER` account shape everything else in the app already
expects — this adds identity-proof options, it does not change what an account is.

## Why
Coverage that matters now, not a nice-to-have — see `changelog.md` 2026-08-23. First written and
deferred to post-M7 the same day, then reversed: the reach argument (most of the target donor
population signs in with Facebook or Telegram day to day) outweighs the M7 scheduling risk, which
still exists and is managed by splitting the work below rather than by waiting it out.

### The M7 conflict, and how it's split
Two unrelated pieces of work hiding under one request, neither of which is small:

- **Facebook Login** needs a Meta Developer App and, depending on the permissions requested, Meta's
  own App Review — a timeline this team does not control, from days to weeks.
- **Telegram** is not OAuth here — Telegram has no "Sign in with Telegram" for this shape of app.
  Per ADR 0002 it means a **bot-driven OTP**: generate a code, send it via the bot, verify what the
  donor types back. That is the full code-generation / expiry / rate-limiting / brute-force path ADR
  0002 chose Google Sign-In specifically to avoid — free, but not smaller.

So the work is sequenced, not raced against M7:

1. **Now, account-level, no code, Sothea's own action:** register the Meta Developer App and submit
   for App Review; create the Telegram bot via @BotFather. Starting the external clock costs nothing
   and blocks nothing.
2. **After step 1 has something to integrate against:** the actual client/backend work below,
   sequenced around M7 rather than squeezed in before it.

## Scope
**In:**
- Facebook: **no new backend verifier** — Firebase Auth handles Facebook as a federated provider
  natively, so the existing Firebase ID token verification (`GoogleTokenVerifier`) already covers a
  Facebook-authenticated user once Facebook is enabled as a sign-in method in the Firebase console.
  Mobile-only work: `flutter_facebook_auth`, exchanging its credential for a Firebase credential, a
  second sign-in button.
- Telegram: `TM-AUTH-002`, built 2026-08-23 — `V11__telegram_auth.sql`, `TelegramAuthService`
  (start/webhook/verify), OTP generation, expiry, resend cooldown, and rate-limiting (`FR-AUTH-002`'s
  retired scope, reintroduced for this one path only), behind a `TelegramBotClient` seam so the
  backend was buildable and testable before a real bot existed. `SEC-REVIEW-002`: pass-with-conditions.
- A threat model per new provider, mirroring `TM-AUTH-001`'s shape — S1/S2 (client-asserted
  identity, audience/issuer checks) do not automatically carry over from Google's.

**Out:**
- Extending either provider to `HOSPITAL`/`ADMIN` sign-in — donors only, per the request.
- Any code landing in a way that jeopardizes M7 (Play Store release) — if the two conflict, M7 wins
  and this slips, not the reverse.

## Acceptance criteria
- [x] Meta Developer App created, Facebook Login product added (App ID `1538785524224504`).
      Development mode, default permissions (`public_profile`, `email`) only — App Review not
      required at this permission level. Going **Live** for real donors needs Meta Business
      Verification on top of App Review; not filed yet, budget for it separately (Sothea).
- [x] Telegram bot created via @BotFather — `@LifeLinkKHbot`. `setWebhook` **not yet called**:
      needs a public HTTPS URL, backend is local-only right now. `TELEGRAM_WEBHOOK_SECRET`
      generated and in `.env`, ready to register once a URL exists — `SEC-REVIEW-002` condition 1
      still open.
- [x] Facebook enabled as a sign-in provider in the Firebase console using the Meta App's ID/Secret
      — no separate backend verifier needed (see Scope). Redirect URI confirmed
      (`https://lifelinkkh.firebaseapp.com/__/auth/handler`), toggle-on saved (Sothea, 2026-08-25).
- [x] Telegram OTP path has expiry, a resend cooldown, and rate-limiting before it ships — not
      after (this is exactly the surface `FR-AUTH-002` existed for). `V11__telegram_auth.sql`,
      `TelegramAuthService`, 19 tests (`TelegramAuthServiceTest` + `TelegramAuthControllerTest`).
- [x] Telegram produces only `DONOR`/`REQUESTER` accounts, same allow-list rule as Google
      (TM-AUTH-001 E1, mirrored as TM-AUTH-002 E1).
- [x] Facebook mobile wiring landed: `flutter_facebook_auth`, `FacebookCredentials` /
      `FirebaseFacebookCredentials` (mirrors `GoogleCredentials`, reuses its Firebase-session
      `idToken`/`signOut` — only interactive sign-in differs per provider), second button on
      `SignInScreen` (`sign-in-facebook`), Android manifest/strings wired to the Meta App ID.
      `flutter analyze` clean, full `flutter test` green (139 tests, 6 new). Not yet run on a
      device — no real Facebook-authenticated login exercised.
- [ ] Facebook produces only `DONOR`/`REQUESTER` accounts — inherits Google's existing E1 control
      once wired up, but not yet confirmed against a real Facebook-authenticated Firebase user.
- [x] Telegram mobile wiring landed: `TelegramAuthRepository`/`DioTelegramAuthRepository` (start +
      verify, no bearer token, same as `AuthRepository`), `TelegramStartController` (deep link) and
      `TelegramVerifyController` (code entry) as separate autoDispose controllers so a wrong code
      doesn't discard the fetched deep link and doesn't leak an error onto `SignInScreen` behind the
      sheet — `AuthController` only learns of the session via `applyTelegramSession`, on success.
      Third button on `SignInScreen` (`sign-in-telegram`) opens `TelegramSignInSheet` (deep-link
      button + 6-digit code field), `url_launcher` for the `t.me` link. `flutter analyze` clean,
      full `flutter test` green (145 tests, 6 new). Not yet run on a device — no real Telegram bot
      round-trip exercised (`setWebhook` still not registered, see below).
- [ ] `SEC-REVIEW-003` — re-review once a real Telegram bot exists (`SEC-REVIEW-002` condition 2).
      The bot itself exists now (`@LifeLinkKHbot`); this still waits on `setWebhook`, which waits on
      a public HTTPS URL (held per Sothea's 2026-08-25 call).
