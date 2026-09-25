---
id: FR-NOTIFY-003-requester-acceptance-push
title: Push the requester when a donor accepts
area: NOTIFY
status: accepted
priority: Should Have
owner: PO
brief_ref: ../briefs/BRIEF-NOTIFY-001-requester-acceptance-push.md
---

## Problem
The family who posts a request is never told that a donor answered. `FR-NOTIFY-001` pushes in one
direction only — to donors — so the requester has to keep reopening the app to find out whether
anyone is coming.

## Desired outcome
Within seconds of a matched donor tapping Accept, the requester's phone alerts them that a donor
accepted their request, and opening the app shows the request's accepted count go up. Who
accepted is not shown to the requester — the donor's identity reaches the hospital, not the family.

## Why
Found on real devices on 2026-09-24 (see the brief). The product's promise is coordination between
the two sides of an emergency; with push in one direction only, one side waits in silence. Added
after M7 and outside DEC-004's graded build — recorded in `../../scope.md` "Grown after M7".

## Scope
**In:**
- One push to the request's creator for each donor whose response becomes `ACCEPTED`.
- Text in the creator's `users.language` (`km` default), carrying the blood type and hospital name
  only.
- A data payload of `type = DONOR_ACCEPTED` and `requestId`, matching the donor alert's shape.
- The mobile app refreshes the requester's request list and detail when the push arrives while it
  is open, and shows a short in-app notice — Android does not display a notification for an app in
  the foreground.

**Out:**
- Declines. A decline is not news the family can act on.
- Tap-to-open the request detail. Neither push routes on tap in this build; both open Home.
- Portal-created requests. Their creator is a staff account with no FCM token; staff see
  acceptances on the portal page. Nothing special-cases this — a user with no token is skipped.
- Delivery tracking. There is no column for it and no metric depends on it.

## Acceptance criteria
- [x] A donor accepting a match sends exactly one push to the request creator's registered token.
- [x] A decline sends no push.
- [x] Replaying an already-applied acceptance (same `Idempotency-Key`) sends no second push.
- [x] The push is sent only after the acceptance has committed; an FCM failure never fails or rolls
      back the respond call.
- [x] The visible text contains no donor name, phone number or coordinate.
- [x] A creator with no FCM token is skipped without error; a dead token is cleared. *(The skip is
      seen in the log; dead-token clearing is reviewed, not exercised — FCM will not return
      `UNREGISTERED` on demand.)*
- [x] With the app open on the requester's Home, the accepted count updates without a manual
      refresh.

Verified 2026-09-25: `MatchServiceTest` (publish on accept only, never on decline, replay or a
refused answer), `RequestFlowIntegrationTest` (listener runs after the real respond commits;
`findRequester` against PostgreSQL), `push_arrival_test.dart` (refetch + notice), and on the API 36
emulator — the system notification in the background and the in-app notice in the foreground.
