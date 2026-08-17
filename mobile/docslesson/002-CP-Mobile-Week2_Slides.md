# Week 2 — Cross-Platform Mobile Application Development

**Topic:** AI Tools, go_router & Material 3 Theming
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 18 July 2026
**Subtitle:** From single-screen skeleton to a real navigated app

## What We Shipped Last Week (E01.1 recap)

- GitHub repo `fieldlog-flutter` with the mandated project structure.
- A 4-line `main.dart` with `runApp()` only.
- One screen — `OnboardingScreen` — rendered on an emulator.
- A clean `.gitignore` (`build/`, `.dart_tool/`, `*.keystore`).

**Today's question:** "Why does professional Flutter code use `go_router` from the first commit?" `Navigator.push` works fine for one screen; it rots at five.

## AI Tooling — Taught, Not Banned

1. **Disclose** — every README has an AI Notes section: what you prompted, what AI gave, what you changed.
2. **Verify** — never commit AI code you cannot explain; if called on, you must walk the line through the code.
3. **Stay current** — AI training lags; check pub.dev for package versions and official docs for the current API shape.

**Weak prompt vs strong prompt:**
- Weak: "How do I add routing in Flutter?" → generic answer, `Navigator.push` example, probably outdated.
- Strong: "Using Flutter 3.x and go_router ^14.6, write a router config with two routes: / (home) and /profile/:name. Return complete code for lib/src/router/app_router.dart."

**What AI gets wrong about Flutter:**
- Outdated package versions (suggests `go_router` ^9.x when current is ^14.x — check pub.dev).
- Made-up API methods — sometimes invents Riverpod or Drift methods that don't exist.
- Old patterns — may suggest `Provider` or `StateNotifier` when the course uses Riverpod 2.x `Notifier` with codegen.
- Single-file solutions — AI loves cramming everything into `main.dart`, violating the course structure.
- Plausible-looking JSON — AI hallucinates response shapes; always test against the real API.

**The AI Notes section in your README (format graded for thoughtfulness, not length):**
```md
## AI Notes

**Prompted**: "Using Flutter 3 + go_router ^14, write a router with two routes: / and /profile/:name."

**Given**: Working config, but with the old `routes:` builder syntax. Also missed errorBuilder.

**Changed**: Replaced with the current declarative `routerConfig` form. Added errorBuilder. Verified against go_router README.
```

## Material 3 Theming

**What changed with Material 3:**
- `ColorScheme.fromSeed` — give it one seed colour; M3 generates a full palette (primary, surface, container, on-* roles).
- Surface vs surface variant — multiple surface tones for elevation hierarchy; no more guessing "is this Card-coloured?".
- Tokens, not magic numbers — `colorScheme.primaryContainer` is meaningful; `const Color(0xFF...)` is not.
- Light + dark, same seed — pass `brightness: Brightness.dark` to `fromSeed`; both themes derive from one source of truth.

**M3 theming in FieldLog:**
```dart
import 'package:flutter/material.dart';

class FieldLogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
        ),
      ),
      darkTheme: ThemeData(useMaterial3: true, ...),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
```

## Navigation — Why go_router

**Imperative push vs declarative routing:**
- `Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(name: name)))` → no deep linking, no auth guard, not testable.
- `context.push(AppRouter.profilePathFor(name))` → deep linking yes, auth guard yes (Week 11), testable yes.

**AppRouter declaration (`lib/src/router/app_router.dart`):**
```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/profile/:name',
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'friend';
          return ProfileScreen(name: name);
        },
      ),
    ],
    errorBuilder: (...) => /* 404 screen */,
  );
}
```

**One router, one file — `lib/src/router/app_router.dart`:** find any route by searching one file, centralised path constants (no magic strings sprinkled around), easy to add a global redirect later (auth in Week 11), easy to test routing in isolation (Week 12).

## Live Coding — Adding go_router to FieldLog

1. `flutter pub add go_router` then `flutter pub get`.
2. Create `lib/src/router/app_router.dart`, declare two routes (`/` and `/profile/:name`), replace `MaterialApp` with `MaterialApp.router` in `app.dart`.
3. `OnboardingScreen` — add a name `TextField` backed by a `TextEditingController`, dispose it in `State.dispose()`, and push to the profile route on "Get started".
4. `ProfileScreen` — reads the `:name` path parameter, shows it in a `Scaffold` with an `AppBar`.
5. Verify theme propagation on the running emulator: toggle dark mode, both screens re-theme without restart, all colours come from `Theme.of(context).colorScheme` — never hardcoded. If a colour looks wrong, the widget is wrong, not the theme.

