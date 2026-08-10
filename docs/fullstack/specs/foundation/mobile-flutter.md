---
id: SPEC-FOUNDATION-MOBILE-FLUTTER
owner: Fullstack (consumed by Mobile)
status: draft
milestone: M2
---

# Foundation Spec — Flutter Mobile App

Scope of this spec: the project shape the Flutter app is created with at M2. Milestone dates are in
root `CLAUDE.md` section 4 — not repeated here.

## What M2 delivers

A Flutter project in `mobile/` that:

- builds and runs on an Android emulator,
- boots to a stub home screen showing the app name in the active locale,
- reads the API base URL from build config (no hardcoded host),
- has Khmer and English ARB files wired with at least one real string each.

No feature screens. No auth. No network calls beyond an optional health ping.

## Project identity

| Field | Value |
|---|---|
| Flutter package (pubspec `name`) | `lifelink_kh` |
| Android application ID | `kh.lifelink.app` — `flutter create --org kh.lifelink` produced `kh.lifelink.lifelink_kh`, so the Gradle `namespace` + `applicationId` and the Kotlin `MainActivity` package were all rewritten to match this spec at init |
| Flutter / Dart SDK | **Flutter 3.44.6 · Dart 3.12.2** — pinned at init 2026-08-10, `environment: sdk: ^3.12.2` |
| Platforms generated | `--platforms=android` only. iOS is deferred (`../../../../CLAUDE.md`), so no `ios/` directory exists to maintain |
| Pinned deps | `flutter_riverpod ^3.4.2`, `go_router ^17.4.0`, `dio ^5.11.0`, `intl 0.20.2` (exact — see below), `flutter_localizations` from SDK |

The Android application ID is effectively permanent — it is the Play Store identity and cannot be
changed after the first upload to internal testing (M7). Confirm it before the first build.

## Folder structure

Feature-first, so M3–M6 features land in isolated directories rather than growing shared folders:

```
mobile/
  lib/
    main.dart
    app.dart                  # MaterialApp.router, theme, locale delegate wiring
    core/
      config/env.dart          # API base URL from dart-define
      network/api_client.dart  # Dio instance + interceptors
      router/app_router.dart   # go_router route table
      theme/app_theme.dart
    features/
      home/                    # the only feature at M2 (stub screen)
        presentation/home_screen.dart
    l10n/
      app_en.arb
      app_km.arb
  l10n.yaml
  test/
```

Each later feature gets `features/<name>/{data,domain,presentation}/`. M2 creates only `home/` and
does not pre-create empty layer folders for features that do not exist yet.

## Decided dependencies

| Concern | Choice | Reason |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod`) | Providers are compile-time checked and testable without pumping a widget tree, and its async primitives model API loading/error states directly — which is most of this app. Bloc was rejected as more boilerplate than a 13-week project needs; `provider` was rejected as less type-safe. |
| Routing | **go_router** | Declarative routes with deep-link support. M5 requires tapping an FCM notification to open a specific request detail — that is a deep link, and go_router handles it without hand-rolled navigator plumbing. |
| HTTP client | **Dio** | Interceptors are needed for attaching the JWT bearer token (M3) and for retry/timeout on the urgent-request path. Plain `http` would mean writing that per call site. |
| Localization | `flutter_localizations` + `intl`, ARB files, `l10n.yaml` | Flutter's first-party path. No third-party i18n package. |

> These are architecture decisions recorded in a spec, which is the wrong place for them long-term.
> **Both the state-management and routing choices owe an ADR** in `docs/tech-lead/adr/` — see the
> follow-ups at the end of this spec.

## Configuration

The API base URL is passed at build time, never committed:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`core/config/env.dart` reads it via `String.fromEnvironment('API_BASE_URL')` and fails fast with a
clear error if it is empty. `10.0.2.2` is the Android emulator's alias for the host machine, which
is where `docker-compose` publishes the backend — see `infra-docker.md`.

Never commit a `.env`, keystore, `google-services.json`, or any API key. Secrets referenced by name
only, per `docs/security/security-checklist.md`.

## Localization

- `lib/l10n/app_km.arb` and `app_en.arb`. **Khmer is the default locale** (`prd.md` section 5).
- `l10n.yaml` sets `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`.
- M2 ships one string (`appTitle`) in both files, proving the pipeline works end to end.
- Khmer text is taller and longer than English. Any widget with a fixed height or width that holds
  text is a defect waiting for M6 — prefer intrinsic sizing from the start.

## Deferred to later milestones

| Deferred | Milestone |
|---|---|
| Google Sign-In + JWT storage, donor profile screens | M3 |
| Urgent request create, responders list | M4 |
| FCM integration, notification deep links, donation history | M5 |
| `geolocator` / `google_maps_flutter`, full Khmer/English string sweep | M6 |
| Signed AAB, Play Store internal testing | M7 |

## Contract gaps

`docs/fullstack/api-contract/mobile/openapi.yaml` currently has `paths: {}` — no endpoint is
defined. M2 needs exactly one:

- `GET /api/health` — unauthenticated liveness check, so the app can prove config wiring works.

Per `docs/cheat-sheet.md` the contracts are filled during `/capybara-adk:plan`. This spec does not
edit them. Mobile requests changes via CR-MAPI
(`docs/fullstack/api-contract/mobile/change-requests.md`).

## Done when

- [ ] `mobile/` contains a Flutter project named `lifelink_kh` with application ID `kh.lifelink.app`.
- [ ] `flutter analyze` reports zero issues.
- [ ] `flutter test` passes (the default widget test is enough at M2).
- [ ] App launches on an Android emulator and shows the stub home screen.
- [ ] Launching without `--dart-define=API_BASE_URL` produces a clear startup error, not a silent
      default or a crash.
- [ ] Switching device language between Khmer and English changes the visible app title.
- [ ] `riverpod`, `go_router`, `dio`, `flutter_localizations`, and `intl` are in `pubspec.yaml` with
      pinned versions.
- [ ] No secret, keystore, or `google-services.json` is committed.
- [ ] Folder structure matches the tree above, with no empty placeholder feature directories.

## Follow-ups this spec does not resolve

- **ADR owed** for state management (Riverpod) and routing (go_router). Decided here to keep M2
  buildable; the record needs to catch up. Still owed as of 2026-08-10 — both are now in the code.
- **Application ID `kh.lifelink.app` needs confirming** before the first Play Store upload. Now set
  in `android/app/build.gradle.kts`; it is permanent after the first internal-testing upload.
- ~~`GET /api/health` must reach the mobile API contract~~ — it was already there.

### Learned at init, 2026-08-10

- **`intl` must be pinned exactly to `0.20.2`.** `flutter_localizations` from the SDK depends on
  exactly that version, so `intl: ^0.20.3` makes version solving fail outright. Do not "upgrade" it.
- **Riverpod 3 retries a failed provider automatically.** An error state therefore flips back to
  loading on its own, which makes it untestable by default — widget tests pass
  `ProviderScope(retry: (_, _) => null)`. Worth knowing before M4, where request submission has a
  real failure path a user must see.
- Android build verified: `flutter build apk --debug --dart-define=API_BASE_URL=…` produces
  `app-debug.apk`. Launch on an emulator is still a **manual** check — QA records it, per
  `../../../qa/test-strategy.md`.
