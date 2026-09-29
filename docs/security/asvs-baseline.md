# OWASP ASVS Baseline

**Standard:** OWASP Application Security Verification Standard **5.0.0**, verified 2026-09-29
against the tagged source (`github.com/OWASP/ASVS`, tag `v5.0.0`, `5.0/en/`). Requirement IDs
below are the real 5.0.0 IDs (`chapter.section.requirement`, e.g. `8.2.2`), copied from that
source — not from memory. **Chosen level: Level 1** (ADR 0005). 5.0.0 has **70** Level 1
requirements across chapters V1–V15; V16 (logging) and V17 (WebRTC) have none at Level 1.

> **Rewritten 2026-09-29 for ADR 0009 / ADR 0010.** The first version (2026-08-10) was written for
> Spring Boot + PostgreSQL + our own JWT — `SecurityConfig`, `V1__init.sql`, CORS on a REST API.
> None of that exists any more. The controls now land on four surfaces:
>
> | Surface | What it is | Where |
> |---|---|---|
> | **Rules** | Firestore Security Rules — every client read and every client write | `firebase/firestore.rules`, tests in `firebase/rules-tests/` |
> | **Functions** | The portal's server functions, the one writer of what a client must not write | `frontend/src/server/`, `POST /api/functions/{name}`, tests in `frontend/test/server/` |
> | **Portal** | Next.js admin portal: sign-in, session cookie, pages, Server Actions | `frontend/src/app/`, `frontend/src/lib/api/` |
> | **App** | Flutter client: Firebase Auth, direct Firestore reads, three portal calls | `mobile/lib/` |

## Why Level 1 — and why that is now in question

Level 1 was defensible *only* because the pilot ran on team-created test accounts
(ADR 0005, `../scope.md`). ADR 0005 names its own trigger: **Level 2 and account deletion come back
into scope before any real donor signs up.** Account deletion (`FR-SECURITY-001`) has shipped
(DEC-016). The portal is live at `lifelinkkh.vercel.app` and the stated goal after the defense is
a real launch. **If a member of the public can install the APK, the trigger has fired** — that is
a Tech Lead decision recorded in an ADR, not something this file can settle.

## Level 1 — status by chapter

Verdicts come from `reviews/SEC-REVIEW-003-firebase-stack.md` (2026-09-29), each with its
`file:line` evidence there. **Pass** = holds and is evidenced. **Partial** = holds in part, the gap
is a numbered finding. **Fail** = does not hold. **N/A** = the feature does not exist here, with
the reason.

