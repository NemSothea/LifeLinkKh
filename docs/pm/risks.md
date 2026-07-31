# Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| DoD step-1 sign-off is self-approval (see below) | High | High (already true) | QA sign-off (step 3) stays independent; decide as PO in writing before reviewing as Tech Lead |
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
