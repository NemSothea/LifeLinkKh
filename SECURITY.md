# Security policy · គោលការណ៍សុវត្ថិភាព

LifeLink KH stores health-adjacent personal data: blood type, district, coarse location and donation
dates. A security bug here can expose a donor, so please report it privately.

LifeLink KH រក្សាទុកព័ត៌មានផ្ទាល់ខ្លួនទាក់ទងនឹងសុខភាព (ក្រុមឈាម ទីតាំង កាលបរិច្ឆេទបរិច្ចាគ)។
ប្រសិនបើអ្នករកឃើញចំណុចខ្សោយផ្នែកសុវត្ថិភាព សូមរាយការណ៍ដោយសម្ងាត់ កុំបង្ហោះជាសាធារណៈ។ `[km-review]`

## How to report · របៀបរាយការណ៍

1. **Do not open a public issue, Discussion, Telegram or Facebook post.**
   **កុំបើក issue សាធារណៈ ឬបង្ហោះលើ Telegram / Facebook។** `[km-review]`
2. Use GitHub's private reporting: **Security → Report a vulnerability** on
   <https://github.com/NemSothea/LifeLinkKh/security/advisories/new>.
3. Include what you found, where (URL, file, screen), steps to reproduce, and what data it could expose.
   Khmer or English are both fine. · អាចសរសេរជាភាសាខ្មែរ ឬអង់គ្លេស។

## What happens next

| Step | Target |
|---|---|
| We acknowledge your report | within 3 days |
| We confirm or rule it out | within 7 days |
| Fix for a confirmed high-severity issue (personal data exposure, auth bypass) | as fast as we can, aim ≤14 days |
| Credit | in the advisory and `CHANGELOG.md`, unless you ask to stay anonymous |

The maintainers are volunteers, so these are targets, not guarantees. We will keep you told either way.

## In scope

- The web portal and its server functions: `frontend/`, including `frontend/src/server/` and
  `/api/functions/*`. Live site: <https://lifelinkkh.vercel.app>.
- Firestore Security Rules: `firebase/firestore.rules`.
- The Android and iOS app: `mobile/`, and the APK published on GitHub Releases.
- Anything that lets someone read another person's contact, location or donation data, act as an
  admin, send pushes, or approve requests.

## Out of scope

- Firebase client API keys in `google-services.json` and `GoogleService-Info.plist`. These are
  public by design; report them only if you can show one is **unrestricted** and can be abused.
- Denial of service, load or spam testing against the live site or the `lifelinkkh` project.
  Please test on the local emulators (`CONTRIBUTING.md`) instead.
- Social engineering of maintainers, donors or hospitals.
- Findings from automated scanners with no demonstrated impact.

## Rules for testing

- Use your own accounts and the Firebase emulators. Never access, change or keep real donors' data.
- If you reach real personal data by accident, stop, do not copy it, and tell us in your report.

We follow the security baseline in `docs/security/asvs-baseline.md`. Past reviews are in
`docs/security/reviews/`.
