# Coding Standards

## Quick rules (unchanged)
- **Commit prefixes:** feat fix spec adr sec brief qa ci chore refactor docs.
- **Firebase (rules + Functions):** every rule has a rules test, Functions hold what a client must not do, no secrets in code (ADR 0009).
- **Web (Next.js/TS):** App Router, typed API client, Tailwind, i18n keys (no hardcoded strings).
- **Mobile (Flutter):** MVVM, feature-first folders, i18n via arb, no direct DB access.
- **Data:** contract-first — update `docs/tech-lead/firestore-data-model.md` and the rules before a client reads or writes a new field.
- **Casing (R8):** lowercase-hyphen meta docs; UPPERCASE CLAUDE/README/ONBOARDING.

## Why these rules and not more

One person writes the requirement, the code and the approval here. A standard's job in that
situation is to remove the decisions that would otherwise be re-made differently in week 11.
Anything that only pays off with a second reviewer, a second team or a second year of
maintenance is deliberately absent.

## Firebase — Security Rules and Cloud Functions

> Replaced the Java / Spring Boot section on 2026-09-26 (ADR 0009). The rules below carry over the
> ones that protected donors in the Spring code; the Spring-specific ones went with `backend/`.

**The rules are the server.** A client talks to Firestore directly, so `firebase/firestore.rules` is
the only thing between it and the data. **A rule without a test in `firebase/rules-tests/` is
treated as absent** — write the test first, as the principal who must be refused, not only the one
who is allowed.

**Deny by default; allow by name.** Every `match` block states who may read and write. A field a
client may not see (the requester's contact) cannot be hidden by a rule, so it lives in its own
document (`requests/{id}/private/contact`) with its own rule.

**Roles are claims, never fields.** A client can write its own `users/{uid}`, so a `role` field there
proves nothing. Access is the custom claim **and** an `admins/{uid}` record no client can write; the
rules check both, so deleting the record ends access before the token expires.

**Functions do what a client must not** — read other donors' profiles, send FCM, write match or
donation documents, change counts. Keep the pure logic (compatibility, cooldown, radius, ordering) in
plain modules like `functions/src/matching.js` with unit tests, and keep the trigger handlers thin
around them.

**Clinical rules stay data.** The ABO/Rh compatibility table is one constant (ADR 0004), not
branching code, and the cooldown is one named pair of constants (90/120 days, DEC-019). A client check is a convenience; the
rule or Function check is the rule.

**Location never leaves rounded.** ADR 0003: a donor's `lat`/`lng`/`geohash` are readable only by
that donor and an admin, and a distance leaves the Function rounded to half a kilometre.

**Time.** Firestore `Timestamp` for stored instants and dates (`lastDonationDate` is a timestamp).
Cooldown arithmetic converts to a Phnom Penh (UTC+7) calendar date first, as `matching.js` does —
never compare a naive local time against an instant, or the cooldown goes wrong at the day
boundary.

**Logging.** `firebase-functions/logger`. Log the event and identifiers, never PII: no phone number,
no coordinates, no blood type, no token in a log line.

**Secrets.** No service-account key in the repo, ever; the Functions use their runtime identity.
A key needed on a laptop for seeding the real project lives in `secrets/` (gitignored).

## TypeScript / Next.js

Strict mode on. No `any` — `unknown` plus a narrowing check. Server Components by default;
`'use client'` only where interaction requires it. One typed Firebase REST client (`frontend/src/lib/api/`), called from the Next server with the
admin's ID token from the httpOnly session cookie — components never call `fetch` directly, and no
token reaches page script. Every
user-visible string goes through an i18n key; a literal in JSX is a defect because the app ships
Khmer and English. Components are function components with typed props, named exports, one component
per file, `PascalCase.tsx`.

## Dart / Flutter

MVVM, feature-first folders. Widgets are `StatelessWidget` unless local state is genuinely needed.
`const` constructors wherever possible. No business logic in a `build()` method. One state-management
approach across the whole app — chosen once, recorded as an ADR, never mixed. All strings via `.arb`.
No Firestore call in a widget: repository class only. `flutter analyze` clean before commit.

## Applies to all three

Names say what a thing is, not what pattern it is: `DonorService`, not `DonorManagerImpl`. No
commented-out code in a commit. No TODO without an FR or BUG id next to it. A comment explains **why**
— the code already says what.
