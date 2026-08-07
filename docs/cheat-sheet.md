# Capybara Cheat Sheet

## Lifecycle
init → project → plan → dev → review → deploy   (status any time)

## IDs (R7)
- Feature: `FR-<AREA>-<###>-<slug>`  areas: AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL GLOBAL SECURITY MOBILE
- Bug: `BUG-<AREA>-<###>`
- ADR: `adr/####-<slug>`
- Change request: `CR-<CH>-###`  channels: PO MAPI SEC  (DEVOPS retired — role dropped)
- Decision: `DEC-###`
Next number lives in each registry index.md; bump it. index.md merge conflict = allocation.

## Definition of Done (R6)
1. spec signed off (PO + Tech Lead [+ Security if R5])
2. code merged
3. QA sign-off vs acceptance criteria
4. Security sign-off (R5 only)
5. no open/in-progress bugs

## Commit / PR prefixes
feat fix spec adr sec brief qa ci chore refactor docs

## Casing (R8)
lowercase-hyphen meta docs; UPPERCASE: CLAUDE README ONBOARDING LICENSE CHANGELOG
