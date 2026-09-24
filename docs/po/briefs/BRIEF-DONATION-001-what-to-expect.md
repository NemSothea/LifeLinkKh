---
id: BRIEF-DONATION-001-what-to-expect
title: What to expect when you donate
area: DONATION
milestone: post-M7
status: promoted
owner: PO
fr_ref: — (not an FR — recorded in docs/scope.md "Grown after M7")
---

## Problem

Someone who has never given blood does not know what happens once they walk into the
centre: how long it takes, whether it hurts, what they should do first, what happens after.
That unknown is the first-time donor's biggest barrier, and nothing in the app answered it.
The app tells a donor *that* they can donate (the eligibility card) and *where* someone needs
blood (the board), but never *what donating is like*.

Evidence: Sothea's own donations. After donating he was given food, water, a snack and a
T-shirt — care and thanks that a first-time donor does not know to expect, and that makes the
visit feel looked-after rather than clinical. Told in advance, it lowers the barrier.

## Why now

Cheap and self-contained — static text, no API, no migration — and it strengthens the
defense story ("we lower the first-time barrier", not only "we match donors").

The framing has to be settled before any copy is written, because the obvious version is
wrong twice:

- `prd.md` §2.2 lists **payment, rewards, or gamification** as out of scope. "Donate and get
  free stuff" is a reward feature.
- Voluntary donation is unpaid by definition (the WHO principle of voluntary non-remunerated
  donation). The snack and water are there so the donor recovers; the gift is thanks. Selling
  either as the reason to donate invites a fair challenge at the defense.

So: a *what to expect* guide in which the snack, water and gift appear as part of the
after-care, hedged ("many centres", "gifts vary"), with a closing line that donation is
voluntary and unpaid.

## Open questions

- [ ] **Which centre?** Sothea's donation is one source. Name the centre (NBTC or a hospital
      drive) so the claims can be checked against it. Gifts differ by centre and campaign —
      until more centres are confirmed, the guide never promises a specific gift.
- [ ] **Khmer copy review** by a native reader before any pilot. Written alongside the
      English; the terms for haemoglobin and "unpaid" are the likeliest to read awkwardly.
- [ ] **Eligibility criteria** (age, weight) are deliberately absent — the app only knows
      the 56-day rule, and a second, unverified set of criteria on a static screen would
      disagree with the centre's own. Add only with a sourced list.
- [ ] Should the eligibility-reminder push (`FR-NOTIFY-002`) open this guide? Not now — push
      routing is the riskiest code in the app this close to the demo.
