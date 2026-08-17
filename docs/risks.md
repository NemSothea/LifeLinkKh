# Risks

> **Relocated 2026-08-07** from `docs/pm/risks.md` when the PM role was dropped. Risks are a project
> artefact, not a role's. Refreshed at the same time — see "Changes on 2026-08-07" at the end.

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| DoD step-1 sign-off is near-self-approval (see below) | High | Med (reduced 2026-08-07) | QA sign-off (step 3) stays independent; decide as PO in writing before reviewing as Tech Lead |
| M4 overloaded after DEC-001/DEC-002 (see below) | High | Med | FCM token registration pulled into M3; cut `FR-REQUEST-003` and `FR-MATCH-002` from M4 first if the milestone slips |
| Low donor density early | High | Med | Campus/NGO onboarding drives |
| Donor phone numbers unverified after auth moved to Google Sign-In | High | High (already true) | Coordinate via FCM push in-app, not phone calls — must land in `FR-REQUEST-002` / `FR-NOTIFY-001`. Lazy verification at acceptance time is the fallback (ADR 0002) |
| No deploy runbook exists (`infra/` deleted with the DevOps role) | Med | High (already true) | Tech Lead writes one before M7. The signed-AAB release currently has no documented promotion path |
| False/abusive requests | Med | Med | Admin moderation + hospital confirmation |
| 5-person team vs assignment's 3 | Low | — | Confirm with instructor |

## Concentrated sign-off authority

**Logged:** 2026-07-31

**What:** Definition of Done step 1 (`docs/cheat-sheet.md`) requires a spec to be signed off by
**PO + Tech Lead [+ Security if R5]**. Nem Sothea holds all three roles — Tech Lead primary,
PO and Security as overlays (`.capybara/setup.md`, `docs/team.md`). PM is also held by Tech Lead.
Three required signatures resolve to one person, so step 1 is self-approval rather than a gate.

**Why it matters:** Every R5 trigger in this project routes through the same person. The R5 set
is large — auth (phone OTP, JWT, RBAC), PII (phone number, precise location, blood type as
health data), secrets (FCM, SMS provider, Maps keys), and external integrations. A design flaw
in any of those passes step 1 unchallenged.

Two decisions make this concrete and are due before Flyway migrations land (both tracked as
briefs in `docs/po/briefs/roadmap.md`):

- **Request expiry rule** — shapes the `BloodRequest` state machine.
- **Location precision** — exact lat/lng vs. district centroid; shapes `DonorProfile` and is
  simultaneously a privacy decision (Security) and a matching-accuracy decision (PO).

In both, the person writing the requirement is the person approving the schema.

**Mitigation:**

1. **Keep DoD step 3 independent.** QA sign-off vs. acceptance criteria (Oun Sreynich) is the
   only remaining external check. It must not migrate to the Tech Lead under time pressure.
2. **Sreynich writes test cases from the FR alone** — no verbal walkthrough. A criterion she
   cannot turn into a test case was underspecified; that is the signal the collapsed step-1
   gate would otherwise have caught.
3. **Sequence the hats, in writing.** Decide as PO in a brief (`docs/po/briefs/`) and commit it
   *before* reviewing the same question as Tech Lead. The committed brief is what prevents one
   snap judgement from standing in for two roles.
4. **R5-triggering changes get an ADR**, not just a spec sign-off (`docs/tech-lead/adr/`). The
   written rationale is reviewable after the fact even when the approval was not independent.
5. **Ask the instructor whether a teammate should hold PO outright.** The team is 5 people; PO is
   currently "team-owned, Tech Lead drives in tooling" (`docs/team.md`). Reassigning it to
   Pisey, Sourn, or Sreynich restores step 1 at no cost to the schedule and is the real fix —
   items 1–4 only reduce the damage.

**Review:** at each milestone boundary. Close this risk if PO is reassigned to another member.

## M4 overloaded

**Logged:** 2026-07-31

**What:** DEC-001 and DEC-002 (`decisions.md`) moved eligibility computation and the FCM
request-alert push from M5 into M4. M4 (W9–10, two weeks) now carries `FR-REQUEST-001` request
creation, `FR-REQUEST-002` accept/decline, `FR-MATCH-001` matching, `FR-DONOR-002` eligibility
computation, `FR-NOTIFY-001` push, and `FR-PORTAL-001` hospital request management — the largest
milestone in the plan by a wide margin.

