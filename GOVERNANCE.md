# Governance · ការគ្រប់គ្រងគម្រោង

How LifeLink KH makes decisions, who approves changes, and how you can become a maintainer.

## សេចក្តីសង្ខេបជាភាសាខ្មែរ `[km-review]`

- អ្នកណាក៏អាចស្នើគំនិត ឬផ្ញើ Pull Request បាន។
- ការសម្រេចចិត្តសំខាន់ៗ ត្រូវសរសេរទុកក្នុង `docs/decisions.md` (DEC) ឬ `docs/tech-lead/adr/` (ADR) ជាមួយហេតុផល។
- ការសម្រេចចិត្តមិនធ្វើនៅក្នុង Telegram ឬ Facebook ទេ។ សូមពិភាក្សានៅលើ GitHub ដើម្បីកុំឲ្យបាត់។
- អ្នកដែលជួយជាប្រចាំ និងពិនិត្យកូដបានល្អ អាចក្លាយជាអ្នកថែទាំ (maintainer)។

## Maintainers

The project started as the Group 2 team project (see README → History). Each area has an owner
(`docs/team.md`, R2 write scopes):

| Area | Paths | Owner (role) |
|---|---|---|
| Mobile app | `mobile/`, `docs/mobile/` | Tech Lead / Mobile: Nem Sothea · contributor: Math Rorpheeyah |
| Web portal | `frontend/` | Frontend: Suon Pisey · contributor: Math Rorpheeyah |
| Firebase rules, seeds | `firebase/`, `docs/fullstack/` | Backend / DB: Moeun Nithvaraman |
| Product (PRD, FRs, changelog) | `docs/po/` | PO scope: Sourn Savourn, Product Supporter (co-PO Nem Sothea) |
| Tests, QA, Definition of Done | `docs/qa/` | QA: Oun Sreynich |
| Architecture, CI, security, releases | `docs/tech-lead/`, `docs/security/`, `.github/`, `scripts/` | Tech Lead: Nem Sothea |

**Lead maintainer:** Nem Sothea (Tech Lead). The lead reviews every PR and breaks ties.
**Community moderator** (Telegram, Facebook, Discussions): Nem Sothea.

`.github/CODEOWNERS` routes each PR to its reviewer automatically.

## How a change gets in

| Size | Path |
|---|---|
| **Small** (typo, translation, bug fix, test) | Open a PR. One maintainer approval, green CI, merge. |
| **Medium** (new screen, new string set, behaviour change inside an existing feature) | Open or comment on an issue first so the owner can say yes before you build. Then PR. |
| **Large** (new feature, data-model or rules change, anything touching personal data, reversing a past decision) | 1. Issue or **Ideas** Discussion. 2. A maintainer writes (or asks you to draft) a **DEC** entry in `docs/decisions.md`, or an **ADR** in `docs/tech-lead/adr/` for hard-to-reverse technical choices. 3. The DEC/ADR is accepted. 4. PR, referencing the DEC/ADR id. |

Extra gates, always:

- Anything touching **auth, personal data, secrets or an external service** needs a security review
  note in `docs/security/reviews/` before merge (R5/R6 in `docs/cheat-sheet.md`).
- **Medical content** follows Cambodian practice and the National Blood Transfusion Center (DEC-019).
- **Cost:** the project runs at $0 (DEC-018). A change that adds a paid service needs its own DEC.

## How to read a DEC entry

Every entry in `docs/decisions.md` has the same shape: **Context** (the problem), **Decision** (what
was chosen), **Consequences** (what it costs, and what is still open). The status is `proposed`,
`accepted`, or superseded by a later DEC. When a DEC says "phase 1 / phase 2" or has an
**Amendment**, the latest amendment wins.

To propose one, open a Discussion in **Ideas** with the same three headings. A maintainer assigns
the next DEC number when it is accepted.

## Decisions are made on GitHub, not in chat

Telegram and Facebook are for questions and news. If something is decided there, a maintainer
writes it into an issue, DEC or ADR within a week, or it is not decided.

## Releases

The Tech Lead cuts releases (the APK on GitHub Releases, portal deploys on Vercel). The target is
one minor release a month, with patch releases as needed. Every release gets a `CHANGELOG.md`
entry with a Khmer summary. Release notes use `docs/community/` templates.

## Becoming a maintainer

1. Contribute regularly: about 5 merged PRs, or sustained translation or review work.
2. Review other people's PRs well: kind, specific, and catching real problems.
3. An existing maintainer proposes you in a Discussion. If no maintainer objects within 7 days,
   you get write access and a line in `.github/CODEOWNERS` for your area.

Maintainers who are inactive for 6 months move to "emeritus" in this file, with thanks. They can
come back any time.

## Changing this document

A change to `GOVERNANCE.md` is a **large** change: Discussion first, then a DEC entry, then the PR.
