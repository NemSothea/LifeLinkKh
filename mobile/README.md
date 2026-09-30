# LifeLink KH — Flutter app (ជីវិត)

Blood-donor matching for Cambodia. This is the donor/patient mobile client. It talks to
Firebase directly — Auth, Firestore and Cloud Messaging, with the Cloud Functions and
Security Rules in [`firebase/`](../firebase/) — and has no backend of its own
([ADR 0009](../docs/tech-lead/adr/0009-firebase-replaces-spring-boot-and-postgres.md)).
The Next.js portal lives alongside it (see the root [`README.md`](../README.md)).

**Owner:** Nem Sothea — Tech Lead / Mobile.
**Track:** B (team product). The FieldLog exercises in
[`docslesson/`](docslesson/) are Track A, but their *architecture rules* are what this
app is built to, so they are kept here next to the code they govern.

## Run it

Two things are needed before the app will build, and one of them is not in this repo.

**1. `android/app/google-services.json`.** Download it from the Firebase console —
Project settings → the Android app registered as `com.kosigndemo.lifelinkkh` → `google-services.json`
— and drop it in `mobile/android/app/`. Without it the build fails outright at
`:app:processDebugGoogleServices`, which is the failure we want: the alternative is Google
Sign-In failing silently at runtime.

The file is **committed on purpose** (see the note in the root `.gitignore`). It is client
configuration, not a secret: the Android API key inside it is restricted by package name
and SHA-1 fingerprint. The file that must never be committed is a service-account key.

**2. The debug SHA-1 fingerprint, registered on that Android app.** Sign-In fails with no
useful error if it is missing — `docs/scope.md` calls it the single most common wasted
afternoon on a project of this shape.

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | grep SHA1
```

Then, against the real `lifelinkkh` Firebase project:

```bash
flutter run
```

Or against a local Firestore emulator (`firebase/README.md` starts one):

```bash
flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081
```

`10.0.2.2` is the Android emulator's alias for the host machine, where the emulator suite
listens. Nothing else is configured at build time; `lib/src/core/config/env.dart` lists the
two optional `--dart-define`s.

Code generation — leave this running while developing:

```bash
dart run build_runner watch -d
```

## iOS build (M6, build-only)

DEC-006 put iOS in scope as a **build target only**: the app compiles and runs on a
simulator or a tethered device, and that is where it stops. No signing, no TestFlight, no
App Store, no Apple Developer account. Play Store internal testing (M7) is still the only
store release in scope.

Proven on Xcode 27.0 / Flutter 3.44.6, all three configurations:

```bash
flutter build ios --simulator --debug     # build/ios/iphonesimulator/Runner.app
flutter build ios --no-codesign --debug   # build/ios/iphoneos/Runner.app
flutter build ios --no-codesign --release # build/ios/iphoneos/Runner.app, 34.7 MB
```

The iOS half uses **CocoaPods**, not Swift Package Manager: `firebase_messaging` pulls in
FirebaseCore, and the SwiftPM path left the workspace without a resolvable Flutter
framework. `ios/Pods/` is gitignored; `Podfile` and `Podfile.lock` are committed, so
`pod install` reproduces the same pod versions.

Two Xcode 27 traps are already worked around in this repo. Both fail *before* any of our
code compiles, so neither error mentions LifeLink at all.

**1. `lipo` no longer takes two architectures.** Xcode 27's `lipo` answers
`-verify_arch requires exactly one input file` when handed `arm64 x86_64` together, and
Flutter 3.44.6's `thinFramework` (`flutter_tools/.../build_system/targets/darwin.dart`)
still passes both in one call. A two-architecture simulator build therefore dies in the
scheme's *pre-action* with a message that contradicts itself — it claims the framework
lacks `arm64 x86_64` and then prints a `lipo -info` showing both. `flutter build` hides
this entirely behind `Uncategorized (Xcode): Exited with status code 255`; the real text
only appears by running `xcodebuild` on `Runner.xcworkspace` directly.

`ios/Flutter/Debug.xcconfig` pins `ARCHS[sdk=iphonesimulator*] = arm64`, which leaves one
architecture and so one argument. `EXCLUDED_ARCHS` does **not** work here — the pre-action
script reads `ARCHS` before exclusions apply. This assumes an Apple Silicon Mac, where
arm64 is the only simulator architecture that runs natively anyway. On an Intel Mac, drop
that line and upgrade Flutter instead.

**2. Pods below iOS 15.0 are rejected outright.** Xcode 27 supports 15.0–27.0 only, and
`flutter_additional_ios_build_settings` still leaves some pods at 12.0:
`The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 12.0, but the range of
supported deployment target versions is 15.0 to 27.0.x`. The `post_install` hook in
`ios/Podfile` raises every pod to 15.0, matching the Runner target.

`ios/Runner/GoogleService-Info.plist` is committed for the same reason
`google-services.json` is — client configuration, restricted by bundle ID, not a secret.

## Architecture — four layers, one direction

```
        ┌──────────────┐
        │ presentation │   widgets. ConsumerWidget, no setState
        └──────┬───────┘
               ▼
        ┌──────────────┐
        │ application  │   services + Riverpod providers/notifiers
        └──────┬───────┘
               ▼
        ┌──────────────┐        ┌──────────────┐
        │   domain     │ ◀───── │     data     │
        └──────────────┘        └──────────────┘
       entities, abstract        concrete repositories
       repositories              (Firestore today, anything later)
