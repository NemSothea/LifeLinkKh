---
id: 0001-stack-and-architecture
title: Stack & architecture
status: accepted
date: 2026-07-24
deciders: Tech Lead
---
## Context
LifeLink KH must ship a Play Store Android app (course M7) plus a web portal for
hospitals/admin, backed by one API. Team of 5 with backend, frontend, mobile, QA (no infra role as of 2026-08-07 — see docs/team.md).

## Decision
- Backend: Spring Boot + PostgreSQL, schema via Flyway migrations.
- Web portal: Next.js (App Router, TypeScript, Tailwind).
- Mobile: Flutter (native Android build → Play Store). No Capacitor/hybrid.
- Two clients share one REST API. ~~Auth: phone OTP → JWT sessions.~~ **Superseded by ADR 0002** —
  auth is Google Sign-In → JWT sessions. Everything else in this ADR stands.
- Local dev + backend/web/db via docker-compose. Push via FCM. Distance via Google Maps.

## Consequences
- Two frontends (Flutter + Next.js) increase surface but map cleanly to team roles.
- Flutter satisfies the native Play Store requirement directly.
- Shared API contract must stay in sync — governed via docs/fullstack/api-contract + CR-MAPI.

## Alternatives considered
- Capacitor R3 Hybrid (one Next.js codebase, wrapped): rejected — team chose native Flutter.
- Flutter-only, no web: rejected — hospitals/admin need a web portal.
- **Microservices, raised and rejected 2026-08-29.** Reasoning it out surfaced the actual reason
  this stays a monolith, so recorded here rather than only in chat: `PortalService.confirmDonation`
  is one transaction across three writes (record the donation, refresh the cooldown cache, close
  the request if fulfilled) specifically so it cannot partially fail. Split across services, that
  becomes a distributed saga with compensating rollbacks — strictly more to build and more ways to
  fail, not less. Combined with no DevOps role on the team (`docs/team.md`) and this being raised at
  M7 of a 13-week course project, the "easier to manage" premise doesn't hold at this scale. Revisit
  only if a real second deploy target or an independent-scaling need ever appears — neither exists
  today.
