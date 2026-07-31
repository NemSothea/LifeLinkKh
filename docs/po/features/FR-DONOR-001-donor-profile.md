---
id: FR-DONOR-001-donor-profile
title: Donor registration and profile
area: DONOR
status: accepted
priority: Must Have
owner: PO
brief_ref: ../prd.md — FR-02
---

## Problem
An authenticated user is not yet a findable donor. Without blood type and location on record the
system cannot tell whether this person can help a specific patient, and a donor who gets alerts for
incompatible or distant requests learns to ignore the app entirely.

## Desired outcome
A donor records their name, blood type, and location once, can edit it whenever it changes, and can
mark themselves unavailable without deleting anything. From then on they only hear about requests
they could actually answer.

## Why
This is the supply side of the whole product. `prd.md` section 1 targets 200 registered donors in
the first pilot month, and none of them exist until this ships.

The availability toggle stays inside this FR rather than splitting out. Whether it grows into
something with its own behaviour — auto-unavailable after repeated declines, scheduled
unavailability — is an open brief in `../briefs/roadmap.md`; splitting it now would pre-decide that.

Blocked in part on the **location-precision brief** in `../briefs/roadmap.md`: it is undecided
whether a donor's location is stored as exact coordinates or a district centroid. That is both a
privacy decision (`prd.md` section 6 calls precise location sensitive) and a matching-accuracy one,
and until it lands this FR cannot say what "location" means.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/mobile/DONOR-profile-setup/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-02 and are not duplicated here.

- [ ] <to be filled after prototyping>
