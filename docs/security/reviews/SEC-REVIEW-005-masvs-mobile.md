---
id: SEC-REVIEW-005
feature: Mobile app (Flutter, Android + iOS) against the mobile standard
date: 2026-09-30
verdict: fail
reviewer: Security (Tech Lead overlay)
standard: OWASP MASVS v2.1.0, MAS baseline profile (L1)
follows: SEC-REVIEW-004-remediation.md
---

## Why this review exists

`../asvs-baseline.md` measures the whole system against OWASP ASVS 5.0.0 Level 1 — a **web**
standard. It covers the app only where a web control happens to land on it (https-only links,
wiping local data at sign-out). The mobile standard is **OWASP MASVS**. Before the app, the
public security page or the NBTC letter says "reviewed against OWASP MASVS", this review has to
exist and its findings have to be closed or accepted.

## Standard

OWASP MASVS **v2.1.0**, control IDs and statements copied from the tagged source
(`github.com/OWASP/masvs`, tag `v2.1.0`, `controls/`) on 2026-09-30 — 24 controls in 8 groups.
MASVS v2 has no L1/L2 levels any more; the MAS project moved them into "MAS Profiles"
(`Document/03-Using_the_MASVS.md`, "MAS Testing Profiles"). **Chosen profile: L1 (baseline)**,
the same level as ADR 0005 chose for ASVS. At L1, NETWORK-2 (pinning) and the RESILIENCE group
are out of profile; they are recorded, not failed.

## Scope reviewed

`mobile/` on `feat/firebase-backend` at `2810a0f`: `lib/`, `android/app/src/main/`,
`ios/Runner/`, `pubspec.yaml`/`.lock`, the debug merged manifest, `scripts/build-release-apk.sh`,
`.github/`. Server-side controls the app relies on (`firebase/firestore.rules`,
`frontend/src/server/`) are cited, not re-reviewed — `SEC-REVIEW-003/004` own them.
Static review only: no dynamic testing (Frida, MobSF, traffic interception) was done.

## Results by control

**Pass** = holds, with evidence. **Partial** = holds in part; the gap is a numbered finding.
**Fail** = does not hold. **Out of profile** = not required at L1. **N/A** = the feature does not
exist here.