**Why it matters:** M4 is also the milestone with the most unresolved product decisions. Three of the
seven open briefs gate it — location precision, max notified count, and zero-match fallback — and
location precision additionally blocks the Flyway migration `FR-MATCH-001` needs. A heavy milestone
whose requirements are still undecided is where a 15-week course project slips.

The alternative was worse. Leaving push in M5 would have closed M4 with `FR-REQUEST-001`'s own
acceptance criteria unmet, forcing QA to fail the milestone or waive a criterion — and QA sign-off is
the only independent gate this project has.

**Mitigation:**

1. **Already applied:** FCM token registration moved into M3 with `FR-DONOR-001`, so M4 adds a send
   path to tokens that already exist rather than building the whole integration under pressure.
2. **Resolve the three M4 briefs before W9.** They are decisions, not work — they cost hours, and
   leaving them open costs days.
3. **Cut order if M4 slips**, decided now rather than in the moment: drop `FR-REQUEST-003`
   duplicate-request warning first, then `FR-MATCH-002` zero-match fallback. Both are `requested`, not
   `accepted`. **Never cut `FR-NOTIFY-001`** — that returns to the acceptance-criteria problem this
   decision exists to avoid.
4. **Do not move `FR-PORTAL-001` out of M4** without checking `FR-DONATION-001`: hospital confirmation
   of donations is what makes the M5 cooldown date trustworthy.

**Review:** at the M3 → M4 boundary. Close if M4 completes on schedule.


## Scope cut (DEC-004) — 2026-08-07

Eight FRs deferred, M3/M4 given three weeks each ([`scope.md`](scope.md)). Effect on this register:

| Risk | Effect |
|---|---|
| M4 overloaded | **Reduced, not closed.** M4 keeps request create, matching, eligibility computation, push and accept/decline — but now over three weeks instead of two, and `FR-REQUEST-003` and `FR-MATCH-002` (the pre-agreed cut order below) are already out |
| Low donor density early | **Unmitigated in the build.** `FR-MATCH-002` zero-match fallback was its direct mitigation and is deferred. A zero-match now just tells the requester none were found |
| New — personal data deletion not built | `FR-SECURITY-001` deferred. Safe only while the pilot uses team test accounts. **Blocks any real-donor use** |
| New — no metrics instrumentation | DEC-003 withdrawn. The five PRD metrics must be produced by SQL queries at demo time; if the pilot data is thin, the defence has no numbers |

## Changes on 2026-08-07

**Concentrated sign-off — partly mitigated.** Mitigation 5 above ("ask whether a teammate should hold
PO outright") was acted on: **Moeun Nithvaraman is now primary PO**, co-holding product definition with
Nem Sothea (`team.md`). Step 1 is no longer strictly one signature. It is not closed, because:

- Tech Lead still holds Security, so R5 sign-off remains self-approval.
- ADR 0003 (donor location precision) was decided by Nem Sothea as Tech Lead without Moeun's
  signature — the first decision the co-PO split existed to catch. Recorded in the ADR itself.

Close this risk when Security moves to another member, or when a second signature is a merge
requirement rather than a convention.

**Location precision — closed.** Resolved by [ADR 0003](tech-lead/adr/0003-donor-location-precision.md).
No longer blocks `donor_profiles`, `V1__init.sql`, or M4 matching.

**Request expiry — still open.** No FR, no rule; `blood_requests.status = 'EXPIRED'` ships unreachable
at M2.

**SMS OTP cost — closed and replaced.** Auth moved to Google Sign-In (ADR 0002), so there is no SMS
spend and no provider to evaluate. The replacement risk is the unverified phone number, now in the
table above. This is a genuine trade, not a removal: cost and code went away, reachability got worse.

**PM role removed.** The DoD tracking this register was part of now sits with QA.

## Changes on 2026-08-17

**Role rotation — no risk change.** Three roles swapped hands: Moeun Nithvaraman took Backend/DB,
Suon Pisey took Frontend, Sourn SAVOURN took PO (co-PO with Nem Sothea). The concentrated-sign-off
risk is unaffected — a second PO voice still exists, only the person holding it changed, and Security
still sits on Tech Lead. Read the 2026-08-07 section as history: sign-offs dated before today belong
to the previous holder, so **Moeun** in that section and in ADR 0003 means the then-PO, not the
current one.
