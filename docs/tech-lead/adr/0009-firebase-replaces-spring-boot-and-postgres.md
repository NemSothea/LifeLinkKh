---
id: 0009-firebase-replaces-spring-boot-and-postgres
title: Firebase (Firestore + Cloud Functions) replaces Spring Boot and PostgreSQL
status: accepted — on branch feat/firebase-backend; main unchanged until the branch runs the golden path
date: 2026-09-26
deciders: Tech Lead
supersedes: 0001 (backend + database rows), 0007 (session JWT)
---

> **ACCEPTED 2026-09-26** by Nem Sothea as Tech Lead, on the branch `feat/firebase-backend`.
> **Not an independent sign-off** — the same person holds Security and co-PO. `main` keeps the
> Spring Boot + PostgreSQL stack and stays the demo fallback until this branch has run the golden
> path end to end (phase 3 below). If it never does, the branch is abandoned and `main` is the product.

## Context

The app already depends on Firebase for two of its three hard problems: identity (Firebase Auth,
ADR 0002) and delivery (FCM). The third — storing donors and requests and matching them — lives in a
Spring Boot service over PostgreSQL that the team runs itself: `docker-compose`, Flyway, a JWT of its
own (ADR 0007), a service-account key mounted into a container, and an `adb reverse` or LAN tunnel
before any phone can reach it.

The Tech Lead's call is to drop that server and let the clients talk to Firebase directly.

## Decision

1. **Firestore is the database.** One collection per former table; the model and the privacy rules
   are in `docs/tech-lead/firestore-data-model.md`. The seeded reference data (districts, hospitals)
   moves across as documents written by a seed script.
2. **Security Rules replace Spring Security.** Rules are the only thing between a client and the
   data, so every rule the API enforced in code is re-stated in `firebase/firestore.rules` and has an
   emulator test in `firebase/rules-tests/`. A rule without a test is treated as absent.
3. **Firebase Auth ID tokens replace the session JWT.** ADR 0007's one-hour JWT, its renewal
   interceptor and the `CircularDependencyError` that renewal path throws on a stale session all go.
   Firebase refreshes its own tokens.
4. **Cloud Functions (Blaze plan) do what a client must not.** Matching and push fan-out on request
   create, the "donor accepted" push, donation confirmation, staff role claims and deactivation. A
   phone can neither read other donors' profiles nor hold the FCM server credential.
5. **Roles are custom claims.** `role` (`HOSPITAL` | `ADMIN`) and `hospitalId` on the ID token, set
   only by a Function. A mobile user carries no claim and is a donor/requester by default.

## What moves and where

| Spring Boot today | Firebase |
|---|---|
| PostgreSQL tables | Firestore collections (`users`, `donors`, `requests`, `matches`, `donations`, `hospitals`, `districts`) |
| Controllers + `@PreAuthorize` | Security Rules, emulator-tested |
| `DonorCandidateRepository` SQL | `onRequestCreated` Function: same filters, same ordering, same cap (ADR 0008) |
| `blood_compatibility` table (ADR 0004) | A constant table in the Function — still data, not branching code |
| `AcceptanceNotifier` | `onMatchAnswered` Function |
| `PortalService.confirmDonation` | `confirmDonation` callable Function |
| Admin staff endpoints | `setStaffRole` / `revokeStaff` callable Functions |
| Portal username + password (DEC-010, DEC-013) | Firebase Auth email + password, role from claims |
| Telegram sign-in | **Dropped in phase 1.** Needs a custom-token Function; re-added only if asked for |
| Rate limiters (request create, public board) | Request create: checked in `onRequestCreated`. Board: none — Firestore bills reads, it does not throttle them |

## Rules the move must not lose

Each of these is a line in `DonorCandidateRepository`, `RequestViews` or `MatchService` today, and
each is a test in `firebase/rules-tests/` or the Functions tests:

- **A donor never matches their own request** (`dp.user_id <> :requesterUserId`).
- **Compatibility direction** — patient is the recipient, donor the donor (ADR 0004).
- **56-day cooldown, boundary inclusive** (`EligibilityCalculator.COOLDOWN_DAYS`).
- **No GPS still matches, sorts last**, never reads as 0 km (the `least(NULL)` trap, ADR 0003).
- **At most 25 notified; only notified donors get a match document** (ADR 0008).
- **Requester contact is revealed only to the creator and to a donor who accepted.** Firestore rules
  cannot hide a field, so the contact lives in its own document, `requests/{id}/private/contact`.
- **A response is given once and never overwritten** (FR-REQUEST-004 is still deferred).
- **Portal staff see their own hospital only**; the public board shows no contact and no donor id.

## Consequences

- **Course risk, accepted knowingly.** `CLAUDE.md` §2 lists Spring Boot + PostgreSQL, and the M1–M2
  ERD, Flyway migrations and API spec were produced against that stack. The ADR defense must explain
  the move; this document is that explanation.
- **Billing card required.** Cloud Functions need the Blaze plan. A class project stays inside the
  free usage, but the card must be on file before phase 3.
- **Docker goes away** for the demo — no `dev-up.sh`, no `adb reverse`, no LAN overlay. The phone
  needs internet instead of a cable. That trades one demo risk (tunnel) for another (venue Wi-Fi).
- **Tests change shape.** Testcontainers integration tests are replaced by Rules tests and Functions
  tests against the Firebase Emulator Suite (Java 21 is already installed for it).
- **Offline-first gets easier.** Firestore's client cache covers reads offline, which is the
  Week 9 requirement the Dio client never met.

## Phases

1. This ADR, the data model, `firestore.rules`, and emulator tests for every rule.
2. Flutter donor flow on Firestore: sign-in, register, profile, donation history.
3. Request create + `onRequestCreated` matching + push. **The golden path — the go/no-go point.**
4. Accept/decline + "donor accepted" push + public board.
5. Portal on the Firebase Web SDK + staff claims.
6. Remove `backend/`, Docker and the demo scripts; rewrite the runbook; merge to `main`.
