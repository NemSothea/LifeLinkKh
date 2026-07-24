# Capybara Setup — LifeLink KH

tier: full

## Stack (R3)
- Backend: Spring Boot + PostgreSQL (Flyway migrations)
- Web: Next.js (App Router, TypeScript, Tailwind)
- Mobile: Flutter

## Mobile model (R3)
flutter

## Acting user roles (R2) — Nem Sothea (solo driver this session)
- primary: Tech Lead
- also: Fullstack, Mobile, PO, QA, DevOps
- Security: overlay held by Tech Lead

> The full 5-person team org chart is in docs/team.md. Acting-user roles above
> govern the R2.1 write-scope gate for THIS Claude Code session.

## Security triggers in scope (R5)
- auth (phone OTP, JWT sessions, RBAC)
- PII (phone number, precise location, blood type = health data)
- secrets (FCM keys, SMS/OTP provider keys, Maps API key)
- external integrations (FCM, SMS OTP provider, Google Maps)

## Deploy
- in scope: yes
- CI platform: GitHub Actions
- DB schema ownership: app migrations (Flyway)

## Feature areas (R7)
AUTH, DONOR, REQUEST, MATCH, DONATION, NOTIFY, PORTAL, GLOBAL, SECURITY, MOBILE

## Stage checklist
- [x] init
- [ ] project   (PRD done; wireframes + thin FRs pending)
- [ ] plan
- [ ] dev
- [ ] review
- [ ] deploy