**Pitfall — TextEditingController discipline:** `StatefulWidget` is allowed in this course ONLY to manage controllers (`TextEditingController`, `ScrollController`, `AnimationController`, `FocusNode`). All four MUST be disposed in `State.dispose()` — forgetting leaks memory, sometimes silently for months. App-level state lives in Riverpod from Week 4 onward — never in a `StatefulWidget`.

## Exercise E02.1 — What You Build This Week

Two routes, M3 theme, go_router only:
- [ ] `go_router` is the only routing — no direct `Navigator.push` anywhere
- [ ] Routes declared in `lib/src/router/app_router.dart`, not inline
- [ ] Material 3 theme via `ColorScheme.fromSeed`, light + dark variants
- [ ] `TextEditingController` properly disposed in the onboarding screen's `State`
- [ ] Dark mode renders correctly when toggled in emulator settings
- [ ] AI Notes section explains one prompt and what you changed

**Self-check:** `grep -r 'Navigator.push' lib/` must return zero matches.

**Stretch tasks:** Khmer locale (`flutter_localizations` + ARB file with `km_KH` translations); route guard preview (redirect to `/` if a name is missing — foreshadows Week 11 auth); `ShellRoute` + bottom nav (2-tab persistent navigation across routes).

## Track B — Team Product (assigned this week)

- Teams of 3, formed and posted in the class group by Monday.
- Each team picks ONE product idea: problem, target user, three features, ranked.
- Must defend "why mobile, not just a website?" in one sentence.
- From Week 3 onward, teams progress through 7 milestones: M1 → M7. M7 = published to Play Store internal testing by Week 15.
- Track A (FieldLog) is your personal capstone. Track B is your team's product.

## Before Week 3 Begins

- Push E02.1 to GitHub — all 6 acceptance criteria met.
- Team formed (3 students) and posted in class group.
- Read docs.flutter.dev — "Flutter app architecture: case study" (15 min).
- Next week is the longest deck of the course — the Service Pattern in depth. Bring laptop charged.

## Key Terms

- **`go_router`** — declarative routing package; single source of truth for all app routes.
- **`ColorScheme.fromSeed`** — Material 3 API that derives a full color palette from one seed color.
- **AI Notes** — mandatory README section disclosing prompt, AI output, and what was changed/verified.
- **Controller discipline** — the rule that `StatefulWidget` exists only to own and dispose controllers.

---

# Week 2 QCM — Chapter Exam (25 questions, with answer key)

**Provenance:** questions as presented in the Week 2 chapter exam; answers worked through against this note. Not lesson content from the source PDF — this is an exam record appended for revision. `✓` marks the correct option; multi-select questions are flagged **[multi]**.

## AI Tooling (Q1–Q5)

**Q1.** What is the FIRST rule when using AI coding assistants in this course?
- A. Use AI for as much code as possible
- B. ✓ **Disclose AI use in an AI Notes section of every README**
- C. Avoid AI for any production-bound code
- D. Only use AI for documentation

*Source:* line 18, first of three rules. *Trap:* C — the section heading is "AI Tooling — **Taught, Not Banned**" (line 16). "Verify" is rule 2, not rule 1.

**Q2.** A "strong" prompt for an AI assistant on Flutter work should include:
- A. Just the question, the AI will figure out context
- B. ✓ **The Flutter and package versions, the exact error if applicable, and the precise intent**
- C. As many examples as possible from Stack Overflow
- D. A request for the AI to write the entire app

*Source:* lines 23–24. A *is* the weak prompt at line 23. D triggers the single-file pitfall (line 30).

**Q3.** **[multi]** Which of these are common pitfalls when AI generates Flutter code?
- A. ✓ **Outdated package versions** (line 27)
- B. ✓ **Made-up API methods** (line 28)
- C. ✓ **Suggesting an old state-management pattern (Provider vs Riverpod 2)** (line 29)
- D. Returning perfectly correct production code every time — *false; negates the whole section*

*Also in the deck, not asked here:* single-file solutions (line 30), plausible-looking JSON (line 31).

**Q4.** When verifying an AI-suggested package version, which is the authoritative source?
- A. The AI's confidence level
- B. The package's GitHub stars
- C. ✓ **The official listing on pub.dev**
- D. A Stack Overflow answer

*Source:* line 20. Division of labour: **pub.dev** for versions, **official docs** for API shape. In practice `flutter pub outdated` queries pub.dev directly.

**Q5.** If you cannot explain the code in your submission when asked in class, the exercise is:
- A. Graded at half credit
- B. Graded at full credit because AI is allowed
- C. ✓ **Not credited**
- D. Replaced with a new prompt for the AI

