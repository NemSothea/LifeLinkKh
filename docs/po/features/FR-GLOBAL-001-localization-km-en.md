---
id: FR-GLOBAL-001-localization-km-en
title: Khmer and English localization
area: GLOBAL
status: accepted
priority: Should Have
owner: PO
brief_ref: ../prd.md — FR-12
---

## Problem
An app for Cambodian blood donors that only speaks English excludes most of the people it exists to
serve. In an emergency, a donor reading a language they are not fluent in will hesitate or misread
which hospital to go to.

## Desired outcome
Every user-facing string on both the mobile app and the web portal exists in Khmer and English, the
user can switch at any time, and the choice survives closing the app.

## Why
Khmer is the default language, not a translation added afterwards — `prd.md` section 5 states that
plainly. Treating it as the default from the start is also a layout constraint: Khmer text runs longer
and taller than English, so a screen designed to fit English breaks when translated. Every wireframe
in `../prototypes/` shows both languages for exactly this reason.

Marked Should Have in `prd.md`, which understates it. An untranslated app fails the target user in
`prd.md` section 3 while still passing every functional test.

## Scope
**In:** <to be filled after prototyping — see ../prototypes/web/GLOBAL-language-switch/>
**Out:** <...>

## Acceptance criteria
Criteria live in `../prd.md` under FR-12 and are not duplicated here.

- [ ] <to be filled after prototyping>
