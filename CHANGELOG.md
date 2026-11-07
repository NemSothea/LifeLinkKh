# Changelog · កំណត់ហេតុការផ្លាស់ប្តូរ

All notable changes to LifeLink KH are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow the Android app's
`version:` in `mobile/pubspec.yaml`. Each release has a short Khmer summary.

Owner: PO (Sourn Savourn). The Tech Lead adds the release entry when a release is cut (Phase 5 steps).

## [Unreleased]

### Launch · ការចាប់ផ្តើម
- Public community launch: `[LAUNCH_DATE]`. Fill this in on the day the posts in
  `docs/community/launch-posts.md` go out.

### Changed
- CI also runs on pushes to `feat/firebase-backend`, the default branch.
- Dependabot no longer proposes the Flutter codegen toolchain (`build_runner`, `drift`, `drift_dev`,
  `riverpod_generator`), Riverpod majors, or `sqlite3_flutter_libs` 0.6. These move by hand with the
  pinned Flutter.

### Security
- Dependency fixes for open Dependabot alerts, including two high-severity ones (`joi`, `re2js`).

## [1.0.1] - 2026-10-25

> **ខ្មែរ** (reviewed by Nem Sothea, 2026-11-07)៖ រូបតំណាងដែលអ្នកជ្រើសរើស ត្រូវបានរក្សាទុកក្នុងគណនី។ កំណែនេះចុះហត្ថលេខាដោយកូនសោថ្មី
> ដូច្នេះអ្នកដែលមាន 1.0.0 ត្រូវលុបវាចេញម្តងសិន រួចដំឡើងកំណែនេះ។ រឿងនេះកើតឡើងតែម្តងនេះប៉ុណ្ណោះ។

### Added
- The avatar you pick is saved to your account, not only to the phone.

### Changed
- **Signed with a new key.** Users of 1.0.0 must uninstall once before installing. Every release
  from 1.0.1 on installs over the previous one. Signing certificate SHA-256:
  `2C:68:FD:65:C4:40:80:F5:EE:5E:A1:DF:96:BD:A8:E4:29:41:FF:88:A1:8C:21:C4:90:7F:67:68:95:12:66:3D`.

### Fixed
- The release script reads the APK signing certificate with `apksigner`.

## [1.0.0] - 2026-10-01

> **ខ្មែរ** (reviewed by Nem Sothea, 2026-11-07)៖ កំណែសាធារណៈដំបូងសម្រាប់ Android។ ចុះឈ្មោះជាអ្នកបរិច្ចាគ ដាក់សំណើឈាមបន្ទាន់
> ទទួលការជូនដំណឹង និងមើលប្រវត្តិបរិច្ចាគ ព្រមទាំងពេលដែលអ្នកអាចបរិច្ចាគម្តងទៀត។

First public release for Android, on GitHub Releases with an install guide at `/download`.

### Added
- Donor registration: blood type, location (GPS), and last donation date, with an eligibility check
  (90 days for men, 120 for women, DEC-019).
- Urgent requests: an admin reviews each one (DEC-015), then matching donors get a push alert,
  filtered by ABO/Rh and distance.
- Donation history, and a reminder when a donor can donate again.
- A notification inbox beside every push, on a high-importance channel.
- Medical disclaimer on the app's About screen and in the portal footer.
- Portal SEO: sitemap, robots, hreflang, canonical and JSON-LD. The public board is `noindex`.
- A link to the handbook (https://nemsothea.github.io/LifeLinkKh/) from the portal footer and the README.
- APK on GitHub Releases with a `.sha256`, a QR code and an install guide.

### Fixed
- The intro slide now says "every 3–4 months" instead of 56 days (DEC-019).
- Sign-in keeps the username and "Remember" after a failed attempt.

[Unreleased]: https://github.com/NemSothea/LifeLinkKh/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/NemSothea/LifeLinkKh/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/NemSothea/LifeLinkKh/releases/tag/v1.0.0