```

Every arrow points inward. A layer may name what it points at and nothing else, which
gives the two properties the whole structure exists for:

- **`presentation/` cannot name `data/`.** A screen imports `application/` for providers
  and `domain/` for entity types. It never learns that Firestore exists.
- **The concrete implementation is named in exactly one file** —
  `application/donation_providers.dart`, the composition root. Swapping the transport, or
  substituting a fake in a test, is a one-line change there and nowhere else — which is
  how ADR 0009 moved every feature off the old REST backend without touching a screen.

`application/` importing `data/` is the one deliberate outward arrow. It is what buys
the isolation above.

### The donation feature, as laid out on disk

```
lib/
  main.dart                        runApp() ONLY — no logic, no theme, no routes
  l10n/                            generated by flutter gen-l10n, not hand-written
  src/
    app.dart                       root widget: MaterialApp.router, theme, locales
    router/app_router.dart         every route, declared. No Navigator.push anywhere
    core/
      config/env.dart              build-time config (optional --dart-defines)
      firebase/firestore_providers.dart  the Firestore instance + current uid
      theme/app_theme.dart         Material 3 from one seed, light + dark
    features/donation/
      domain/
        donation.dart              final class, value equality, no Flutter import
        donation_repository.dart   abstract interface
      data/
        firestore_donation_repository.dart  implements DonationRepository
      application/
        donation_service.dart      the Service — pure Dart, no Riverpod import
        donation_providers.dart    @riverpod providers  (+ .g.dart, generated)
      presentation/
        donation_history_screen.dart  ConsumerWidget
```

### The Service, against the six rules

`DonationService` is a pass-through today because reading one list has nothing to
orchestrate. The seam is still worth having: `AuthService` has a sign-in, a session restore
and a sign-out to sequence, and it sits in exactly this position.

| Rule | How it holds here |
|---|---|
| S1 one per feature | `DonationService`, not an `AppService` |
| S2 stateless | no instance field holds UI state |
| S3 returns domain types | returns `Result<List<Donation>>`, never a Firestore snapshot |
| S4 depends on abstractions | constructor takes `DonationRepository`, not the Firestore one |
| S5 no Flutter import | `test/donation_service_test.dart` needs no widget tree |
| S6 orchestrates, doesn't render | builds no widgets |

## Testing

```bash
flutter analyze && flutter test
```

Three levels, and the level is chosen by what is being proven:

- `donation_service_test.dart` — the Service with a plain stub. No Riverpod, no widgets.
- `home_screen_test.dart` — the screen, with the repository providers overridden at the
  **repository** seam rather than at the provider nearest the widget. Everything above the
  transport is therefore exercised for real.
- `firestore_*_repository_test.dart` — each repository against `fake_cloud_firestore`. What
  the Security Rules allow is tested separately, against the real emulator, in
  `firebase/rules-tests/`.
- `auth_service_test.dart` — sign-in, sign-out ordering, and session restore refusing a
  stored session that no Firebase user backs.
- `sign_in_flow_test.dart` — screen, controller, service and router redirect together, with
  fakes only at the plugin and transport seams. It runs with **no Firebase and no
  emulator**, which is the payoff for `GoogleCredentials` and `SessionStore` being abstract.
- `donor_registration_flow_test.dart` — the three setup steps and the profile screen against a
  fake `DonorRepository`. Each test names the `FR-DONOR-001` criterion it holds: eight blood
  types visible at once, saving refused without a blood type or district but **not** without a
  date, and both the day count and the calendar date on the result.

## Deliberate gaps

Recorded so they read as decisions rather than oversights. Full rationale in
[`ADR 0006`](../docs/tech-lead/adr/0006-flutter-course-architecture.md).

- ~~**`AsyncNotifier` and the four-state render** (Week 5)~~ — landed with M3 sign-in:
  `AuthController` is an `AsyncNotifier`, and the sign-in screen renders idle, in-flight,
  signed-in and failed, with a retry on each.
- ~~**`Result<T>` and sealed `Failure`** (Week 6)~~ — landed in `core/error/`.
- **`custom_lint` + `riverpod_lint`** — recommended, not required, and unsolvable on
  this Flutter SDK.

## AI Notes

Claude Code (Opus 5) wrote most of this app under review, and the whole repo runs the
Capybara multi-role framework. Two records worth keeping:

**Prompt — "make sure we follow the course rules for Flutter."** The audit that came
back found ten violations, and the two most useful ones were the ones I would not have
looked for. `home_screen.dart` imported `../data/health_repository.dart` — the exact
import Week 4 exists to remove — and every provider was hand-written as
`final xProvider = Provider((ref) => ...)`, which Week 4's own exam names as the
canonical AI-generated Riverpod mistake. The generated code was written by AI and the
mistake it made was the documented one.

**What I changed rather than accepted.** The first attempt tried to add
`riverpod_generator` on top of `flutter_riverpod 3.4.2` and version solving failed:
the generator needs `matcher <0.12.19`, and Flutter 3.44.6's `flutter_test` pins
`0.12.19`. The fix was not to abandon code generation but to move the runtime to
Riverpod 2.x — which is what the course prescribes anyway. A downgrade that increases
compliance is worth double-checking, so it is written up in ADR 0006 rather than left
in a commit message.
