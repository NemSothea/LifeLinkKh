# Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| DoD step-1 sign-off is self-approval (see below) | High | High (already true) | QA sign-off (step 3) stays independent; decide as PO in writing before reviewing as Tech Lead |
| M4 overloaded after DEC-001/DEC-002 (see below) | High | Med | FCM token registration pulled into M3; cut `FR-REQUEST-003` and `FR-MATCH-002` from M4 first if the milestone slips |
| Low donor density early | High | Med | Campus/NGO onboarding drives |
| SMS OTP cost/deliverability | Med | Med | Evaluate provider early; Firebase phone-auth fallback |
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

**What:** DEC-001 and DEC-002 (`docs/pm/decisions.md`) moved eligibility computation and the FCM
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
