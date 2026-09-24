---
id: BUG-MOBILE-005
title: Every donor with a profile hits "Failed to load libsqlite3.so" on Home — the APK ships no SQLite
area: MOBILE
severity: blocker
status: fixed
found_in: device rehearsal 2026-09-24, Android emulator API 36 (fixed same day)
reported_by: QA
---
## Steps to reproduce
1. Install the app on a real Android device or emulator.
2. Sign in with Google and complete a donor profile.
3. Open the Home tab.

## Expected
The "requests near you" section lists matched alerts, or shows its empty state.

## Actual
The section renders the retry/failure card. The network call succeeded — `GET /matches/me` answered
**200** — and the failure is local:

```
Unhandled Exception: Invalid argument(s): Failed to load dynamic library
'/data/data/com.kosign.lifelinkkh/lib/libsqlite3.so': dlopen failed: library not found
  at OfflineFirstMatchRepository.fetchMine (offline_first_match_repository.dart:34)
  at MyMatchesController.build (match_providers.dart:61)
```

`unzip -l app-debug.apk | grep sqlite` returned nothing: no `libsqlite3.so` for any ABI.

## Cause
`pubspec.yaml` carried `sqlite3_flutter_libs: ^0.6.0+eol`. That release is an **empty package** —
its own README says "starting from version 0.6.0, this package no longer does anything" — published
so that apps which have migrated to `sqlite3` **3.x** can assert the old Flutter build scripts are
gone. Drift 2.28 here still resolves `sqlite3` **2.9.4**, which gets its native library from exactly
that package. So the dependency that bundles SQLite quietly stopped bundling it, and Gradle happily
built an APK without it.

## Fix
Pinned `sqlite3_flutter_libs: ^0.5.41` (resolved 0.5.42), the last line that ships the library, with
a comment in `pubspec.yaml` explaining why it must not be "upgraded" to 0.6.0. Verified: all three
ABIs now carry `libsqlite3.so`, and the section renders its empty state on the device.

## Why no test caught it
Every test runs on macOS, which has a system SQLite that `sqlite3` 2.x falls back to, so the Drift
path opens fine on the host. The failure needs three things at once — a real Android install, an
account **with a donor profile**, and the Home tab — and the mobile suite has none of them.

`flutter analyze`, 189 unit/widget tests and CI were all green across the release that introduced it.

## Notes
- The same missing library would have broken donation history and the offline accept/decline queue,
  both of which read the same database. Home is simply the first screen to touch it.
- Worth a standing check before any release: `unzip -l <apk> | grep libsqlite3`. A dependency can
  stop shipping a native library without anything in Dart changing.
