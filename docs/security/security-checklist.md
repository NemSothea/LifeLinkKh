# Security Checklist (seeded from in-scope R5 triggers)

## auth
- [ ] Google ID token verified **server-side** — signature, `aud`, `iss`, expiry. A client-supplied
      user identifier is never trusted: that is an authentication bypass.
- [ ] Sign-in endpoint rate-limited; replay of a used ID token rejected.
- [ ] JWT signed, short-lived, refresh handled; logout invalidates.
- [ ] RBAC enforced server-side on every endpoint (donor/requester/hospital/admin).

## PII (phone, location, blood type/health)
- [ ] PII encrypted in transit (TLS) and access-controlled.
- [ ] Donor contact revealed only after the donor accepts a request.
- [ ] Data retention + deletion honored (see PRD §6).

## secrets (Firebase Auth + FCM, Maps keys)
- [ ] No secrets in git; loaded via env / secret store.
- [ ] CI secrets scoped; rotated on exposure.

## external integrations (Firebase Auth, FCM, Google Maps)
- [ ] Validate + rate-limit inbound webhooks/callbacks.
- [ ] Handle provider failure gracefully; no PII leaked in logs.

- [ ] Self-service sign-up cannot produce `HOSPITAL` or `ADMIN` — rejected, not downgraded.
- [ ] No donor endpoint returns `latitude`, `longitude`, or an unrounded distance (ADR 0003).

> Any change touching the above runs the R6 gate: threat model (threat-models/) +
> review note (reviews/) before merge.

Completed for auth: [`TM-AUTH-001`](threat-models/TM-AUTH-001-google-sign-in.md) +
[`SEC-REVIEW-001`](reviews/SEC-REVIEW-001-google-sign-in.md) (pass-with-conditions — conditions are
tracked on `FR-AUTH-003` and verified by `docs/qa/test-cases/TC-AUTH-001-google-sign-in-security.md`).
A second review is required against the M3 implementation.

Completed for Telegram sign-in (`FR-AUTH-004`):
[`TM-AUTH-002`](threat-models/TM-AUTH-002-telegram-sign-in.md) +
[`SEC-REVIEW-002`](reviews/SEC-REVIEW-002-telegram-sign-in.md) (pass-with-conditions — the "validate
+ rate-limit inbound webhooks" row above is this feature's whole reason for existing: the webhook
secret-token check is `TM-AUTH-002` S1). No QA test case exists yet for this one — `FR-AUTH-004` has
no real bot to test against until Sothea's `@BotFather` step lands; `SEC-REVIEW-003` covers the
re-review once it does.
