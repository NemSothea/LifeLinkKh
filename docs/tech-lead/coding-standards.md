# Coding Standards

- **Commit prefixes:** feat fix spec adr sec brief qa infra chore refactor docs.
- **Backend (Java/Spring):** layered (Controller/Service/Repository), DTOs at boundaries, Flyway for all schema changes, no secrets in code.
- **Web (Next.js/TS):** App Router, typed API client, Tailwind, i18n keys (no hardcoded strings).
- **Mobile (Flutter):** MVVM, feature-first folders, i18n via arb, no direct DB access.
- **API:** contract-first — update docs/fullstack/api-contract before implementing.
- **Casing (R8):** lowercase-hyphen meta docs; UPPERCASE CLAUDE/README/ONBOARDING.
