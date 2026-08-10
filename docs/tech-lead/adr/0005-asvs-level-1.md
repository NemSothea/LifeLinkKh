---
id: 0005-asvs-level-1
title: Security verification targets OWASP ASVS Level 1
status: accepted
date: 2026-08-10
deciders: Tech Lead (Security overlay)
---

## Context

`docs/security/security-checklist.md` held 18 ad-hoc checkboxes with no standard behind them. Ad-hoc
checklists have a specific failure mode: they cover what the author already thought of, and there is
no way to tell what is missing. This project stores phone numbers, blood type and location, and one
person writes the requirement, the code and the approval — so "what did we forget" is the question
that matters most and the checklist could not answer it.

OWASP ASVS is the standard that answers it. It defines three levels. The choice is which one this
project verifies against.

## Decision

**ASVS Level 1**, mapped in [`../../security/asvs-baseline.md`](../../security/asvs-baseline.md).

Level 1 controls are enforced as real controls with tests behind them, not as checkboxes. The mapping
document lists which ASVS areas are in scope, which are explicitly out of scope with a reason, and
which of the 8 surviving FRs each control lands on.

Requirement IDs are not quoted anywhere until someone verifies them against the published document.
The baseline states controls in words instead. A wrong requirement ID is worse than no ID — it looks
authoritative and cannot be checked.

## Consequences

Verification becomes falsifiable: every Level 1 control in the baseline maps to a test in
`docs/qa/test-strategy.md`, and four of them are marked non-negotiable because their failure is a
privacy breach rather than a bug. Out-of-scope areas are now recorded with reasons, so the defence
answer to "did you consider file upload security" is "there are no uploads" rather than silence.

**Accepted cost, stated plainly.** This app handles sensitive personal data, and a real deployment
would owe Level 2. Level 1 is defensible *only* because the pilot runs on team-created test accounts
with no member of the public involved (`../../scope.md`). Level 2 and `FR-SECURITY-001` (account and
data deletion) come back into scope **before any real donor signs up** — a campus drive or an NGO
partner triggers that, and it is not a scheduling decision at that point.

Level 2's additional demands — formal key management, hardened session lifecycle, cryptographic
review, verified logging infrastructure — cost weeks and earn zero course marks. That is why they are
out, not because they do not matter.

## Alternatives considered

- **Level 2 now** — rejected. Weeks of work against a pilot with no real user data, at the cost of
  the features that are actually graded. Revisit the moment the user set changes.
- **Keep the ad-hoc checklist** — rejected. It cannot answer what is missing, and with no independent
  reviewer on this project that is the only question worth asking.
- **A different standard (NIST SSDF, CIS)** — rejected. Both are broader programme-level frameworks.
  ASVS maps to application controls, which is what this codebase has.
