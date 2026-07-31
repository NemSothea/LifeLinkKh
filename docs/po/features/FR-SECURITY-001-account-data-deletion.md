---
id: FR-SECURITY-001-account-data-deletion
title: Account and personal data deletion
area: SECURITY
status: requested
priority: Must Have
owner: PO
brief_ref: ../prd.md — section 6, data retention
---

## Problem
`prd.md` section 6 states that users may request deletion of their account and personal data. No
feature provides it. A donor who wants out has no way out — their phone number, precise location, and
blood type stay in the database indefinitely.

That data set is the most sensitive this product holds. Section 6 classifies blood type as health data
and phone number and location as sensitive. Holding them after someone has asked you to stop is the
single worst thing this project could do to a volunteer who joined to help strangers.

## Desired outcome
A user can delete their account from within the app and their personal data goes with it. Where records
must be kept for the impact reporting section 6 describes, they are anonymized rather than retained
intact — the donation happened, but it is no longer attached to a person.

## Why
The commitment is already made in writing. An unimplemented privacy promise is worse than no promise,
because users act on it.

It also interacts with a decision that is still open. The **location-precision brief** in
`../briefs/roadmap.md` determines how identifying stored location is in the first place — less precision
means less to delete and less exposure before anyone asks. Deletion and precision are the same privacy
question approached from two ends.

Needs a Security review under R5 — this feature touches PII directly and section 6 sets the retention
rules it must satisfy (requests anonymized after two years, donation history kept for the account
lifetime). Those two rules and "delete everything" have to be reconciled explicitly, not
by whoever writes the code first.

Priority **proposed** as Must Have. Should land before real donors are onboarded in the pilot, not after.

## Scope
**In:** <to be filled after prototyping>
**Out:** <...>

## Acceptance criteria
- [ ] <to be filled after prototyping>
