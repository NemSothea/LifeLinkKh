# Week 1 — Cross-Platform Mobile Application Development

**Topic:** Setup, First Flutter App, GitHub, and Dart for Senior Devs
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 11 July 2026
**Capstone:** FieldLog — one feature per week, 16 weeks total

## Course Framing

- **Four principles the course lives by:**
  1. Patterns before pace — foundations re-taught through patterns so everyone writes Flutter the same correct way.
  2. Capstone-spine — every exercise builds one app, FieldLog; shipped to Play Store internal testing by Week 16.
  3. GitHub is the workflow — every commit pushed by end of session; a real engineering workflow, not a submission system.
  4. AI is required — Claude / Copilot / Cursor use is disclosed, critically reviewed, not banned.
- **What you walk out with after 16 weeks:** a personal GitHub repo of 16 weeks of FieldLog exercises (E01.1 → E15.1), a published FieldLog on Play Store internal testing, a team-built second app, an Architecture Decision Record (Flutter vs KMP vs native), fluency in Flutter/Dart 3/Riverpod/Drift/Dio/freezed/golden_toolkit, and reading-level Kotlin plus AI pair-programming as a real skill.
- **Why cross-platform, why now (2026 landscape):** Flutter has 98+ active jobs in Cambodia (Indeed, 2026), dominant in local hiring, Impeller renderer, Google-backed. KMP has 80%+ code-sharing in production apps (Netflix, Cash App, McDonald's, JetBrains) — shares business logic, keeps UI native. Native still right for SDK-heavy apps, highest performance, at 2x the engineering cost of cross-platform.
- **What this course is NOT:** not a Bachelor's repeat (no re-teaching setState/basic widgets/simple navigation), not YouTube-tutorial pace, not framework-of-the-month, not a guarantee — it IS where Master's-level Flutter engineering becomes your default coding style.

## Flutter Project Anatomy

```
fieldlog_flutter/
├── pubspec.yaml      ← dependencies, assets, SDK pin
├── lib/
│   ├── main.dart     ← runApp() ONLY
│   └── src/
│       ├── features/ ← all feature code lives here
│       │   └── onboarding/
│       └── router/   ← global routing (Week 2)
├── android/          ← Gradle, signing, native Kotlin
├── ios/              ← Xcode (read, don't build)
├── test/             ← unit & widget tests
└── .gitignore        ← build/, .dart_tool/, *.keystore
```

**Rule #1 — the single most-important rule:** source code lives under `lib/src/features/<feature>/`. Never in `lib/main.dart`, `lib/screens/`, or `lib/models/`. Feature folders scale; technical folders fragment.

**`main.dart` — only this, nothing else:**
```dart
import 'package:flutter/material.dart';
import 'src/app.dart';

void main() {
  runApp(const FieldLogApp());
}
```
If you write business logic, theme, or routes in `main.dart` — you are wrong. All app setup belongs in the root widget.

**`FieldLogApp` — the real entry point:**
```dart
class FieldLogApp extends StatelessWidget {
  const FieldLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldLog',
      home: const OnboardingScreen(),
    );
  }
}
```
No business logic. Just app setup, theme (Week 2), and the root route.

## OOP for Master's — Rules of Engagement

1. **Visibility discipline** — every field starts private (`_field`); make public only when outside code legitimately needs it.
2. **Immutability by default** — `final` on every field, `const` constructors where possible; mutable state needs a reason.
3. **Composition over inheritance** — `extends` used exactly twice this whole course; everything else uses `implements`, mixins, or fields.
4. **Depend on abstractions** — never import a concrete data source from a widget or service; always go through an abstract Repository/Service.
5. **SRP test** — "Can I name this class without using *and* or *or*?" If not, it does too much — split it.
6. **DIP test** — "If I swap Drift for Hive tomorrow, what files change?" Only the implementation file is the right answer.

## Dart 3 Features You Must Be Fluent With

- **Records:** `final (name, age) = ('Sok', 28);`
- **Sealed classes:** `sealed class Failure {} class NetworkFailure extends Failure {}`
- **Pattern matching:** `switch (value) { case (var x, var y) => x + y, }`
- **Switch expressions:** `final label = switch (status) { Loading() => 'Loading...', Data(:final v) => v.toString(), };`

## Live Coding — Building E01.1

1. `flutter create fieldlog_flutter` — walk the generated output, note the bloated default `lib/main.dart` we will replace.
2. Impose the structure:
   ```
   mkdir -p lib/src/features/onboarding/presentation
   touch lib/src/app.dart
   touch lib/src/features/onboarding/presentation/onboarding_screen.dart
   # rewrite main.dart to the 4-line version
   # move FieldLogApp to lib/src/app.dart
   # move OnboardingScreen to features/onboarding/presentation/
   ```
3. First screen — `OnboardingScreen extends StatelessWidget`, a `Scaffold` with a centered `ElevatedButton` that shows a `SnackBar` on press.
4. Git init, first push:
   ```
   git init
   git add .gitignore && git commit -m "Initial .gitignore"   # .gitignore FIRST — always
   git add .
   git commit -m "E01.1: FieldLog skeleton with feature folders"
   git remote add origin git@github.com:<you>/fieldlog-flutter.git
   git push -u origin main
   ```
   Commit convention: `E[WW].[N]: <action>`. Always verify `.gitignore` caught `build/` and `.dart_tool/`.

## Exercise E01.1 — Acceptance Criteria (all must be met, effort-based grading)

- [ ] Project name: `fieldlog_flutter` (snake_case, no spaces)
- [ ] Source code under `lib/src/features/onboarding/` — NOT in `lib/main.dart`
- [ ] `main.dart` only calls `runApp()` — root widget lives in `lib/src/app.dart`
- [ ] App runs on Android emulator or physical phone
- [ ] Pushed to GitHub with proper `.gitignore` (no `build/`, no `.dart_tool/`)
- [ ] `README.md` with app name, your name, screenshot, AI Notes section

**Stretch tasks (public recognition, not extra grade points):** custom app icon via `flutter_launcher_icons`; add `ColorScheme.fromSeed` and verify it propagates; deploy to a physical phone via USB.

## Before Week 2 Begins

- Push E01.1 to GitHub — all 6 acceptance criteria met.
- Install an AI assistant (Claude / Copilot / Cursor); verify by asking it to explain `Future<void>` vs `void` in Dart.
- Read official Flutter docs: "Navigate to a new screen and back" (15 min).
- Read the `go_router` README basics (10 min).

## Key Terms

- **Feature folder** — `lib/src/features/<feature>/`, the only place source code lives.
- **Root widget** — `FieldLogApp`, holds app-wide config (theme, routes); the real entry point.
- **SRP / DIP** — Single Responsibility / Dependency Inversion, tested with the "name it" and "swap it" questions.
- **Sealed class** — Dart 3 construct for exhaustive, closed type hierarchies (e.g. `Failure`).
- **Records** — Dart 3 lightweight anonymous tuples, e.g. `(name, age)`.
