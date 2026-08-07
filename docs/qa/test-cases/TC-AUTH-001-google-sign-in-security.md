---
id: TC-AUTH-001
feature: FR-AUTH-003-google-sign-in
milestone: M3
type: security / integration
source: SEC-REVIEW-001 conditions F2 + TM-AUTH-001
status: not-run
---

# TC-AUTH-001 — Google Sign-In cannot be bypassed or escalated

Written from `SEC-REVIEW-001` so QA can verify the conditions without re-deriving the reasoning.
Every case below must be run against the M3 backend before `FR-AUTH-003` is signed off.
These are **negative** tests: each one passes only if the request is *refused*.

## Preconditions
- M3 backend running with auth enabled.
- Two real accounts: `donorA`, `donorB`. A valid Google ID token obtainable for each.
- A second, unrelated Firebase project available to mint a foreign but genuine ID token.

## Cases

| # | Threat | Action | Expected |
|---|---|---|---|
| 1 | S1 | Sign in as `donorA`, then call any endpoint passing `donorB`'s user ID / `uid` / email in the body or a query param | `donorB`'s data is never returned. Identity comes from the token alone |
| 2 | S1 | POST the sign-in exchange with a user identifier but **no** ID token | 401. No account created, no session issued |
| 3 | S2 | Present a genuine, correctly-signed ID token from the **other** Firebase project | 401. Signature alone must not be sufficient — `aud` must be checked |
| 4 | T1 | Present a token with header `{"alg":"none"}` and no signature | 401 |
| 5 | T1 | Present an RS256 token re-signed as HS256 using Google's public key as the HMAC secret | 401 |
| 6 | E1 | Sign up self-service requesting `role: "ADMIN"` | Request **rejected** with an error. Not silently created as `DONOR` — a silent downgrade hides the attempt |
| 7 | E1 | Same as 6 with `role: "HOSPITAL"` | Rejected |
| 8 | S3 | Reuse an already-exchanged ID token on a second exchange | 401 |
| 9 | S3 | Call a business endpoint using the raw Google ID token instead of the backend JWT | 401 |
| 10 | I2 | Grep application logs after running cases 1–9 | No ID token, backend JWT, phone number, or blood type appears in any log line |
| 11 | D1 | Fire 100 sign-in attempts from one IP in 10 seconds | Rate limited (429), service stays up |

## Case 12 — donor contact and location exposure (I1 + ADR 0003)
Combined per `ADR 0003`, since both are the same failure: an entity serialised instead of an explicit DTO.

1. As `donorA`, create a request that matches `donorB`.
2. Fetch the match list and the request detail **before** `donorB` accepts.
3. Inspect every response body.

Expected: no `phone`, no `latitude`, no `longitude`, and no unrounded distance for `donorB` — at any
milestone, on any endpoint, including admin views. District name and a distance rounded to 0.5 km are
permitted. After `donorB` accepts, contact may appear; coordinates still must not.

## Blocking
`FR-AUTH-003` cannot be closed while any case above fails. Cases 1, 3 and 6 are authentication bypass
or privilege escalation — they are release blockers, not bugs to triage.
