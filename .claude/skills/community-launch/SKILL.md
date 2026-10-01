---
name: community-launch
description: Phased playbook for taking LifeLink KH public as an open-source community project — website SEO, APK release, bilingual handbook ("book"), contributor community. Use when the user says "go public", "community launch", "SEO", "publish book", "release APK", "open source the repo", or "next community update". Runs ONE phase per invocation.
---

# Community launch — LifeLink KH (ជីវិត)

Three published surfaces, one community:

| Surface | Where it lives | Hosting ($0) |
|---|---|---|
| Website | `frontend/` (Next.js 16 App Router, `next-intl`, locales `km` default + `en`) | Vercel Hobby `sin1` — today `lifelinkkh.vercel.app`; custom domain = `[DOMAIN]` only if free |
| Mobile | `mobile/` (Flutter, `version:` in `mobile/pubspec.yaml`) | GitHub Releases on `NemSothea/LifeLinkKh` + the portal's `/[locale]/download` page |
| Book | `docs/book/` (not yet created) | GitHub Pages |
| Community | GitHub Issues/Discussions, `[TELEGRAM_LINK]`, `[FB_PAGE]` | free |

## Rules that override everything in this file

1. **$0.** Never add anything that costs money (paid domain, Blaze, Play Console fee, paid SEO tool,
   paid translation). If a step needs money, stop and ask. See DEC-018 and the cost memory.
2. **Never merge to or push to `main`.** Work on the current branch; commit only when asked.
3. **No personal data on any public or indexed surface.** Blood type + location + donation date
   about a person is health data. Public pages show aggregate or request-level data only, exactly
   what DEC-009's public board already shows — never donor names, phones, UIDs, or coordinates.
4. **Medical claims follow DEC-019:** guidance follows Cambodian practice and the NBTC; the app never
   says it replaces the National Blood Transfusion Center.
5. **R2 write scopes still apply** (`docs/team.md`). Note the owner role on every change.
6. **Khmer is first.** Every user-facing string ships in `km` and `en`. Khmer you are not sure of
   gets `[km-review]` and goes on the review list for a native speaker — never guess silently.
7. **Never invent facts:** no user counts, partner names, contacts, URLs or quotes. Use placeholders.

## How to run this skill

1. Walk the phases in order. For each, check its **Done when** list against the repo (read files,
   run `ls`/`grep`/`gh`). The first phase with any unmet item is the **current phase**.
2. Tell the user: current phase, which items are met, which are not.
3. Do only the current phase. Never skip an unmet phase; never start the next one in the same run.
4. Before anything in **Needs a human decision**, stop and ask (max 3 questions).
5. Ask before: adding a dependency, editing code outside the phase's listed paths, deleting any file,
   anything touching Firebase rules or data.
6. After each deliverable print `✅ <what was done>`. End with: phase status, what is left, the
   next phase's first step.
7. Run `/verify-all` before calling a phase that touched `frontend/` or `mobile/` done.

---

## Phase 0 — Audit

**Goal:** know what exists before building anything.
**Owner:** Tech Lead (Sothea).
**Inputs:** `CLAUDE.md`, `README.md`, `docs/decisions.md`, `docs/scope.md`, `docs/team.md`,
`frontend/src/app/`, `frontend/next.config.ts`, `frontend/src/i18n/`, `.github/`, `mobile/pubspec.yaml`,
`.gitignore`, `secrets/`.

State at the time this skill was written (2026-09-30) — re-check, do not trust:

- Present: `README.md` (bilingual badges, screenshots, live portal link), `.github/pull_request_template.md`,
  `.github/CODEOWNERS`, `.github/dependabot.yml`, `.github/workflows/ci.yml`, `ONBOARDING.md`,
  `frontend/src/app/opengraph-image.png` + `.alt.txt`, `icon.png`, `apple-icon.png`, root
  `generateMetadata` in `[locale]/layout.tsx` (title + description only), security headers in
  `next.config.ts`, Kantumruy Pro via `next/font` (self-hosted, `display: swap`), public routes
  `/[locale]`, `/getting-blood`, `/download`, `/privacy`, `/delete-account`.
- **Missing:** `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md` (+ `.km.md`),
  `GOVERNANCE.md`, `CHANGELOG.md`, `.github/ISSUE_TEMPLATE/`, `app/sitemap.ts`, `app/robots.ts`,
  hreflang/canonical, JSON-LD, `noindex` on `/sign-in` and the admin-only sub-pages under `/portal` (`/portal` itself is the public board, DEC-009), `docs/book/`, GitHub Releases
  for the APK, a public contributor setup that works without team credentials.
