# SEO report — web portal

> Owner: Frontend (Pisey); Tech Lead reviews. Written 2026-09-30 by the `community-launch` skill,
> Phase 3. Re-run Lighthouse after any change to fonts, images or the layout.

## Decisions (2026-09-30)

| Question | Decision | Why |
|---|---|---|
| Index `/portal` (the public board)? | **No: `noindex, nofollow`**, inherited by every admin sub-page | The board names the donors who accepted (`request-list.tsx`). An indexed page would tie a person to a hospital and a blood type, and a search cache keeps that after the donor deletes their account (DEC-016). Revisit only if the board stops showing names. |
| Domain | `https://lifelinkkh.vercel.app` via `NEXT_PUBLIC_SITE_URL` | Free. A future free custom domain is one env change on Vercel. |
| Search Console / Bing verification | HTML meta tag from `GOOGLE_SITE_VERIFICATION` / `BING_SITE_VERIFICATION` | A `vercel.app` subdomain gives no DNS access, so the meta tag is the only method. |
| Block `/portal`, `/sign-in` in `robots.txt`? | **No**, only `/api/` | A crawler refused a page never reads its `noindex`, and can still list the bare URL. `noindex` is the right tool. |

## What is in place

| Item | Where |
|---|---|
| Base URL, hreflang, canonical, Open Graph, Twitter, JSON-LD helpers | `frontend/src/lib/seo.ts` (+ `seo.test.ts`) |
| Site defaults: `metadataBase`, title template `%s · LifeLink KH`, verification, Organization + WebSite JSON-LD | `frontend/src/app/[locale]/layout.tsx` |
| Per-page title + description + canonical + `km`/`en`/`x-default` | `getting-blood`, `download`, `privacy`, `delete-account` pages; home uses the layout's |
| `noindex` | `frontend/src/app/[locale]/portal/layout.tsx` (board + admin pages), `sign-in/page.tsx` |
| MobileApplication JSON-LD (no `aggregateRating`: there are no real ratings) | `download/page.tsx` |
| `sitemap.xml`: 5 pages × 2 locales with hreflang alternates, no `lastModified` (no real date) | `frontend/src/app/sitemap.ts` |
| `robots.txt` | `frontend/src/app/robots.ts` |
| Share image (bilingual, Khmer renders correctly), restated on every page because a page's own `openGraph` drops the file-convention image | `frontend/src/app/opengraph-image.png` |
| Meta strings | `app.metaTitle`, `*.metaDescription` in `frontend/src/messages/{km,en}.json`, all ≤160 chars |

Verified on a local production build (`next build && next start`) with `curl`. Every indexed page
has a unique `<title>`, a description, its own canonical, and three hreflang links. `/km/portal`,
`/km/portal/dashboard` and `/en/sign-in` render `<meta name="robots" content="noindex, nofollow">`.
Every JSON-LD block parses. The sitemap lists no `/portal` or `/sign-in` URL.

## Lighthouse (mobile, slow 4G, 4× CPU)

Local production build (`next build && next start`), Lighthouse 12, 2026-09-30.

### Before: Kantumruy Pro at 4 static weights, `display: 'swap'`

Measured with `simulate` throttling.

| Page | Perf | SEO | A11y | FCP | LCP | CLS | TBT |
|---|---|---|---|---|---|---|---|
| `/km` | 93 | 92 | 100 | 0.9 s | 3.2 s | 0 | 20 ms |
| `/km/getting-blood` | 93 | 92 | 100 | 0.9 s | 3.2 s | 0 | 30 ms |
| `/km/download` | 94 | 92 | 100 | 0.9 s | 3.1 s | 0 | 30 ms |

The LCP element was the Khmer `<h1>`, with 86% of the time in render delay. Text painted at 0.9 s in a
fallback font and again when Kantumruy Pro arrived; that second paint was the LCP. Fonts totalled 137 KiB.

### After: Kantumruy Pro variable font, Khmer subset only, `display: 'optional'`

