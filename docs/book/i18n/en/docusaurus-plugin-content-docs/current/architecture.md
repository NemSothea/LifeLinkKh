---
title: Architecture
sidebar_position: 5
description: How LifeLink KH is built — Flutter app, Next.js portal on Vercel, one Firebase project on the free Spark plan.
---

# Architecture

LifeLink KH is **two clients and one Firebase project**, running at $0.

```text
            Firebase (lifelinkkh, asia-southeast1, Spark plan — no card)
     ┌──────────────────────────────────────────────┐
     │  Firestore + Security Rules   Firebase Auth  │
     │  Cloud Messaging (FCM)                       │
     └──────────────────────────────────────────────┘
          ▲  Firebase SDK (reads)     ▲  REST (admin) + Admin SDK (functions)
          │                           │
     Flutter app ──── POST /api/functions/{name} ────> Next.js portal, Vercel sin1
  (donors, requesters)  createRequest · respondToMatch   (public pages + admin +
     → APK               deleteAccount                    reviewRequest · confirmDonation)
```

| Layer | Technology | Source |
|---|---|---|
| Mobile | Flutter (Android; iOS build-only), Riverpod, go_router, cloud_firestore | `mobile/` |
| Web | Next.js App Router, TypeScript, Tailwind, shadcn/ui, next-intl | `frontend/` |
| Server logic | The portal's own Node server on Vercel Hobby (`frontend/src/server/`) | ADR 0010 |
| Data | Cloud Firestore + Security Rules, one emulator test per rule | `firebase/` |
| Identity | Firebase Auth: Google/Facebook in the app, Google or password for admins | ADR 0002, DEC-017 |
| Push | Firebase Cloud Messaging, in the donor's own language | — |
| Location | `geolocator`, no map widget | DEC-004, ADR 0003 |

## The rules that hold it together

- **Clients read Firebase directly; the Security Rules are the only gate.** Anything a client must
  not write goes through a function on the portal's server, and the rules refuse that write to
  every client.
- **Five functions** (`POST /api/functions/{name}` with the caller's Firebase ID token):
  - `createRequest` (app): writes a request as `PENDING`;
  - `reviewRequest` (admin): approve, which runs matching and push, or reject;
  - `respondToMatch` (app): a donor's accept or decline;
  - `confirmDonation` (admin): records the donation and starts the cooldown;
  - `deleteAccount` (self): removes personal data and keeps anonymous counts.
- **Matching** selects compatible, available, eligible donors within 10 km of the hospital, nearest
  first. ABO/Rh compatibility is a fixed lookup table, never user input (ADR 0004). Donors with no
  GPS still match by district.
- **Offline first:** the app reads through Firestore's offline cache, and a donor's answer is
  queued on the phone until it can be sent.

## Read further (in the repo)

- [README: architecture and data model](https://github.com/NemSothea/LifeLinkKh#architecture)
- [Firestore data model and the reason for each rule](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/docs/tech-lead/firestore-data-model.md)
- [ADR 0009: why Firebase replaced Spring Boot + PostgreSQL](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/docs/tech-lead/adr/0009-firebase-replaces-spring-boot-and-postgres.md)
- [ADR 0010: why the functions run in the portal](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/docs/tech-lead/adr/0010-portal-functions-replace-cloud-functions.md)
- Every decision: [Decisions](./decisions.md)