*Source:* rule 2, line 19 — *"never commit AI code you cannot explain; if called on, you must walk the line through the code."* Note the note states the obligation, not a penalty in these words; C is the only option consistent with "never". "Walk the line through" means line-level, not feature-level.

## Material 3 Theming (Q6–Q10)

**Q6.** Which constructor generates a full M3 colour palette from a single colour?
- A. `ColorScheme(primary: ..., secondary: ..., tertiary: ...)`
- B. ✓ **`ColorScheme.fromSeed(seedColor: ...)`**
- C. `MaterialColor(0xFF0F766E, {...})`
- D. `Theme.of(context).colorScheme.fromColor(...)`

*Source:* line 47. A is real but requires every role by hand. C is a pre-M3 swatch. D does not exist — pitfall 2.

**Q7.** To enable M3 in a `ThemeData` you must set:
- A. ✓ **`useMaterial3: true`**
- B. `material3: true`
- C. `version: 3`
- D. Nothing — M3 is on by default in all Flutter versions

*Source:* lines 61, 66. D fails on **"all versions"** — M3 became the default in Flutter 3.16. On Flutter 3.44 the framework does `useMaterial3 ??= true;` (`theme_data.dart:413`) and the flag is slated for removal, but the property that enables M3 is still `useMaterial3`. Keep writing it explicitly — graders grep for it.

**Q8.** **[multi]** Which of these are TRUE about Material 3 colour roles?
- A. ✓ **`colorScheme.primary` pairs with `colorScheme.onPrimary` for accessible foreground** (the `on-*` roles, line 47)
- B. ✓ **`colorScheme.primaryContainer` is a lower-emphasis variant for surfaces**
- C. ✓ **`colorScheme.surfaceTint` is used for elevation overlays** (line 48; defaults to primary)
- D. `colorScheme.background` should always be hard-coded white — *false, twice over*

*Why D fails twice:* hard-coding violates line 49 ("tokens, not magic numbers") and destroys dark mode; **and** `background` is itself deprecated after v3.18.0-0.1.pre — use `colorScheme.surface`. Also note M3 has since expanded past line 48's "surface vs surface variant" to the `surfaceContainer` / `surfaceContainerLow` / `surfaceContainerHighest` ramp.

**Q9.** To create a dark variant from the same seed colour, you pass:
- A. `darkMode: true`
- B. ✓ **`brightness: Brightness.dark` to `ColorScheme.fromSeed`**
- C. A separate hex colour for every dark role
- D. `theme.invert()`

*Source:* line 50. D is conceptually wrong as well as fake — M3 dark shifts tonal positions, it does not invert light. Making dark mode actually *appear* also needs `darkTheme:` on `MaterialApp` plus `themeMode: ThemeMode.system`.

**Q10.** Which is the correct way to read the current primary colour inside a widget?
- A. `Color(0xFF0F766E)`
- B. `MaterialApp.primaryColor`
- C. ✓ **`Theme.of(context).colorScheme.primary`**
- D. `Colors.primary`

*Source:* line 108. *Mechanism:* `Theme.of(context)` is an `InheritedWidget` lookup, so the widget subscribes to theme changes and rebuilds on an OS toggle. A hardcoded `Color` has no subscription. D does not exist. Remember line 108's second sentence: *"If a colour looks wrong, the widget is wrong, not the theme."*

## Navigation — go_router (Q11–Q16, Q20–Q21)

**Q11.** The only acceptable mechanism for navigation between screens is:
- A. `Navigator.push`
- B. `Navigator.of(context).pushNamed`
- C. ✓ **`go_router` (`context.push`, `context.go`, `context.pop`)**
- D. Manually changing widget state to swap children

*Source:* E02.1 criterion 1 (line 115); self-check `grep -r 'Navigator.push' lib/` → zero matches (line 122). D is not navigation at all — no back stack, no URL, no `pop`.

**Q12.** Routes for FieldLog are declared in:
- A. `lib/main.dart`
- B. Inline inside each widget's `onPressed`
- C. ✓ **`lib/src/router/app_router.dart`**
- D. `pubspec.yaml`

*Source:* line 116. D is bait — `go_router` goes in `pubspec.yaml` as a *package* (line 104), not as routes. The four reasons at line 100: one-file search; centralised path constants; easy global redirect later (W11 auth); easy isolated routing tests (W12).

**Q13.** **[multi]** Which of these are TRUE differences between `context.push` and `context.go`?
- A. ✓ **`push` adds to the back stack; `go` replaces the current location**
- B. ✓ **Both can take path parameters**
- C. ✓ **`push` is preferred when the user should be able to navigate back**
- D. `go` is required to use Material 3 — *false; routing and theming are orthogonal*

