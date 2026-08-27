---
id: FR-DONOR-003-scannable-donor-id
title: Scannable donor ID (QR/barcode check-in)
area: DONOR
status: requested
priority: Nice to Have
owner: PO
brief_ref: none — surfaced 2026-08-27 during M7 demo dry run, not from a written brief
---

## Problem
Confirming a donation on the web portal (`FR-PORTAL-001`) is staff manually finding the right
request row and clicking confirm — no identity-verification step at all. Real blood-donation
services (e.g. the national blood transfusion service's own app) issue donors a scannable ID —
barcode or QR — that staff scan on-site to pull up identity and donation history instantly.

## Desired outcome
A donor's profile screen shows a QR/barcode encoding a signed, short-lived token. Hospital staff
scan it from the portal (or a mobile scan screen) to jump straight to that donor's accepted match,
skipping the manual row-hunt `PortalService.confirmDonation` requires today.

## Why
Not why it matters *now* — it doesn't; see Scope. Recorded because it is a real gap next to how
actual blood services confirm identity, and worth having a doc to point at instead of relitigating
the idea from scratch later.

## Scope
**In (if ever built):** signed/expiring token generation on the donor profile, QR render on mobile,
a scan step in the portal's confirm-donation flow.
**Out:** anything resembling a static/unsigned code (replayable, a real security gap for a
credential tied to a person's blood type and location).

## Why this is deferred, not built
Not on the course's graded list (`docs/scope.md`: auth, push, GPS, DB, Play Store). Real scope —
signing/expiry, a backend endpoint, camera-scan integration on the Next.js portal — not a quick
add, and surfaced at M7 with a demo to finish. Per DEC-004's own reasoning, this is exactly what
the "future work" section is for rather than schedule risk this late.

## Acceptance criteria
None yet — `status: requested`, not `accepted`. Needs a brief and a prototype pass before this
gets acceptance criteria, per the PO flow in `docs/po/CLAUDE.md`.
