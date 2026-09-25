---
id: BRIEF-NOTIFY-001-requester-acceptance-push
title: Tell the requester a donor is coming
area: NOTIFY
milestone: post-M7
status: promoted
owner: PO
fr_ref: FR-NOTIFY-003-requester-acceptance-push
---

## Problem

Push goes one direction only. `FR-NOTIFY-001` alerts **donors** the moment a request is created;
nothing tells the **requester** when one of those donors accepts. The family who posted has to
open the app and look — the status and the accepted count do update on their Home tab, but no
alert tells them to go and look.

Evidence: running the full loop on two real devices on 2026-09-24, the first time the request and
the acceptance were on different phones. A demo where one person holds both phones hides the gap
completely, because the person who accepts is also the person watching the requester's screen.

For the family this is the worst moment in the product to be silent. They posted because someone
needs blood now; the one thing they want to know next is whether anyone answered.

## Why now

- It is the obvious question after the demo walkthrough — "so how does the family know someone
  is coming?" — and "they have to keep opening the app" is a weak answer to give at a defence.
- It is small. The accept path already knows which request was answered, the request knows who
  created it, and that user's FCM token and language are already stored for the same reason
  donors' are. It adds a second send path, not a subsystem.
- It rides on an integration that already works end to end on real devices. Waiting until after
  the demo gains nothing.

## Open questions

- [x] **Who receives it?** The request's creator (`created_by_user_id`). For a request posted
      from the portal that is a hospital staff account, which normally has no FCM token, so
      nothing is sent — the portal page is where staff see acceptances. Not a special case in
      the code; a user with no token is simply skipped.
- [x] **What does the lock screen show?** Blood type and hospital, as for the donor alert —
      never the donor's name or phone. Inside the app the requester sees the accepted count, not
      the donor — identity goes to the hospital, which confirms the donation. `TM-AUTH-001` I2
      applies to this push exactly as it does to the other.
- [x] **One push per acceptance, or one per request?** One per acceptance. A request for three
      units can collect three donors, and each one is news. Declines send nothing.
- [ ] **Tapping it** opens the app to Home, where the request card already shows the accepted
      count. Deep-linking into the request detail is not built for either push — the donor alert
      does not route on tap today either — and adding tap routing this close to the demo is the
      riskiest change in the app. Revisit after the defence, for both pushes together.