- Secrets: `secrets/*` is gitignored except `secrets/README.md`; `git log --all -- 'secrets/*.json'`
  was empty. A full history scan (Phase 1) is still required before the repo is advertised.

**Checklist**
- [ ] Re-verify every line above; write findings to `docs/tech-lead/community-launch-audit.md`
      (surface → present / missing / broken, with file paths).
- [ ] Confirm repo visibility: `gh repo view NemSothea/LifeLinkKh --json visibility`.
- [ ] List anything that only works with team credentials (Firebase project, admin passwords
      DEC-013, `google-services.json`) — outsiders must be able to run on emulators without them.

**Needs a human decision — license** (ask, do not choose):
- **MIT** — shortest, most familiar; anyone may fork into a closed product.
- **Apache-2.0** — like MIT plus an explicit patent grant and NOTICE file; common for orgs/NGOs.
- **AGPL-3.0** — anyone running a modified portal as a service must publish their changes; keeps
  forks open, but deters some companies and hospitals from adopting.
- Also ask: the mobile app, docs/book and images — same license, or CC BY 4.0 for docs/images?

**Done when**
- [ ] `docs/tech-lead/community-launch-audit.md` exists and lists every surface.
- [ ] License choice is recorded as a new DEC entry in `docs/decisions.md`.

---

## Phase 1 — Open-source readiness

**Goal:** a stranger can safely read, report and propose changes.
**Owner:** Tech Lead + Security overlay (Sothea); PO (Sourn) reviews the disclaimer wording.

**Checklist**
- [ ] `LICENSE` — the license from Phase 0, verbatim text, correct year and holder.
- [ ] `SECURITY.md` — report privately via GitHub "Report a vulnerability" (enable private
      vulnerability reporting in repo settings — human step); what is in scope (portal, functions in
      `frontend/src/server/`, `firebase/firestore.rules`, app); response target; never open a public
      issue for a vuln. km + en.