| ASVS | Requirement (short) | Surface | Verdict | Finding |
|---|---|---|---|---|
| 1.2.1 | Context-aware output encoding | Portal | Pass | JSX escapes; no `dangerouslySetInnerHTML` |
| 1.2.2 | URL building encodes data, safe schemes only | Portal, App | Pass | App allows `http` links in release (F-15) |
| 1.2.3 | No JS/JSON injection | Portal | Pass | |
| 1.2.4 | Parameterised DB queries | Functions | Partial | Doc ids from input not validated (F-10) |
| 1.2.5 | OS command injection | — | N/A | No OS calls |
| 1.3.1 | Sanitise WYSIWYG HTML | — | N/A | No rich text input |
| 1.3.2 | No `eval` / dynamic code | Functions | Partial | No eval, but dispatch reads `Object.prototype` (F-01) |
| 1.5.1 | XML parser hardening | — | N/A | No XML |
| 2.1.1 | Validation rules documented | all | Pass | `docs/fullstack/api-contract/`, `firestore-data-model.md` |
| 2.2.1 | Positive validation of business input | Rules, Functions | Partial | `districtCode` length, geohash precision (F-12) |
| 2.2.2 | Validation at a trusted layer | Rules, Functions | Pass | Client checks are UX only |
| 2.3.1 | Business flows in order, no skipped steps | Rules, Functions | Partial | Donor can rewrite `lastDonationDate`/`sex` after a donation (F-04) |
| 3.2.1 | Content not rendered in the wrong context | Portal | Partial | No CSP, no `nosniff`, no `frame-ancestors` (F-06) |
| 3.2.2 | Text rendered as text | Portal | Pass | |
| 3.3.1 | Cookies `Secure` + `__Host-`/`__Secure-` prefix | Portal | Partial | `Secure` in prod, no prefix (F-13) |
| 3.4.1 | HSTS, max-age ≥ 1 year | Portal | Pass | Prod sends `max-age=63072000; includeSubDomains; preload` (curl, 2026-09-29) |
| 3.4.2 | CORS origin fixed or allow-listed | Portal, Functions | Partial | Prod sends `Access-Control-Allow-Origin: *` on `/api/functions/*` (F-03); code sets none |
| 3.5.1 | Cross-origin requests to sensitive functions validated | Portal, Functions | Pass | Functions are bearer-only; Server Actions get Next's Origin check |
| 3.5.2 | Preflight cannot be bypassed | — | N/A | Nothing relies on preflight |
| 3.5.3 | Sensitive functions not on GET/HEAD | Functions | Pass | GET answers 405 |
| 4.1.1 | Content-Type matches body, with charset | Functions | Partial | JSON without charset; crashes return Next HTML (F-01, F-03) |
| 4.4.1 | WSS only | — | N/A | No WebSocket; push is FCM |
| 5.2.1, 5.2.2, 5.3.1, 5.3.2 | File upload / file paths | — | N/A | No upload, no file path from input |
| 6.1.1 | Anti-automation documented | Portal, Functions | Fail | Not written down (F-08) |
| 6.2.1 | Password ≥ 8 chars (15 recommended) | Portal | Pass | Change: 8, seed: 12 (F-14 raises it) |
| 6.2.2, 6.2.3 | User can change password; needs current | Portal | Pass | |
| 6.2.4 | Checked against top-3000 passwords | Portal | Fail | No list (F-14) |
| 6.2.5–6.2.8 | No composition rules, masked, paste allowed, not truncated | Portal | Pass | |
| 6.3.1 | Brute-force controls implemented | Portal | Partial | Firebase per-account lockout only (F-08) |
| 6.3.2 | No default accounts | Portal | Partial | Seed default username `soborey`, no default password (F-16) |
| 6.4.1 | Initial secrets random and short-lived | Portal | Pass | None generated |
| 6.4.2 | No password hints / secret questions | Portal | Pass | |
| 7.2.1 | Session tokens verified at a trusted backend | Functions, Rules | Pass | `verifyIdToken`; rules verify reads |
| 7.2.2 | Dynamic tokens, not static keys | all | Pass | Firebase ID tokens |
| 7.2.3 | Reference-token entropy | — | N/A | Self-contained tokens |
| 7.2.4 | New token on (re-)authentication | Portal, App | Pass | |
| 7.4.1 | Logout ends the session | Portal | Fail | Cookie deleted, token valid ≤ 1 h (F-05) |
| 7.4.2 | Sessions end when an account is deleted/disabled | Functions | Partial | No `checkRevoked` (F-05) |
| 8.1.1 | Authorization rules documented | Rules | Pass | Per-block comments + data-model doc |
| 8.2.1 | Function-level access restricted | Rules, Functions | Pass | ADMIN = claim **and** `admins/{uid}` |
| 8.2.2 | Data-level access (IDOR/BOLA) | Rules, Functions | Pass | Every personal doc keyed to `uid()` |
| 8.3.1 | Authorization at a trusted layer | Rules, Functions | Pass | |
| 9.1.1–9.1.3 | Token signature, algorithm allow-list, trusted keys | Functions | Pass | Admin SDK: RS256, Google JWKS |
| 9.2.1 | `exp`/`nbf` enforced | Functions | Pass | |
| 10.4.1–10.4.5 | Authorization-server duties | — | N/A | We run no OAuth server; Google and Firebase do |
| 11.3.1, 11.3.2, 11.4.1 | Ciphers, modes, hashes | — | N/A | We implement no cryptography |
| 12.1.1, 12.2.1, 12.2.2 | TLS versions, TLS everywhere, public certs | all | Partial | Vercel/Google terminate TLS; app accepts an `http` `PORTAL_URL` in release (F-15) |
| 13.4.1 | No `.git` served | Portal | Pass | `/.git/config` → 404 on prod |
| 14.2.1 | No sensitive data in URLs | Portal, App | Partial | Donor name in `?confirmed=` redirect (F-17) |
| 14.3.1 | Client storage cleared at session end | App, Portal | Partial | App keeps Drift DB, sync queue, Firestore cache (F-07) |
| 15.1.1 | Dependency remediation time frames documented | all | Fail | None written (F-09) |
| 15.2.1 | No component past those time frames | Portal | Fail | `next` 15.5.23: 1 critical, 2 high (F-02) |
| 15.3.1 | Only the needed fields returned | Rules, Functions | Partial | Admin reads donor coordinates; `acceptedDonors` public, keyed by uid (F-11) |

**Totals (70 IDs, grouped rows counted per ID):** Pass 30 · Partial 17 · Fail 5 · N/A 18.

## Project controls beyond ASVS

These are ours, not ASVS's. They stay because their failure is a privacy breach, and each is a
test in `../qa/test-strategy.md` §"Non-negotiable security tests".

| Control | Where | Verdict |
|---|---|---|
| No client reads another donor's `lat`, `lng`, `geohash` or an unrounded distance (ADR 0003) | Rules | Pass for donors and requesters; **admin reads them**, which ADR 0003 forbids (F-11) |
| A client cannot give itself a role; ADMIN needs claim + `admins/{uid}` | Rules | Pass, tested |
| Identity only from `request.auth.uid` | Rules | Pass for `create`; `update` of another uid's doc untested (F-18) |
| `requests/{id}/private/contact` readable only by the creator and accepting donors | Rules | Pass, tested; stays readable after the request closes (F-19) |
| One error shape, no stack trace or server detail | Functions | Partial (F-01) |
| No phone, coordinate or blood type in a log line | Functions, App | Pass; app `debugPrint`s uncaught errors in release (F-20) |
| `FIREBASE_SERVICE_ACCOUNT` never reaches a browser or the repo | Functions | Pass — `server-only`, no `NEXT_PUBLIC_`, not in git |
| No secret, keystore or service-account file in git | all | Pass (`git ls-files`, 2026-09-29) |

## How this is verified

Not by reading this file. Each Pass cites `file:line` in the review it came from; a verdict with
no citation is `unknown`, never Pass. Re-run with `/fr-security-check <FR>` per feature, and write
a new `SEC-REVIEW-###` whenever a surface changes (R6).
