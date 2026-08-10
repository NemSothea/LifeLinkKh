---
id: SPEC-FOUNDATION-FRONTEND-NEXTJS
owner: Fullstack
status: draft
milestone: M2
---

# Foundation Spec — Next.js Web Portal

Scope of this spec: the project shape the hospital/admin portal is created with at M2. Milestone
dates are in root `CLAUDE.md` section 4 — not repeated here.

This is **Next.js with the App Router**, not a plain React SPA. Locked in
`docs/tech-lead/adr/0001-stack-and-architecture.md`.

## What M2 delivers

A Next.js project in `frontend/` that:

- builds and runs under `docker compose up` alongside the backend,
- serves one page that calls `GET /api/health` and renders the result,
- has Tailwind and strict TypeScript configured,
- routes `/km` and `/en` with Khmer as the default locale, one translated string proving the wiring.

No portal features. No auth. No forms.

## Project identity

| Field | Value |
|---|---|
| Package name | `lifelink-web` |
| Next.js | **15.5.23** — pinned at init 2026-08-10 |
| React | **19.1.0** |
| TypeScript | `strict: true`, no `any` escape hatches in committed code |
| Styling | **Tailwind CSS 4** via `@tailwindcss/postcss`. Tailwind 4 is CSS-first: there is **no `tailwind.config.ts`** — configuration lives in `src/app/globals.css` and `postcss.config.mjs`. The layout below is otherwise as built |
| i18n | **next-intl 4.13.x** |
| Package manager | npm, so one lockfile format is reviewed |

## Directory layout

```
frontend/
  src/
    app/
      [locale]/
        layout.tsx           # locale provider, html lang, font
        page.tsx             # M2: health-check page
      api/                   # route handlers — empty at M2
    lib/
      api/
        client.ts            # typed fetch wrapper, base URL from env
        health.ts            # getHealth()
    messages/
      km.json
      en.json
    middleware.ts            # locale negotiation + redirect
  next.config.ts
  tailwind.config.ts
  tsconfig.json
```

All routes live under `app/[locale]/`. Adding the locale segment later means moving every route file
and breaking every link — cheaper to start with it than to retrofit at M6.

## Decided dependencies

| Concern | Choice | Reason |
|---|---|---|
| Internationalization | **next-intl** | The App Router removed the built-in `i18n` config that the Pages Router had, so localized routing needs a library. next-intl is App-Router-native, handles the `[locale]` segment and middleware negotiation, and works in both server and client components — which matters because the portal is mostly server-rendered. |
| Data fetching | **Native `fetch` in server components** | Next 15 caches and revalidates `fetch` directly. No React Query at M2 — the portal has no client-side cache requirement until the M4 request list, and adding it now is an abstraction with no consumer. |
| Forms | none at M2 | Chosen with the M3 portal auth spec, not here. |

> Same caveat as the mobile spec: **next-intl is an architecture decision recorded in a spec.** It
> owes an ADR — see follow-ups.

## Configuration

Two env vars, both named only — never committed with values:

| Variable | Used by | Notes |
|---|---|---|
| `API_BASE_URL` | server components, route handlers | Inside Docker this resolves to the `backend` service name, not `localhost` — see `infra-docker.md`. |
| `NEXT_PUBLIC_API_BASE_URL` | browser code | Only if a client component ever calls the API directly. Not needed at M2. |

Anything prefixed `NEXT_PUBLIC_` is embedded in the client bundle and readable by anyone. Never put a
key, token, or secret behind that prefix.

## Localization

- `src/messages/km.json` and `en.json`. **Khmer is the default locale** (`prd.md` section 5).
- Middleware redirects `/` to `/km`.
- M2 ships one key (`app.title`) in both files.
- Khmer renders taller and longer than English. Set an explicit Khmer-capable font stack in
  `[locale]/layout.tsx` — the default system stack renders Khmer inconsistently across Windows and
  macOS, and a portal that looks broken on a hospital's PC is a portal nobody uses.

## Deferred to later milestones

| Deferred | Milestone |
|---|---|
| Hospital/admin sign-in, session handling | M3 |
| Hospital request list, responders view, confirm donation (FR-10) | M4 |
| Admin dashboard and metrics (FR-11) | M6 |
| Full Khmer/English string sweep, portal polish | M6 |

## Contract gaps

`docs/fullstack/api-contract/web/openapi.yaml` has `paths: {}`. M2 needs:

- `GET /api/health` — unauthenticated, response `200 {"status":"UP"}`.

`lib/api/health.ts` types its response against that contract entry. Until the contract is filled
during `/capybara-adk:plan`, the type is a local guess with nothing to validate it against. This
spec does not edit the contract.

## Done when

- [ ] `frontend/` contains a Next.js 15 App Router project named `lifelink-web`.
- [ ] `npm run build` succeeds with `strict: true` and zero TypeScript errors.
- [ ] `npm run lint` passes.
- [ ] `docker compose up` serves the app on its published port.
- [ ] Visiting `/` redirects to `/km`.
- [ ] `/km` and `/en` both render, showing the translated title in the right language.
- [ ] The page displays the live result of `GET /api/health` fetched from the backend **container**,
      not a hardcoded string or a mock.
- [ ] Stopping the backend makes the page show a handled error state, not an unhandled exception.
- [ ] Khmer text renders correctly, with an explicit Khmer-capable font stack set.
- [ ] No secret appears in any `NEXT_PUBLIC_` variable or committed file.

## Follow-ups this spec does not resolve

- **ADR owed** for next-intl as the i18n approach. Still owed as of 2026-08-10 — the library is
  installed and wired, so the ADR now documents a decision already in the code.
- ~~`GET /api/health` must reach the web API contract~~ — added to
  `../../api-contract/web/openapi.yaml` on 2026-08-10. The mobile contract already had it.
- ~~Tailwind major version must be pinned~~ — Tailwind 4, recorded above.
- **Error-shape conflict, unresolved.** The web contract's `Error` schema is
  `{ error: { code, message } }`; the backend's `common/error/ErrorResponse` is
  `{ code, message, timestamp }`. `docs/fullstack/CLAUDE.md` says openapi wins on conflict, so the
  backend record needs reshaping — but that touches every future client, so it is Tech Lead's call,
  not a silent fix. No endpoint returns an error body yet, so nothing is broken today; M3 is the
  deadline.
- **3 high-severity npm audit findings**, both transitive through `next`: `postcss` and `sharp`
  (libvips CVEs). `npm audit fix --force` wants a Next major change and was **not** run. Both are
  build-time or image-optimisation paths, not request handling. Re-check at M6 when Next is next
  bumped.
