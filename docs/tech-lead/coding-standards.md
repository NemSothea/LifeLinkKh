# Coding Standards

## Quick rules (unchanged)
- **Commit prefixes:** feat fix spec adr sec brief qa ci chore refactor docs.
- **Backend (Java/Spring):** layered (Controller/Service/Repository), DTOs at boundaries, Flyway for all schema changes, no secrets in code.
- **Web (Next.js/TS):** App Router, typed API client, Tailwind, i18n keys (no hardcoded strings).
- **Mobile (Flutter):** MVVM, feature-first folders, i18n via arb, no direct DB access.
- **API:** contract-first — update docs/fullstack/api-contract before implementing.
- **Casing (R8):** lowercase-hyphen meta docs; UPPERCASE CLAUDE/README/ONBOARDING.

## Why these rules and not more

One person writes the requirement, the code and the approval here. A standard's job in that
situation is to remove the decisions that would otherwise be re-made differently in week 11.
Anything that only pays off with a second reviewer, a second team or a second year of
maintenance is deliberately absent.

## Java / Spring Boot

**Structure — package by domain, not by layer.** `user/`, `donor/`, `hospital/`, `request/`,
`match/`, `donation/`, plus `config/`, `common/`, `health/`. A feature is one folder. Never create
`services/` or `controllers/` packages. Never create an empty class ahead of the milestone that
needs it.

**Dependency injection — constructor only.** `private final` fields, one constructor, no
`@Autowired` on fields, no setter injection. Field injection hides what a class needs and makes it
untestable without a Spring context.

**Layer contract, enforced:**
- Controller: HTTP only — bind, validate, delegate, map to a response. Zero business logic, zero
  repository calls.
- Service: business logic and the transaction boundary. `@Transactional` lives here, never on a
  controller or a repository.
- Repository: queries only.

**OOP rules that actually matter in this codebase:**
- **An entity is NEVER serialised to a response.** Every response body is a `record` DTO built by an
  explicit allow-list mapper. This is not style — ADR 0003 forbids `donor_profiles.latitude` and
  `longitude` from appearing in any response, and entity serialisation is precisely how that leaks.
- DTOs are `record`s. Immutable, no setters.
- Entities keep raw `UUID` foreign keys at M2 rather than JPA associations, so no lazy-load can
  traverse into forbidden columns. Revisit only if a query genuinely needs the graph.
- Constrained values (`role`, `blood_type`, `urgency`, `status`) stay `String` in Java. The DB CHECK
  constraints and `blood_compatibility` are the single authority; a parallel Java enum would be a
  second source of truth for a clinical rule.
- No inheritance except `@MappedSuperclass` for audit columns. No abstract base service, no generic
  CRUD superclass.
- No static mutable state anywhere.

**Null policy.** A method returns `Optional<T>` or a non-null value — never `null`. Parameters are
assumed non-null unless the field is nullable in the schema (`phone`, `latitude`, `longitude`,
`last_donation_date`, `blood_request_id`, `confirmed_by_user_id`), and every one of those is
documented in the entity's Javadoc.

**Errors.** One shape: `ErrorResponse(code, message, timestamp)` from `common/error/`. An error body
never carries a stack trace, an exception class name or a SQL fragment. Server-side cause goes to the
log, not to the caller.

**Validation.** Jakarta Bean Validation on request DTOs. Business rules — the 56-day cooldown, ABO/Rh
compatibility, role restrictions on sign-up — are enforced **server-side in a service**, never only
in a client. A client check is a convenience; the server check is the rule.

**Time.** `TIMESTAMPTZ` / `OffsetDateTime` for instants, `LocalDate` for donation dates. Never
`LocalDateTime` for a stored instant — Cambodia is UTC+7 and naive local time makes the cooldown
wrong at boundaries.

**Logging.** SLF4J. Log the event and identifiers, never PII: no phone number, no coordinates, no
blood type in a log line. `logger.error("...", ex)` — never `ex.printStackTrace()`.

**Migrations.** Flyway owns the schema; `ddl-auto: validate` and nothing else. A merged migration is
never edited — a mistake is corrected by the next `V<n>`.

**Formatting.** google-java-format **AOSP variant** — 4-space indent, 100-column lines — enforced by
Spotless in `verify`. `./mvnw spotless:apply` fixes violations. No wildcard imports, no tabs.
Javadoc on any class or field carrying a rule that is not obvious from the name.

## TypeScript / Next.js

Strict mode on. No `any` — `unknown` plus a narrowing check. Server Components by default;
`'use client'` only where interaction requires it. One generated or hand-written typed API client
from `docs/fullstack/api-contract/web/openapi.yaml` — components never call `fetch` directly. Every
user-visible string goes through an i18n key; a literal in JSX is a defect because the app ships
Khmer and English. Components are function components with typed props, named exports, one component
per file, `PascalCase.tsx`.

## Dart / Flutter

MVVM, feature-first folders. Widgets are `StatelessWidget` unless local state is genuinely needed.
`const` constructors wherever possible. No business logic in a `build()` method. One state-management
approach across the whole app — chosen once, recorded as an ADR, never mixed. All strings via `.arb`.
No direct HTTP in a widget: repository class only. `flutter analyze` clean before commit.

## Applies to all three

Names say what a thing is, not what pattern it is: `DonorService`, not `DonorManagerImpl`. No
commented-out code in a commit. No TODO without an FR or BUG id next to it. A comment explains **why**
— the code already says what.