`frontend/src/app/[locale]/layout.tsx`. This keeps the 500 and 600 weights the portal uses
(77 `font-medium`/`font-semibold` classes). Fonts now total 104 KiB.

| Page | Perf (sim) | SEO | A11y | LCP `simulate` | LCP `devtools` | FCP `devtools` | CLS | TBT |
|---|---|---|---|---|---|---|---|---|
| `/km` | 95 | 92 | 100 | 2.9 s | **2.4 s** | 1.7 s | 0 | 10–70 ms |
| `/en` | 95 | 92 | 100 | 2.9 s | **2.4 s** | 1.6 s | 0.002 | 10–20 ms |
| `/km/getting-blood` | 95 | 92 | 100 | 2.9 s | **1.7 s** | 1.7 s | 0 | 10–90 ms |
| `/km/download` | 95 | 92 | 100 | 2.9 s | — | — | 0 | 10 ms |

- **Targets: LCP < 2.5 s ✅ (devtools), CLS < 0.1 ✅, TBT ✅.**
  - `devtools` mode applies real network throttling to real loading and is the closer model of a
    phone. `simulate` on `localhost` estimates from a request graph in which every byte finished
    before paint, so it charges the whole ~250 KiB to LCP. Its 2.9 s is a pessimistic bound.
  - 2.4 s leaves little margin. Any new font weight, image above the fold, or large client
    component on the home page can push it over, so re-measure after such changes.
  - The "before" build was not measured in `devtools` mode, so compare `simulate` with `simulate`:
    3.2 s → 2.9 s.
- **SEO 92** is a test artefact. The only failing audit is `canonical`, because the build was served
  from `localhost` while the canonical points to `lifelinkkh.vercel.app`. Re-check on the deployed site.
- The live site could not be measured with PageSpeed Insights on 2026-09-30: the anonymous daily
  quota was exhausted. Run it after deploy: <https://pagespeed.web.dev/analysis?url=https://lifelinkkh.vercel.app/km>.

## Keywords

Used naturally in titles and descriptions, never stuffed. All Khmer terms are `[km-review]`.

| Khmer | English |
|---|---|
| បរិច្ចាគឈាម | donate blood |
| អ្នកបរិច្ចាគឈាម | blood donor |
| ត្រូវការឈាមបន្ទាន់ | urgently need blood |
| ក្រុមឈាម | blood group |
| រកអ្នកបរិច្ចាគឈាម | find a blood donor |
| កម្មវិធីបរិច្ចាគឈាម | blood donation app |
| បរិច្ចាគឈាមនៅភ្នំពេញ | donate blood in Phnom Penh |
| មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម | National Blood Transfusion Center |
| លក្ខខណ្ឌបរិច្ចាគឈាម | blood donation eligibility |
| ជួយសង្គ្រោះជីវិត | save lives |

English targets: blood donor Cambodia · blood donor Phnom Penh · donate blood Phnom Penh · urgent
blood request Cambodia · find blood donor near me · blood donation app Cambodia · O negative donor
Cambodia · blood donation eligibility · National Blood Transfusion Center Cambodia · volunteer blood
donor app Android.

## Human steps after deploy (free)

1. **Google Search Console:** add the URL-prefix property `https://lifelinkkh.vercel.app/`, choose
   *HTML tag*, and copy only the `content` value into Vercel as `GOOGLE_SITE_VERIFICATION`.
   Redeploy, click Verify, then submit `sitemap.xml` and request indexing of `/km` and `/en`.
2. **Bing Webmaster Tools:** import from Search Console, or use the meta tag →
   `BING_SITE_VERIFICATION`. Redeploy, verify, submit the sitemap.
3. **Rich Results Test** on `/km/download` and `/km`: <https://search.google.com/test/rich-results>.
   MobileApplication without ratings is valid structured data, but Google shows no app rich result
   without real reviews. That is expected; don't add fake ones.
4. **Share preview:** paste `/km/getting-blood` into Telegram and the Facebook Sharing Debugger.
   The bilingual image and the Khmer title should both show.
5. **PageSpeed Insights** (link above): record the live numbers in this file.