*Precision on A:* `go` rebuilds the stack from the target path's **route hierarchy**; it does not blindly wipe everything. For a flat router the effect is as stated — no back arrow. **Coverage note:** `context.go` and the push-vs-go contrast do **not** appear anywhere in this note. This question tests past the markdown — likely PDF content the conversion missed.

**Q14.** A path declared `/profile/:name` is read inside the builder using:
- A. `state.queryParameters['name']`
- B. ✓ **`state.pathParameters['name']`**
- C. `state.params['name']`
- D. `context.parameter('name')`

*Source:* lines 89–90. *Key trap:* C was **correct in go_router ≤5.x**, renamed to `pathParameters` in 6.x — the outdated-API pitfall (line 27) and the most likely thing AI hands you. A is real but reads `?name=x`, not the path segment. `pathParameters` returns `String?`, hence the `?? 'friend'` fallback.

**Q15.** Which root widget wires go_router into the app?
- A. `MaterialApp`
- B. `CupertinoApp`
- C. ✓ **`MaterialApp.router`**
- D. `Navigator`

*Source:* lines 59, 105. `.router` is the named constructor that unlocks the `routerConfig:` slot. A is the strongest distractor because it is the real mistake in the deck's own AI Notes example (lines 39–41): AI returned *"the old `routes:` builder syntax"* and it had to be replaced with the declarative `routerConfig` form.

**Q16.** **[multi]** Which are reasons we use go_router rather than `Navigator.push`?
- A. ✓ **Supports deep linking** (line 78)
- B. ✓ **Centralises routes for easy testing** (line 100, W12)
- C. ✓ **Allows a global `redirect:` callback for auth** (line 100, W11)
- D. Forces all routes to be defined at compile time — *false*

*Why D fails:* go_router matching is **runtime string matching**. A misspelled path in `context.push` yields the `errorBuilder` 404 at runtime, not a build failure. "Declarative" means *routes declared as data in one place*, not *compile-time route safety* — that needs `go_router_builder` codegen, which is outside this course.

**Q20.** The convention for navigating to a path-parameterised route is:
- A. Concatenate inline: `context.push('/profile/$name')` everywhere
- B. ✓ **Use a helper: `context.push(AppRouter.profilePathFor(name))`**
- C. Hard-code the URL in each widget
- D. `Navigator.pushNamed` with a String

*Source:* lines 78, 100. *Trap:* A is the only option that isn't broken — merely unmaintainable. The exam tests convention, not compilability. The interpolation still happens in the helper; it just happens **once**, adjacent to the `:name` declaration it must stay in sync with. Caveat: "typed helper" oversells it — the helper returns `String`, so there is no compile-time route safety.

**Q21.** If the user enters an unknown route, go_router should display:
- A. A blank screen
- B. ✓ **A 404 screen from `errorBuilder:`**
- C. The home screen silently
- D. A crash

*Source:* line 95; also flagged at line 39 as something AI **missed**. D is the failure mode when `errorBuilder` is absent, not the design. *Why C is tempting and still wrong:* silently redirecting home is legitimate when **deliberate** — that is the W11 `redirect:` callback. `errorBuilder` handles *no such route exists*; `redirect` handles *this route exists but you may not see it*.

## Controller Discipline (Q17–Q19)

**Q17.** A `TextEditingController` MUST be:
- A. ✓ **Created and disposed in the surrounding `State`** (`initState`/`dispose`)
- B. Recreated on every `build` call
- C. Made a global variable
- D. Wrapped in a `setState`

*Source:* line 110. B leaks the old controller every frame-triggering rebuild and wipes typed text. D is a category error — a controller is a long-lived object, not a value to set. *Wording note:* creating the controller as a **field initializer** also satisfies A; `initState` is only needed when creation depends on `widget.*` or `context`. `super.dispose()` goes last.

**Q18.** `StatefulWidget` is acceptable ONLY for:
- A. Holding business-logic state
- B. ✓ **Holding controller lifecycles (`TextEditingController`, `ScrollController`, etc.)**
- C. Storing user data
- D. Storing the result of API calls

*Source:* line 110. A, C, and D are the same wrong answer in different hats: *widget owns app state*. The test is mechanical — does this object need `dispose()`? Then `State`. Otherwise Riverpod. D specifically belongs to W5 `AsyncNotifier`.

**Q19.** **[multi]** Which of these need to be disposed in `State.dispose()`?
- A. ✓ **`TextEditingController`**
- B. ✓ **`ScrollController`**
- C. ✓ **`AnimationController`**
- D. `final` strings — *false; plain immutable values, GC handles them*

