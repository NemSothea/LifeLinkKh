# Community launch — Phase 0 audit

> Owner: Tech Lead (Sothea). Written 2026-09-30 by the `community-launch` skill, Phase 0.
> Re-run the skill to refresh it; a line here is only as true as the date above.

## Headline

**The repo is already public (`gh repo view` → `"visibility":"PUBLIC"`) and has no license.**
With no license, the default is all rights reserved. Anyone can read the code, but nobody may legally
reuse, fork or contribute to it. Choosing a license is the first blocker for everything after this audit.

## Surfaces

### Repository / community files

| Item | State | Path / evidence |
|---|---|---|
| README | present (bilingual badges, screenshots, live links) | `README.md` |
| LICENSE | **missing** | `gh repo view` → `licenseInfo: null` |
| SECURITY.md | **missing** | — |
| CODE_OF_CONDUCT.md | **missing** | — |
| CONTRIBUTING.md / .km.md | **missing** (`ONBOARDING.md` exists, team-facing) | `ONBOARDING.md` |
| GOVERNANCE.md | **missing** (governance is internal: `docs/roles-and-flows.md`, `docs/decisions.md`) | — |
| CHANGELOG.md | **missing** at root | — |
| Issue templates | **missing** | no `.github/ISSUE_TEMPLATE/` |
| PR template | present (no personal-data line yet) | `.github/pull_request_template.md` |
| CODEOWNERS, Dependabot, CI | present | `.github/CODEOWNERS`, `.github/dependabot.yml`, `.github/workflows/ci.yml` |
| Labels | defaults present (`good first issue`, `help wanted`, `documentation`…); **missing** `translation-km`, `docs`, `mobile`, `web`, `firebase`, `security` | `gh label list` |
| Discussions | **off** | `hasDiscussionsEnabled: false` |
| Releases | **none** | `gh release list` empty |

### Website (`frontend/`, Next.js 16, `next-intl`, `km` default + `en`)

| Item | State | Path / evidence |
|---|---|---|
| Public routes | present | `src/app/[locale]/{page,getting-blood,download,privacy,delete-account}` |
| Root metadata | partial: title + description only, same title on every page | `src/app/[locale]/layout.tsx` `generateMetadata` |
| Per-route metadata | **missing** | — |
| `sitemap.ts` / `robots.ts` | **missing** | — |
| hreflang / canonical | **missing** | no `alternates` in `src/` |
| JSON-LD | **missing** | no `application/ld+json` in `src/` |
| `noindex` on `/sign-in`, admin sub-pages | **missing**: indexable | no `robots`/`index: false` in `src/` |
| `/portal` | **the public request board** (DEC-009), with admin actions after sign-in. It shows donor names, so indexing it is a decision, not a default | `src/app/[locale]/portal/page.tsx` |
| OG image | present, one static PNG shared by both locales | `src/app/opengraph-image.png` + `.alt.txt` |
| Icons | present | `src/app/icon.png`, `apple-icon.png`, `favicon.ico` |
| `<html lang>` | present, per locale | `layout.tsx` |
| Fonts | present, self-hosted via `next/font` (Inter + Kantumruy Pro `khmer` subset, `display: swap`) | `layout.tsx` |
| Security headers | present; CSP has no `script-src`, so inline JSON-LD will not be blocked | `next.config.ts` |
| Strings | `src/messages/{km,en}.json` | `src/i18n/request.ts` |
| Live URL | `https://lifelinkkh.vercel.app` (free Vercel subdomain) | `README.md` |

### Mobile (`mobile/`, Flutter)

| Item | State | Path / evidence |
|---|---|---|
| Version | `1.0.0+1` | `mobile/pubspec.yaml` |
| Distribution | signed APK linked from the portal's download page; **no GitHub Release, no checksum** | `README.md`, `gh release list` |
| Strings | `lib/l10n/app_{km,en}.arb` | `mobile/lib/l10n/` |
| Signing secrets | ignored (`key.properties`, `*.jks`) | `.gitignore`, `mobile/android/.gitignore` |
| Firebase client config | **committed on purpose** (`google-services.json`, `GoogleService-Info.plist`); these are not secrets, but the API key inside should be restricted in Google Cloud | `.gitignore` lines 28–33 |

### Book

| Item | State |
|---|---|
| `docs/book/` | **missing** |
| Source material to link from | present: `docs/tech-lead/`, `docs/decisions.md`, `docs/po/`, `docs/demo-runbook.md`, `firebase/README.md` |

### Community channels

| Item | State |
|---|---|
| Telegram group, Facebook page | unknown to the repo: `[TELEGRAM_LINK]`, `[FB_PAGE]` |
| `docs/community/` | **missing** |

## Secrets

- `secrets/*` is ignored except `secrets/README.md`, and `git ls-files secrets` lists only the README.
- `git log --all -- 'secrets/*.json' '*service-account*'` is empty: the service-account key has never been committed.
- `frontend/.env.local` exists locally and is ignored (`.env.*`). Only `.env.example` is tracked, and it holds variable names with no values.
- A full-history scan (`gitleaks`) has **not** run yet. It is part of Phase 1, and the repo is already public, so run it early.

## What needs team credentials, and what an outsider can run without them

| Task | Needs | Outsider can do it? |
|---|---|---|
| Firestore + Auth emulators (`cd firebase && npm run emulators:app`) | Java 21, Firebase CLI; no login expected for emulators (not yet tested on a clean machine) | yes, to be verified in Phase 2 |
| Seed (`seed:app`, `seed:admin:app`) | `PORTAL_ADMIN_PASSWORD`, which the contributor picks (≥12 chars, DEC-013) | yes |
| Portal against emulators (`frontend`, `npm run dev`) | `frontend/.env.local` with emulator hosts. **No `frontend/.env.example` exists**, so an outsider has to guess from the root `.env.example` | yes, but undocumented: **gap** |
| Flutter app against emulators | committed `google-services.json` + `--dart-define` emulator/portal URLs | yes |
| Real `lifelinkkh` project (deploy, real pushes, `metrics -- --project lifelinkkh`) | service-account JSON (`GOOGLE_APPLICATION_CREDENTIALS` / `FIREBASE_SERVICE_ACCOUNT`) | no, and that is correct |
| Signed release APK | keystore + `key.properties` | no, and that is correct (maintainers only) |

## Top gaps, in order

1. No LICENSE on a public repo.
2. `/sign-in` is indexable; `/portal` (public board, donor names) has no indexing decision; there is no sitemap, robots, hreflang or canonical.
3. No contributor-facing docs: CONTRIBUTING (en/km), SECURITY, CODE_OF_CONDUCT, issue templates, `frontend/.env.example`.
4. No GitHub Release or checksum for the APK.
5. No book, Discussions or `docs/community/`.
