# Translating LifeLink KH · ការបកប្រែ

Every string a user sees ships in **Khmer (`km`, the default)** and **English (`en`)**. A string that
exists in only one language is a bug.

## Where the strings live

| Client | Khmer | English | Notes |
|---|---|---|---|
| Web portal | `frontend/src/messages/km.json` | `frontend/src/messages/en.json` | `next-intl`, nested by page (`app`, `portal`, `download`…). Loaded in `frontend/src/i18n/request.ts` |
| App | `mobile/lib/l10n/app_km.arb` | `mobile/lib/l10n/app_en.arb` | Flutter `gen-l10n`. `app_en.arb` is the template: every key has an `@key` entry with a `description` there |
| Android system strings | `mobile/android/app/src/main/res/values-km/strings.xml` | `.../res/values/strings.xml` | Notification channel names and the like |
| Docs | `CONTRIBUTING.km.md`, Khmer sections in `README.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `GOVERNANCE.md` | the English files | Lines still awaiting a native check carry `[km-review]` |

On 2026-09-30 both clients had exactly the same key set in `km` and `en`. Keep it that way.

## Adding or changing a string

1. Add the key to **both** files in the same PR. Keep the same nesting (portal) or the same key
   (app).
2. **App only:** add `"@yourKey": { "description": "…" }` to `app_en.arb`. Say where the string
   appears and any length limit. Translators see only this description, not the screen.
3. Placeholders stay in English exactly as written: `{year}`, `{count}`, `{name}`. Translate the
   words around them, never the placeholder.
4. Plurals and selects (`{count, plural, …}`) keep their structure in both languages. Khmer has no
   grammatical plural, so the `other` branch is usually enough, but keep the ICU syntax valid.
5. Regenerate and test:
   - App: `cd mobile && flutter gen-l10n && flutter test`
   - Portal: `cd frontend && npm test -- --run`
6. If you can't write the Khmer, put the English in `km` too, mark it in the PR description, and add
   the `translation-km` label. A Khmer speaker will fix it before release. Never leave a key out.

## Khmer style rules

- **Plain, everyday Khmer.** Write for a worried family member at 2am, not for a government letter.
  Prefer "ត្រូវការឈាមបន្ទាន់" over a formal construction.
- **Numbers:** use Khmer digits (០១២៣៤៥៦៧៨៩) in running Khmer text where the existing strings do. Keep
  Western digits for blood units, distances, phone numbers and dates that are shown next to an input.
  Follow what the surrounding strings already do.
- **Blood types stay Latin:** `A+`, `O-`, `AB+`. Never transliterate them.
- **Keep product names:** "LifeLink KH". The Khmer brand is "ជីវិត", used as "ជីវិត — LifeLink KH" in
  titles.
- **Spaces:** Khmer has no spaces between words. Use a space only between phrases, as in normal Khmer
  writing, and before and after Latin words and numbers.
- **Punctuation:** end sentences with `។`. Use `៖` before a list or an explanation.
- **Font:** both clients use **Kantumruy Pro** for Khmer. If a glyph shows as a box, report it; don't
  work around it with a different character.
- **Medical terms** follow the National Blood Transfusion Center's usage (DEC-019):
  - មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម (NBTC)
  - ការបរិច្ចាគឈាម (blood donation)
  - អ្នកបរិច្ចាគឈាម (blood donor)
  - ក្រុមឈាម (blood group)

  Mark any term you are unsure of `[km-review]` in the PR.

## Review

- Every Khmer change is reviewed by a native Khmer speaker before a release. Label the PR
  `translation-km`.
- Reviewers check meaning first, then tone, then spelling.
- A reviewer who fixes a docs line removes its `[km-review]` marker.
- Found a bad string in the app or on the website? Open a **Translation / ការបកប្រែ** issue
  (`.github/ISSUE_TEMPLATE/translation.yml`) with a screenshot.

## Known gap

There is no automated check yet that `km` and `en` have the same keys. The counts match today, but
nothing enforces it. A small parity check in `scripts/verify-all.sh` has been proposed; it is not
added yet (Tech Lead to approve).