*Discriminator:* does it hold listeners or a ticker? Then dispose it. All three extend `ChangeNotifier` or register with a `Ticker`, so they accumulate listener references that outlive the widget. **`FocusNode` is the fourth** in line 110's set, absent from this question. Also disposable but outside the deck's four: `PageController`, `TabController`, `StreamSubscription` (via `cancel()`), `Timer` (via `cancel()`).

## Tracks & Deliverables (Q22–Q25)

**Q22.** Track A refers to:
- A. ✓ **The personal capstone (FieldLog) every student builds individually**
- B. The team product built by groups of 3
- C. Background reading
- D. Extra-credit experiments

*Source:* line 132. B is the swap — that is Track B.

**Q23.** Track B refers to:
- A. The personal capstone
- B. ✓ **The team-product assignment running M1–M7 milestones**
- C. Optional reading lists
- D. Final exam practice

*Source:* lines 126–132. **Timing asymmetry:** Track B is *assigned* in Week 2 but its milestones start **Week 3** (line 131). M7 = Play Store internal testing by Week 15.

| | Track A | Track B |
|---|---|---|
| What | FieldLog | Team product |
| Who | Individual | Teams of 3 |
| Assigned | Week 1 | Week 2 |
| Structure | Weekly `E[WW].[N]` exercises | 7 milestones, M1 → M7 |
| Endpoint | — | Play Store internal testing, Week 15 |

**Q24.** **[multi]** The Track B brief asks each team for:
- A. ✓ **A problem statement and target user** (line 129)
- B. ✓ **Three core features ranked by priority** (line 129 — *ranked* is load-bearing)
- C. ✓ **A defence of "why mobile and not just a website"** (line 130 — in **one sentence**)
- D. A complete revenue model — *false; never appears in the deck*

**Q25.** By the end of Week 2, each student must have:
- A. The team product on Play Store
- B. ✓ **E02.1 pushed to GitHub with all acceptance criteria met**
- C. A Kotlin Multiplatform project
- D. A signed AAB ready for release

*Source:* line 136 — all **6** acceptance criteria met. *Trap:* A is a real requirement pointed at the wrong deadline — M7, Week 15, thirteen weeks out. Full pre-week-3 checklist (lines 136–139): push E02.1; team of 3 posted; read *"Flutter app architecture: case study"* (15 min); laptop charged for the longest deck of the course.

## Answer key (compact)

| Q | Ans | Q | Ans | Q | Ans | Q | Ans | Q | Ans |
|---|---|---|---|---|---|---|---|---|---|
| 1 | B | 6 | B | 11 | C | 16 | A B C | 21 | B |
| 2 | B | 7 | A | 12 | C | 17 | A | 22 | A |
| 3 | A B C | 8 | A B C | 13 | A B C | 18 | B | 23 | B |
| 4 | C | 9 | B | 14 | B | 19 | A B C | 24 | A B C |
| 5 | C | 10 | C | 15 | C | 20 | B | 25 | B |

Every multi-select question here follows the same shape: **options A, B, C true; option D false**. D is always the over-claim ("perfectly correct every time", "always hard-code white", "required for Material 3", "compile time", "final strings", "revenue model").

## Errata — where this note has gone stale

Found while working the exam. The note's own rule 3 (line 20) applies to the note itself.

- **Line 27** claims `go_router` "current is ^14.x". Actual latest is **17.3.0** (`flutter pub outdated` against `fieldlog_flutter_week2`, which resolves 14.8.1). Three majors behind — and this is the one example a student is most likely to verify.
- **Line 48** frames M3 surfaces as "surface vs surface variant". M3 has since expanded to the `surfaceContainer` ramp, and `colorScheme.background` is deprecated in favour of `surface`.
- **Lines 61/66** teach `useMaterial3: true` as required. Still the right property and still required for coursework, but Flutter 3.44 defaults it to `true` and the framework marks it for removal.
- **Lines 66, 95** use `...` pseudo-code inside otherwise-complete Dart. Line 66 elides `brightness: Brightness.dark` — the one parameter the surrounding prose (line 50) exists to teach.
- **Line 56** slide `FieldLogApp` omits `const FieldLogApp({super.key})`; copying it verbatim trips `use_key_in_widget_constructors`.
- **Coverage gap:** Q13's `context.go` / push-vs-go contrast is absent from this markdown. Re-running `lesson-to-markdown` on `002-CP-Mobile-Week2_Slides.pdf` would confirm whether the conversion dropped it.
