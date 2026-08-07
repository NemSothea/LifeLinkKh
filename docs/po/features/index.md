# Feature Registry (FR)

IDs follow R7: `FR-<AREA>-<###>-<slug>`. Numbering is **per area** — each area has its own counter
below. Bump the counter when you claim a number; a merge conflict on this file is the allocation
working as intended.

Milestones reference root `CLAUDE.md` section 4, which is the only place milestone dates live.

## Next number per area

| Area | Next |
|---|---|
| AUTH | 003 |
| DONOR | 003 |
| REQUEST | 006 |
| MATCH | 003 |
| DONATION | 002 |
| NOTIFY | 003 |
| PORTAL | 003 |
| GLOBAL | 003 |
| SECURITY | 002 |
| MOBILE | 001 |

## Registry

`status: accepted` means the feature comes from `prd.md` and is approved.
`status: requested` means it was added to close a documented gap and is **not yet approved** —
its priority is a proposal.
`status: superseded` / `retired` means it is history — do not build against it. Rows kept so old
cross-references still resolve.

| ID | Title | Area | Priority | Status | Milestone |
|----|-------|------|----------|--------|-----------|
| [FR-AUTH-003-google-sign-in](FR-AUTH-003-google-sign-in.md) | Authentication via Google Sign-In | AUTH | Must Have | accepted | M3 |
| [FR-AUTH-001-phone-otp-auth](FR-AUTH-001-phone-otp-auth.md) | ~~Phone authentication via OTP~~ | AUTH | Must Have | **superseded** by FR-AUTH-003 | — |
| [FR-AUTH-002-otp-resend-cooldown](FR-AUTH-002-otp-resend-cooldown.md) | ~~OTP resend with cooldown~~ | AUTH | Should Have | **retired** — no OTP to resend | — |
| [FR-DONOR-001-donor-profile](FR-DONOR-001-donor-profile.md) | Donor registration and profile | DONOR | Must Have | accepted | M3 |
| [FR-DONOR-002-eligibility-check](FR-DONOR-002-eligibility-check.md) | Eligibility check — 56-day cooldown | DONOR | Must Have | accepted | M4 computation, M5 donor status |
| [FR-REQUEST-001-create-urgent-request](FR-REQUEST-001-create-urgent-request.md) | Create urgent blood request | REQUEST | Must Have | accepted | M4 |
| [FR-REQUEST-002-respond-accept-decline](FR-REQUEST-002-respond-accept-decline.md) | Respond to a request — accept or decline | REQUEST | Must Have | accepted | M4 |
| [FR-REQUEST-003-duplicate-request-warning](FR-REQUEST-003-duplicate-request-warning.md) | Warn on duplicate open request | REQUEST | Should Have | requested | M4 |
| [FR-REQUEST-004-withdraw-acceptance](FR-REQUEST-004-withdraw-acceptance.md) | Donor withdraws acceptance | REQUEST | Should Have | requested | M5 🔒 |
| [FR-REQUEST-005-request-expiry](FR-REQUEST-005-request-expiry.md) | Request expiry rule | REQUEST | Should Have | requested | M5 🔒 |
| [FR-MATCH-001-donor-matching](FR-MATCH-001-donor-matching.md) | Donor matching by compatibility and distance | MATCH | Must Have | accepted | M4 🔒 |
| [FR-MATCH-002-zero-match-fallback](FR-MATCH-002-zero-match-fallback.md) | No-donors-found handling | MATCH | Should Have | requested | M4 🔒 |
| [FR-DONATION-001-donation-history](FR-DONATION-001-donation-history.md) | Donation history | DONATION | Should Have | accepted | M5 |
| [FR-NOTIFY-001-request-push-alert](FR-NOTIFY-001-request-push-alert.md) | Push alert for a matched request | NOTIFY | Must Have | accepted | M4 (tokens M3) |
| [FR-NOTIFY-002-eligibility-reminder](FR-NOTIFY-002-eligibility-reminder.md) | Eligibility reminder when cooldown ends | NOTIFY | Should Have | accepted | M5 |
| [FR-PORTAL-001-hospital-request-management](FR-PORTAL-001-hospital-request-management.md) | Hospital request management (web) | PORTAL | Should Have | accepted | M4 |
| [FR-PORTAL-002-admin-dashboard](FR-PORTAL-002-admin-dashboard.md) | Admin dashboard (web) | PORTAL | Should Have | accepted | M6 |
| [FR-GLOBAL-001-localization-km-en](FR-GLOBAL-001-localization-km-en.md) | Khmer and English localization | GLOBAL | Should Have | accepted | M6 |
| [FR-GLOBAL-002-metrics-instrumentation](FR-GLOBAL-002-metrics-instrumentation.md) | Success-metric event capture | GLOBAL | Must Have | requested | M3–M5 capture, M6 dashboard |
| [FR-SECURITY-001-account-data-deletion](FR-SECURITY-001-account-data-deletion.md) | Account and personal data deletion | SECURITY | Must Have | requested | M6 |

**19 features.** 12 from `prd.md` FR-01..FR-12, 7 added to close documented gaps.

🔒 = blocked on an open brief in [../briefs/roadmap.md](../briefs/roadmap.md).
The MATCH rows' location-precision and compatibility blockers were cleared on 2026-08-07 by
[ADR 0003](../../tech-lead/adr/0003-donor-location-precision.md) and
[ADR 0004](../../tech-lead/adr/0004-abo-rh-compatibility-lookup-table.md); both stay 🔒 on the
remaining max-notified-count brief.

## Blocked on open briefs

| FR | Blocking brief | Must resolve before |
|---|---|---|
| `FR-MATCH-001` | Location precision; max notified count | M4 |
| `FR-MATCH-002` | Zero-match fallback | M4 |
| `FR-REQUEST-005` | Request expiry rule | M4 (shapes schema) |
| `FR-REQUEST-004` | Withdrawn acceptance | M5 |
| `FR-DONOR-001`, `FR-DONOR-002`, `FR-DONATION-001`, `FR-SECURITY-001` | Location precision / walk-in donation | M4–M6 |

## Scheduling conflicts — resolved

Mapping features against `CLAUDE.md` section 4 exposed three ordering problems. All are now decided;
full rationale in [../../pm/decisions.md](../../pm/decisions.md), and section 4 has been amended to
match.

| Was | Now | Decision |
|---|---|---|
| 56-day cooldown scheduled M5, but M4 matching must filter ineligible donors | Eligibility **computation** at M4; donor-facing status stays M5 | [DEC-001](../../pm/decisions.md) |
| FCM push scheduled M5, but FR-04 requires notification on request creation at M4 | Request-alert push at **M4**; FCM **token registration at M3**; eligibility reminder stays M5 | [DEC-002](../../pm/decisions.md) |
| Metrics capture registered against M5, but its events occur from M3 onward | Capture is a **per-milestone delivery requirement** M3–M5; dashboard at M6 | [DEC-003](../../pm/decisions.md) |

Net effect: **M4 is now the heaviest milestone** — request creation, matching, eligibility computation
and push in two weeks. Recorded as a schedule risk in [../../pm/risks.md](../../pm/risks.md).

## Overlap resolved

`prd.md` FR-06's third acceptance criterion (reminder when a donor becomes eligible again) duplicated
FR-09. It is assigned to `FR-NOTIFY-002` only. `FR-NOTIFY-001` covers the urgent request alert.