| Control | Statement (v2.1.0) | Verdict | Evidence | Gap |
|---|---|---|---|---|
| STORAGE-1 | The app securely stores sensitive data. | Partial | Session in `flutter_secure_storage` (Keystore / Keychain), `features/auth/data/secure_session_store.dart:17,62-70`; Drift DB holds only match ids, answers and the sync queue, no names or phones, `core/database/app_database.dart:18-53`; all of it wiped at sign-out and deletion, `features/auth/application/local_data_eraser.dart:35-53` (F-07) | Firestore's offline cache (requester phones, own name and coordinates) is unencrypted at rest while signed in — accepted at L1, platform sandbox only |
| STORAGE-2 | The app prevents leakage of sensitive data. | Partial | Only log line is `kDebugMode`-guarded, `core/error/crash_handling.dart:29` (F-20); lock-screen push shows blood type and hospital, no name or phone, `frontend/src/server/push.js:9-12,74-76` | **M-02** backup on; **M-09** phone copied to clipboard unmarked |
| CRYPTO-1 | The app employs current strong cryptography … | N/A | No crypto package (`pubspec.yaml`); TLS and Keystore/Keychain via SDKs | — |
| CRYPTO-2 | The app performs key management … | N/A | No app-managed keys | — |
| AUTH-1 | The app uses secure authentication and authorization protocols … | Pass | Google/Facebook through Firebase Auth; self-service roles clamped, `features/auth/data/firebase_auth_repository.dart:40-60`; session restored only if the Firebase uid matches, `features/auth/application/auth_service.dart:110-136`; portal calls carry the Firebase ID token, `core/api/functions_portal_api.dart:22`; every read/write authorised by the rules | — |
| AUTH-2 | The app performs local authentication securely … | N/A | No local authentication (`local_auth` absent) | — |
| AUTH-3 | The app secures sensitive operations with additional authentication. | Pass | Account deletion re-authenticates first, `features/account/application/account_deletion_service.dart:55-57`; server checks `auth_time`, `frontend/src/server/delete-account.js:129` | — |
| NETWORK-1 | The app secures all network traffic … | Pass | Portal and config links https-only outside debug, `core/config/env.dart:52-66`, `features/update/domain/app_config.dart:107-109` (F-15); no cleartext flag, no ATS exception | **M-11** emulator host not limited to debug |
| NETWORK-2 | The app performs identity pinning … | Out of profile | No pinning | Accepted at L1 (M-13) |
| PLATFORM-1 | The app uses IPC mechanisms securely. | Pass | Only the launcher activity and the Facebook OAuth redirect are exported, `android/app/src/main/AndroidManifest.xml:16-37,63-72`; SDK receivers permission-guarded; no app deep links; push taps route by a known `type` list and a match must be in the user's inbox, `app.dart:173-195` | **M-10** `requestId` from a push not validated |
| PLATFORM-2 | The app uses WebViews securely. | Pass | No WebView; `url_launcher` always external, `core/links/link_opener.dart:24` | — |
| PLATFORM-3 | The app uses the user interface securely. | Partial | Requester phone shown only after acceptance, from the rules-protected `requests/{id}/private/contact`, `features/match/presentation/match_detail_screen.dart:327-341` | **M-09** no screenshot / app-switcher protection |
| CODE-1 | The app requires an up-to-date platform version. | Pass | Android minSdk 24 / targetSdk 36 (Flutter defaults, `android/app/build.gradle.kts:42-43`); iOS 15.0, `ios/Podfile:2` | — |
| CODE-2 | The app has a mechanism for enforcing app updates. | Pass | `minVersionCode` in `config/app` shows a non-dismissable block, `features/update/domain/app_update.dart:57,92-99`, `features/update/presentation/update_gate.dart:97-98` | — |
| CODE-3 | The app only uses software components without known vulnerabilities. | Partial | Dependabot for `pub`, `.github/dependabot.yml:24-30`; lockfile current (2026-09-30) | **M-06** no vulnerability scan; Dependabot inactive until main |
| CODE-4 | The app validates and sanitizes all untrusted inputs. | Pass | Phone normalised and validated, `core/phone/cambodian_phone.dart:24,47`; report note ≤ 500 in app and rules, `features/report/presentation/report_request_sheet.dart:124`, `firebase/firestore.rules:170-177`; every request field re-checked server-side, `frontend/src/server/create-request.js:34-42` | M-10 |
| RESILIENCE-1..4 | Platform integrity, anti-tampering, anti-static, anti-dynamic analysis. | Out of profile | None: no root/jailbreak check, no App Check, no obfuscation | **M-07**, **M-08** recorded as hygiene |
| PRIVACY-1 | The app minimizes access to sensitive data and resources. | **Fail** | Location asked only on "use my current location", `features/donor/presentation/donor_setup_screen.dart:318-323`, at medium accuracy | **M-04** exact coordinates stored; **M-01** iOS purpose string missing; fine location requested |
| PRIVACY-2 | The app prevents identification of the user. | **Fail** | No analytics, crash-reporting or ads SDK | **M-03** Facebook SDK auto-logs app events; `AD_ID` merged in |
| PRIVACY-3 | The app is transparent about data collection and usage. | Partial | Privacy policy linked before sign-in and in About, `features/auth/presentation/sign_in_screen.dart:289-294`, `features/about/presentation/about_screen.dart:134-140`; reason given for sex and location, `l10n/app_en.arb:190,1055` | **M-05** no iOS privacy manifest |
| PRIVACY-4 | The app offers user control over their data. | Pass | In-app account deletion (DEC-016); availability toggle stops alerts; donor profile editable; no data export | Export accepted at L1 (M-13) |

Paths without a prefix are under `mobile/lib/src/`.

**Tally (24 controls):** 9 pass · 5 partial · 2 fail · 3 N/A · 5 out of profile (NETWORK-2 and
RESILIENCE-1…4).

## Findings