- [ ] `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1, plus a short Khmer summary and the contact
      channel (`[CONDUCT_EMAIL]`).
- [ ] `CONTRIBUTING.md` + `CONTRIBUTING.km.md` — setup on emulators only, branch/commit style
      (match existing `feat(...)`/`fix(...)`/`docs:` history), how to run `verify-all` checks, what
      R2 scopes mean for an outsider, where to ask.
- [ ] `.github/ISSUE_TEMPLATE/bug.yml`, `feature.yml`, `translation.yml`, `config.yml`
      (`blank_issues_enabled: false`, link to Discussions and `SECURITY.md`). Every label/prompt
      bilingual, e.g. "What happened? / តើមានបញ្ហាអ្វីកើតឡើង?".
- [ ] Update `.github/pull_request_template.md` — keep existing sections, add a bilingual
      checklist line for "no personal data in screenshots / logs".
- [ ] Labels via `gh label create`: `good first issue`, `help wanted`, `translation-km`, `docs`,
      `mobile`, `web`, `firebase`, `security`. Seed 5+ real `good first issue`s from the audit.
- [ ] Secrets scan of full history: `gitleaks detect --source . --log-opts="--all"` (free; ask before
      installing). If anything is found: stop, tell the user, rotate the credential first — rewriting
      history is a separate, confirmed step.
- [ ] Medical disclaimer, km + en, in `README.md`, the portal footer (`frontend/src/components/SiteFooter.tsx`
      via `frontend/src/messages/*.json`) and the app's about screen:
      "LifeLink KH helps connect donors and patients. It does not replace the National Blood
      Transfusion Center or medical advice." /
      "LifeLink KH ជួយភ្ជាប់អ្នកបរិច្ចាគឈាម និងអ្នកជំងឺ។ វាមិនជំនួសមជ្ឈមណ្ឌលជាតិផ្តល់ឈាម ឬដំបូន្មានវេជ្ជសាស្ត្រឡើយ។" `[km-review]`
- [ ] README: add "Contribute / ចូលរួម" section linking all of the above.

**Needs a human decision:** conduct contact address; whether the README keeps course/Group 2 framing.

**Done when**
- [ ] All listed files exist; `gh label list` shows the labels; ≥5 open `good first issue`s.
- [ ] Secrets scan ran with zero findings (or findings rotated and recorded).
- [ ] Disclaimer visible in all three clients in both languages; `/verify-all` passes.

---

## Phase 2 — Community infrastructure

**Goal:** people know where to talk, how decisions are made, and can contribute in 15 minutes.
**Owner:** PO (Sourn) for channels and governance text; Tech Lead for the contributor path;
Frontend (Pisey) + Mobile (Sothea) for the translation workflow.

**Checklist**
- [ ] GitHub Discussions enabled (human step) with categories: Announcements / ដំណឹង,
      Q&A / សំណួរ-ចម្លើយ, Ideas / គំនិត, Translation / ការបកប្រែ, Show & tell.
- [ ] Telegram group + Facebook page — **human creates them**; the skill writes
      `docs/community/channels.md`: purpose of each, rules, moderators, pinned message text (km + en),
      and "bugs go to GitHub, not chat". Links stay `[TELEGRAM_LINK]` / `[FB_PAGE]` until provided.
- [ ] `GOVERNANCE.md` (+ Khmer summary): maintainers and their R2 scopes from `docs/team.md`;
      how an outsider proposes a change (issue → Discussion → DEC entry in `docs/decisions.md`);
      who approves (CODEOWNERS); how someone becomes a maintainer.
- [ ] First-contributor path in `CONTRIBUTING.md`, tested on a clean clone:
      `cd firebase && npm ci && npm run emulators:app` (Java 21), `cd frontend && npm ci && npm run dev`,
      demo seed, portal open in the browser. Target ≤15 min on a normal laptop; time it and write
      the real number. Must need **no** team credentials (use `demo-lifelink` project id).
- [ ] Translation workflow `docs/community/translating.md`: where strings live
      (`frontend/src/messages/{km,en}.json`, `mobile/lib/l10n/app_{km,en}.arb`), key naming,
      Khmer style rules (numerals, spacing, font = Kantumruy Pro), how to test, review by a native
      speaker, `translation-km` label. CI check that `km` and `en` have the same keys, if one
      does not exist (ask before adding).

**Needs a human decision:** who moderates Telegram/Facebook; whether chat is in Khmer only or both.

**Done when**
- [ ] Discussions on with the categories; `channels.md`, `GOVERNANCE.md`, `translating.md` exist.
- [ ] A clean-clone run of the contributor path succeeded and its time is written down.

---

## Phase 3 — Website SEO

**Goal:** someone searching in Khmer or English for blood donation in Cambodia finds the portal.
**Owner:** Frontend (Pisey); Tech Lead reviews (`frontend/` is R2 Frontend).
**Base URL:** read from an env var (`NEXT_PUBLIC_SITE_URL`, default `https://lifelinkkh.vercel.app`);
never hard-code `[DOMAIN]`.

**Checklist — technical**
- [ ] `generateMetadata` on every public route (`/`, `/getting-blood`, `/download`, `/privacy`,
      `/delete-account`): unique `title` (template `%s · LifeLink KH`), `description` ≤160 chars,
      from `frontend/src/messages/{km,en}.json`, never hard-coded.
- [ ] `alternates`: `canonical` = own locale URL; `languages: { km, en, 'x-default': km URL }`.
- [ ] `frontend/src/app/sitemap.ts` — public routes × both locales with `alternates.languages`;
      no `/portal`, `/sign-in`, `/api`. Request-board detail pages only if they carry no personal data.
- [ ] `frontend/src/app/robots.ts` — allow `/`, disallow `/api/` only. **Never disallow a `noindex`
      page**: a crawler refused the page never reads the tag and can still list the bare URL;
      point to the sitemap.
- [ ] `robots: { index: false, follow: false }` in metadata for `/sign-in` and the admin-only `/portal/*`
      sub-pages (belt and braces with robots.ts).
- [ ] **`/portal` is the public request board (DEC-009), and it shows donor names.** Whether it is indexed
      is a human decision: index it only once the board shows no donor names, or keep it `noindex`.
- [ ] JSON-LD `<script type="application/ld+json">` in the locale layout: `Organization`,
      `WebSite` (with `inLanguage` km/en), and on `/download` a `MobileApplication`
      (`operatingSystem: Android`, `applicationCategory: HealthApplication`, `offers.price: 0`,
      `downloadUrl` → GitHub Release). No `aggregateRating` — we have no real ratings.
- [ ] Open Graph + Twitter: `og:locale` `km_KH` / `en_US`, `twitter:card summary_large_image`. The
      existing `app/opengraph-image.png` is bilingual with correct Khmer, so keep it, but **restate it in
      every page's `openGraph.images`**: a page that sets `openGraph` drops the file-convention image.
- [ ] Fonts: already self-hosted by `next/font` with `display: swap` — confirm Khmer subset is
      preloaded on Khmer pages and no layout shift on swap.
- [ ] `<html lang>` already set per locale — keep it.
- [ ] Check that the CSP in `next.config.ts` still allows the JSON-LD inline script (it has no
      `script-src` today — do not add one in this phase).
- [ ] Core Web Vitals targets on a mid-range Android over 4G (Lighthouse mobile preset):
      **LCP < 2.5 s, CLS < 0.1, INP < 200 ms**; images through `next/image`, above-fold image `priority`.
      Record scores in `docs/tech-lead/seo-report.md`.

**Checklist — content and keywords** (use naturally in titles, H1s, descriptions; no stuffing)

Khmer (all `[km-review]` until a native speaker signs off):
1. បរិច្ចាគឈាម — donate blood
2. អ្នកបរិច្ចាគឈាម — blood donor
3. ត្រូវការឈាមបន្ទាន់ — urgently need blood
4. ក្រុមឈាម — blood group
5. រកអ្នកបរិច្ចាគឈាម — find a blood donor
6. កម្មវិធីបរិច្ចាគឈាម — blood donation app
7. បរិច្ចាគឈាមនៅភ្នំពេញ — donate blood in Phnom Penh
8. មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម — National Blood Transfusion Center
9. លក្ខខណ្ឌបរិច្ចាគឈាម — blood donation eligibility
10. ជួយសង្គ្រោះជីវិត — save lives

English:
1. blood donor Cambodia
2. blood donor Phnom Penh
3. donate blood Phnom Penh
4. urgent blood request Cambodia
5. find blood donor near me
6. blood donation app Cambodia
7. blood type O negative donor Cambodia
8. blood donation eligibility Cambodia 90 days
9. National Blood Transfusion Center Cambodia
10. volunteer blood donor app Android

- [ ] `/getting-blood` answers the real questions (who can donate, how often, where) in both
      languages — this is the page most likely to rank; keep it consistent with DEC-019.
- [ ] Human steps (free): verify in Google Search Console and Bing Webmaster Tools (DNS or HTML
      meta tag via `metadata.verification`), submit `sitemap.xml`, request indexing of `/km` and `/en`.

**Needs a human decision:** custom domain (only if free); verification method; whether `/portal` (the
public board, with donor names) is indexed.

**Done when**
- [ ] `curl -s $SITE/sitemap.xml` and `$SITE/robots.txt` return valid output; `/km/sign-in` has
      `noindex` in its HTML; `/km/portal` matches the recorded board-indexing decision.
- [ ] Every public page has a unique title, description, canonical and km/en/x-default hreflang
      (check with `curl -s | grep`).
- [ ] Google Rich Results Test passes the JSON-LD; OG image shows correct Khmer glyphs.
- [ ] Lighthouse mobile meets the three CWV targets; `seo-report.md` records scores.
- [ ] Search Console shows the sitemap as processed (human confirms).

---

## Phase 4 — Book (handbook)

**Goal:** one bilingual place that explains the app to users and the code to contributors.
**Owner:** PO (Sourn) for user chapters; Tech Lead for architecture/contributing; QA (Sreynich) reviews.
**Tool:** **Docusaurus** — Node (the team already runs Node for `frontend/` and `firebase/`),
built-in i18n with a `km` locale, versioned docs, free deploy to GitHub Pages via Actions.
Adding it is a new dependency tree under `docs/book/` only — ask before `npx create-docusaurus`.

**Table of contents** (`docs/book/docs/` = **km**, the default locale; `docs/book/i18n/en/docusaurus-plugin-content-docs/current/` = en).
Chapter 7 is generated from `docs/decisions.md` + the ADRs by `docs/book/scripts/gen-decisions.mjs` on every build.
1. What LifeLink KH is / LifeLink KH ជាអ្វី
2. User guide — donors: register, alerts, accept/decline, history, eligibility (90 days men, 120 women)
3. User guide — requesters: post a request, admin review (DEC-015), when help is coming
4. Donor FAQ — eligibility, privacy, deleting your account (DEC-016)
5. Architecture — link/adapt `docs/tech-lead/` and ADRs 0009/0010; one diagram
6. Contributing — reuse `CONTRIBUTING.md`, translation guide, first 15 minutes
7. Decisions (ADR/DEC index) — generated list linking `docs/decisions.md` and the ADR folder
8. Glossary — Khmer ↔ English terms used in the UI

Rules: link to source docs instead of copying them where possible, so the book does not drift;
screenshots from the showcase seed only (no real personal data).

**Checklist**
- [ ] `docs/book/` scaffolded; `docusaurus.config` with `i18n: { defaultLocale: 'km', locales: ['km','en'] }`,
      Kantumruy Pro loaded.
- [ ] `.github/workflows/book.yml` — build + deploy to GitHub Pages on changes under `docs/book/`
      (Tech Lead owns CI). Human enables Pages in repo settings.
- [ ] Book has its own sitemap (Docusaurus plugin) and is linked from `README.md` and the portal footer.

**Done when**
- [ ] Book is live on GitHub Pages in both languages, all 8 chapters present (stub marked "draft" is OK
      only for 7–8), linked from README and portal.

---

## Phase 5 — Mobile distribution

**Goal:** anyone can download, verify and install the APK without the Play Store.
**Owner:** Tech Lead / Mobile (Sothea). Play Store stays deferred (DEC-012, 500-user cost rule).

**Checklist**
- [ ] Bump `version:` in `mobile/pubspec.yaml`; build signed release APK (keystore stays outside git;
      never commit `key.properties` or `.jks`).
- [ ] `shasum -a 256 app-release.apk > app-release.apk.sha256`.
- [ ] `gh release create vX.Y.Z app-release.apk app-release.apk.sha256 --notes-file ...` — ask before
      publishing (outward-facing).
- [ ] `docs/community/release-notes-template.md` — sections: What's new / អ្វីថ្មី, Fixes / ការកែ,
      Known issues / បញ្ហាដែលដឹង, SHA-256, minimum Android version.
- [ ] Install guide (book chapter + `/download` page): allow install from unknown sources, verify
      SHA-256, how updates work, how to uninstall. Screenshots in Khmer.
- [ ] `/download` page: a button to the latest GitHub Release asset, and a QR code that points to the
      same stable URL (static PNG committed under `frontend/public/`, generated once, no new runtime dep).
- [ ] Optional, ask first: CI job that builds the APK on tag and attaches it to the release.

**Done when**
- [ ] Latest GitHub Release has the APK + `.sha256`; `/download` button and QR resolve to it;
      the published checksum matches a fresh download.

---

## Phase 6 — Launch

**Goal:** tell the right people, once, with everything ready.
**Owner:** PO (Sourn) for copy and outreach; Tech Lead gives the go/no-go.

**Launch checklist** (all must be true)
- [ ] Phases 1–5 done. Repo public (human flips visibility — confirm first).
- [ ] Demo data on production is the showcase seed, not personal data.
- [ ] Portal, book, APK links all work from a phone on mobile data.
- [ ] Someone is on watch for 72 h for issues, Telegram and Facebook.

**Announcement copy** — write to `docs/community/launch-posts.md`, km + en, each ≤120 words,
with `[TELEGRAM_LINK]`, `[FB_PAGE]`, portal, book and repo links:
- [ ] Telegram (Khmer first, short, one call to action: install / join).
- [ ] Facebook page post (Khmer first, one screenshot, disclaimer line).
- [ ] Developer communities (English first): what it is, stack, "good first issues" link.

**Outreach targets — categories only** (no invented names or contacts; human fills in):
universities with CS / medicine / nursing faculties; student volunteer and Red Cross youth clubs;
NGOs working on health in Cambodia; developer communities and meetups in Phnom Penh;
hospital and NBTC communications teams (only after a human has made first contact).

**Done when**
- [ ] Launch checklist all true; posts published by a human; launch date recorded in `CHANGELOG.md`.

---

## Phase 7 — Update cadence (the loop)

**Goal:** the project keeps moving after launch; this skill is re-run for each update.
**Owner:** Tech Lead for releases; QA (Sreynich) for triage; PO (Sourn) for the changelog.

**Checklist**
- [ ] `CHANGELOG.md` (Keep a Changelog format, km summary per release), owned by PO.
- [ ] Release rhythm written in `GOVERNANCE.md`: e.g. one minor release per month, patch releases
      as needed; every release = Phase 5 steps again.
- [ ] Weekly triage (QA): label new issues, reply within 7 days, close stale after 30 days with a
      bilingual message; `good first issue` pool kept at ≥5.
- [ ] Monthly metrics in `docs/community/metrics.md` — only numbers that can be read, never guessed:
      GitHub Insights (stars, forks, contributors, PRs merged, issues closed), Release download counts
      (`gh release view --json assets`), Search Console clicks/impressions and top queries (km vs en),
      `cd firebase && npm run metrics` (the five PRD metrics).
- [ ] Re-check SEO each release: sitemap still lists all public routes, no `/portal` indexed
      (Search Console → Pages).

**Re-running for the next update**
- Invoke this skill again. If Phases 0–6 are all done, treat Phase 7 as current and do the cadence
  items that are due (release, triage, metrics), then report what changed since the last run
  (`git log --since` the last `CHANGELOG.md` entry).
- When a new surface or channel is added, add it to the table at the top and to Phase 0's audit.

**Done when** (per cycle)
- [ ] This month's metrics row exists, the changelog has the release, triage is current.
