# Security Checklist (seeded from in-scope R5 triggers)

## auth
- [ ] OTP rate-limited; expiry enforced; brute-force protected.
- [ ] JWT signed, short-lived, refresh handled; logout invalidates.
- [ ] RBAC enforced server-side on every endpoint (donor/requester/hospital/admin).

## PII (phone, location, blood type/health)
- [ ] PII encrypted in transit (TLS) and access-controlled.
- [ ] Donor contact revealed only after the donor accepts a request.
- [ ] Data retention + deletion honored (see PRD §6).

## secrets (FCM, SMS/OTP, Maps keys)
- [ ] No secrets in git; loaded via env / secret store.
- [ ] CI secrets scoped; rotated on exposure.

## external integrations (FCM, SMS, Google Maps)
- [ ] Validate + rate-limit inbound webhooks/callbacks.
- [ ] Handle provider failure gracefully; no PII leaked in logs.

> Any change touching the above runs the R6 gate: threat model (threat-models/) +
> review note (reviews/) before merge.