| ID | Sev | Where | Finding | Fix |
|---|---|---|---|---|
| M-01 | Medium | `ios/Runner/Info.plist` (key missing) | No `NSLocationWhenInUseUsageDescription`. iOS refuses the permission request; `requestPermission()` sits outside the `try` in `core/location/device_location_service.dart:20`, so "use my current location" can hang. App Store review would reject the build. | Add the purpose string (km + en); move the permission calls inside the `try` |
| M-02 | Medium | `android/app/src/main/AndroidManifest.xml:12` | `allowBackup` defaults to on: the Firestore cache and `lifelink.sqlite` can leave the device in a cloud backup or device transfer. | `android:allowBackup="false"` (or `dataExtractionRules` excluding `databases/`, `files/`); iOS: exclude the DB and cache folders from backup |
| M-03 | Medium | `Info.plist:42-47`, `android/.../res/values/strings.xml`, merged manifest | The Facebook SDK logs app install/activate events by default, and the `AD_ID` / adservices permissions are merged in — contradicts "no advertising or analytics tracking" on the privacy page. | `FacebookAutoLogAppEventsEnabled` and `FacebookAdvertiserIDCollectionEnabled` = false on both platforms; remove `AD_ID` and adservices with `tools:node="remove"` |
| M-04 | Medium | `features/donor/data/firestore_donor_repository.dart:76-92`, `core/location/geohash.dart:7` | Raw lat/lng and a 10-character geohash (~1 m) are stored, while the manifest comment and ADR 0003 promise ~0.5 km rounding. | Round to 3 decimals and a 6-character geohash before writing; tighten `firebase/firestore.rules:55`; drop `ACCESS_FINE_LOCATION` |
| M-05 | Low | `ios/` (file missing) | No `PrivacyInfo.xcprivacy`. | Add one: required-reason APIs (UserDefaults) and collected data types |
| M-06 | Low | `.github/workflows/ci.yml:108-117`, `.github/dependabot.yml:6-7` | No vulnerability scan of `pubspec.lock`; Dependabot runs only once the file is on the default branch. | `osv-scanner --lockfile mobile/pubspec.lock` step in CI |
| M-07 | Low | `scripts/build-release-apk.sh:41` | Release builds are not obfuscated. | `--obfuscate --split-debug-info=build/symbols` (symbols kept out of git) |
| M-08 | Low | `android/app/build.gradle.kts:66-70` | A release build without `key.properties` is silently signed with the debug key. | Fail the release task when signing config is missing |
| M-09 | Low | `features/match/presentation/match_detail_screen.dart:340-357` | Requester phone: no screenshot / app-switcher protection; copied to the clipboard unmarked and never cleared. | Mark the clip sensitive (Android 13+); optional `FLAG_SECURE` on match and request detail |
| M-10 | Low | `app.dart:174-185`, `features/request/presentation/request_detail_screen.dart:33` | `requestId` from a push payload is routed unvalidated (only the server sends FCM, so low). | Check against `^[A-Za-z0-9_-]{1,128}$` before routing (same as the portal's `ids.js`) |
| M-11 | Low | `lib/main.dart:54-57` | `FIRESTORE_EMULATOR` is honoured in release builds. | `if (kDebugMode && emulator != null)` |
| M-12 | Low | `ios/Runner/Info.plist:56-57` | Dev-only `NSLocalNetworkUsageDescription` ships in release. | Remove, or move to a Debug-only plist |
| M-13 | Info | — | No certificate pinning, no data export. | Record as accepted L1 decisions in `../asvs-baseline.md` |

## Verdict & conditions

**Fail** at the L1 profile: PRIVACY-1 and PRIVACY-2 do not hold, and M-01 is a functional bug
on iOS. Nothing here exposes one user's data to another user — the Firestore rules still decide
every read — but the app collects more precisely, and shares more with Facebook, than its own
privacy page says.

**Until M-01 to M-04 are fixed, nothing public — the security page, the About screen, the NBTC
letter, the defense slides — may say the app meets or was verified against OWASP MASVS.** It
may say "reviewed against OWASP MASVS v2.1.0; fixes in progress", linking this review.

Re-review (SEC-REVIEW-006) after M-01…M-04, M-11 and M-12 land; M-05…M-10 may be accepted with a
dated reason instead.
