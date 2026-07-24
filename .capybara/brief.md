# Project Brief — LifeLink KH (ជីវិត)

## Idea
A blood-donor matching app for Cambodia. It connects patients/families who urgently
need blood with nearby eligible voluntary donors, replacing the ad-hoc Facebook-post
approach hospitals use today. A Flutter mobile app serves donors and requesters; a
Next.js web portal serves hospitals and administrators. One Spring Boot + PostgreSQL
backend powers both. Core problem: blood emergencies have no fast, systematic way to
reach matching nearby donors.

## Stack
Spring Boot (backend) · Next.js (web) · Flutter (mobile) · PostgreSQL · Docker.

## Mobile model (R3)
Flutter — native Android build for Play Store internal testing (course M7).

## Feature areas (R7)
- AUTH — phone OTP auth, sessions, RBAC
- DONOR — donor profile, eligibility, availability
- REQUEST — urgent blood requests
- MATCH — donor matching (ABO/Rh compatibility + distance)
- DONATION — donation history, hospital confirmation
- NOTIFY — FCM push, eligibility reminders
- PORTAL — hospital + admin web portal

## Sensitivity (R5)
auth, PII, secrets, external integrations. Security = overlay on Tech Lead.

## Deploy
In scope. CI: GitHub Actions. DB schema: Flyway app migrations.

## Naming conventions to preserve
None special. Casing per R8 (lowercase-hyphen meta docs; uppercase CLAUDE/README/ONBOARDING).

## Course context
Track B team product, Cross-Platform Mobile App Development (16 weeks). Team of 5.
M7 = published to Play Store internal testing by Week 15. See root CLAUDE.md.
