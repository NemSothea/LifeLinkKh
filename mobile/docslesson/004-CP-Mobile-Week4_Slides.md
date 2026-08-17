# Week 4 — Cross-Platform Mobile Application Development

**Topic:** Riverpod Fundamentals — Notifier & Code Generation
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 1 August 2026
**Subtitle:** Where state lives, and how Services get into widgets

> Source PDF is named `003-CP-Mobile-Week4_Slides.pdf` at repo root (prefix mis-numbered by the lecturer; content is Week 4 of 16).

## Where We Are After Week 3 (E03.1 recap)

What to keep:

- `profile/{data, domain, application, presentation}/` folders.
- `Profile` entity is immutable (final fields).
- `ProfileRepository` is abstract; `FakeProfileRepository` implements it.
- `ProfileService` depends on the abstract repository — never on the concrete one.

What is still wrong:

- The screen still constructs the Service manually with `new`.

**Today:** replace that manual construction with Riverpod-managed DI.

**Team check-in (M1 review):** 1 minute per team, out loud — team name and lead, problem statement in one sentence, target user in one sentence, three core features ranked. The lecturer asks one sharpening question per team.

**Today's question:** "How do widgets get state without being responsible for it?" Most Bachelor's code answers this with `setState`. That doesn't survive a real team. We replace it today.

## The Landscape — State Management Options

| Option | Verdict | Why |
|---|---|---|
| `setState` | Limited | Local widget state. Fine for forms, scrolling. Not for app state. |
| Provider | Legacy | Riverpod's predecessor. Maintained but superseded. Use Riverpod instead. |
| BLoC | Heavy | Powerful, but boilerplate-heavy. Good for very large apps. Overkill here. |
| **Riverpod 2.x** | **OUR PICK** | Compile-time safety · DI built in · testable · official successor to Provider. |

### What Riverpod gives us

- **Compile-time safety** — forgot to wrap the app in `ProviderScope`? The compiler catches it. Bad provider read in `build()`? The compiler catches it.
- **DI built in** — no separate `get_it` / `injectable` / BLoC Provider boilerplate. The provider IS the DI graph.
- **Testable by default** — `ProviderContainer` + `overrideWith`: replace one line, swap any dependency in a test.
- **Maintained by Provider's author** — Riverpod is the official successor. Same person, fewer bugs, better API.

## Three Primitives You Need to Know

| Primitive | Purpose |
|---|---|
| `Provider` | Exposes a value or a dependency. Used for our Services and Repositories. |
| `Notifier<T>` | Mutable state. Synchronous. Replaces `ChangeNotifier` for app state. **This week.** |
| `AsyncNotifier<T>` | Async state. Wraps `Future<T>` in `AsyncValue`. Loading / data / error. Next week (W5). |

## ProviderScope — Wrap the App Once, at the Root

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';

void main() {
  runApp(
    const ProviderScope(child: FieldLogApp()),
  );
}
```

Without this wrapper, Riverpod throws at runtime. Riverpod 3 catches it at compile time.

## The #1 Riverpod Bug — `ref.read` vs `ref.watch`

`ref.watch` ✓ inside `build()`:

```dart
// In build() — subscribe
final profile = ref.watch(
  profileNotifierProvider
);
// Rebuilds when state changes
```

`ref.read` inside callbacks:

```dart
// In onPressed — one-shot
onPressed: () {
  ref.read(
    profileNotifierProvider.notifier
  ).enrol();
},
```

Mix them up and you get rebuild storms or stale state. **This is the bug.**

## Code Generation — Why `riverpod_generator`

- **Refactor-safe** — rename a provider, every reference updates. No string-based lookups to forget.
- **Less boilerplate** — a Notifier with `build_runner` is ~5 lines. Without, ~25.
- **Same API** — `ref.read` / `ref.watch` work identically. The generator just produces the plumbing.
- **One command to run** — `dart run build_runner watch` — leave it running, regenerates on save.

### What the annotation generates for you

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';   // generated

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Profile? build() => null;

  Future<void> enrol(...) async {
    // call into the Service, update state
  }
}
```

## Riverpod = the DI Mechanism for Our Services

**Week 3 — what we built:**

- Service Pattern with constructor injection.
- Service depends on abstract Repository (rule S4).

**Week 4 — what we change:**

- Riverpod providers expose the Service and Repository.
- Widget reads the provider — never constructs a Service.
- *Service code is unchanged — that's rule S4 paying off.*

### The first link in the chain — Repository provider

```dart
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return FakeProfileRepository();
}
```

In W7 we change this to return `DriftProfileRepository`. Nothing else moves.

### The Service depends on the Repository

```dart
@Riverpod(keepAlive: true)
ProfileService profileService(ProfileServiceRef ref) {
  return ProfileService(
    ref.watch(profileRepositoryProvider),
  );
}
```

`ref.watch` here = if the repository provider is overridden in a test, the service uses the override.

### The wiring

`Widget (ConsumerWidget) → Notifier (@riverpod class) → Service (constructor DI) → Repository (abstract) → Fake / Drift / Dio (concrete)`

Each arrow is a Riverpod read — overridable for tests. Notice what is NOT in this diagram: imports between widgets, manual constructors, `get_it`.

### What you don't have to do

- No giant `main.dart` constructing 20 services and passing them down.
- No `get_it` global registry that hides dependencies.
- No `Provider.of<Service>(context)` typed lookups that break at runtime.
- Test setup is ONE line: `overrideWith` for any provider in the graph.
- Lazy by default: providers are created only when first read.

## Live Coding — 3 Steps

### Step 1 — Add ProviderScope and packages

```bash
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add --dev riverpod_generator build_runner
dart run build_runner watch -d
```

```dart
// Then wrap MaterialApp:
runApp(const ProviderScope(child: FieldLogApp()));
```

Leave `build_runner watch` running. It regenerates `.g.dart` files as you save.

### Step 2 — Write the Notifier and its providers

```dart
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ref) =>
    FakeProfileRepository();

@Riverpod(keepAlive: true)
ProfileService profileService(ref) =>
    ProfileService(ref.watch(profileRepositoryProvider));

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  Profile? build() => null;

  Future<void> enrol(...) async {
    state = await ref.read(profileServiceProvider).enrol(...);
  }
}
```

### Step 3 — Consume from the widget

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);

    return Scaffold(
      body: profile == null ? const Text('Not enrolled')
                            : Text(profile.name),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(profileNotifierProvider.notifier)
                            .enrol(...),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
```

## Exercise — E04.1: Riverpod-managed Profile state

- [ ] `flutter_riverpod`, `riverpod_annotation` in pubspec; generator + `build_runner` in `dev_dependencies`
- [ ] `ProviderScope` wraps `MaterialApp` in `main.dart`
- [ ] `@riverpod` annotated provider generates a `.g.dart` file
- [ ] No `setState()` calls in the Profile feature (`StatefulWidget` allowed only for `TextEditingController` disposal)
- [ ] Presentation layer uses `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] README has the AI Notes section

**All criteria must be met. No partial credit. M1 review feedback applied for teams.**

## Before Week 5 Begins

- Push E04.1 with the generator running cleanly.
- Read: Riverpod docs — `AsyncNotifier` and `AsyncValue` sections (15 min).
- Think about: what does your screen show while data is loading?
- Team M2 — wireframes due by Monday.

*Next week: four states every async screen must render — loading, data, error, empty.*

## Key Terms

- **ProviderScope** — root widget that hosts the Riverpod provider graph; the app must be wrapped in it once, in `main.dart`.
- **Notifier&lt;T&gt;** — Riverpod 2.x class holding synchronous mutable state; replaces `ChangeNotifier` for app state.
- **AsyncNotifier&lt;T&gt;** — async counterpart wrapping `Future<T>` in `AsyncValue` (loading / data / error); taught in Week 5.
- **`ref.watch`** — subscribing read, used inside `build()`; rebuilds the widget when the provider's state changes.
- **`ref.read`** — one-shot read, used inside callbacks such as `onPressed`; does not subscribe.
- **`overrideWith`** — one-line test hook that swaps any provider in the graph, e.g. a fake repository for a real one.
- **`riverpod_generator` / `build_runner`** — code generation that turns `@riverpod` annotations into `.g.dart` provider plumbing; run with `dart run build_runner watch`.

---

# Week 4 QCM — Chapter Exam (25 questions, with answer key)

**Provenance:** questions as presented in the Week 4 chapter exam; answers worked through against this note and the `fieldlog_flutter_week4` snapshot. Not lesson content from the source PDF — this is an exam record appended for revision. `✓` marks the correct option; multi-select questions are flagged **[multi]**.

**Read this before using the key:** Week 4 **breaks the multi-select pattern twice**. Q5, Q8 and Q17 follow the familiar "A, B, C true — D false" shape, but **Q14 and Q21 are A, B, D** — in both, the false option sits in the *third* slot. Answer on content, not shape.

**The single mental model this whole exam tests:** `ref.watch` in `build()`, `ref.read` in callbacks; providers wire dependencies, the Service Pattern is unchanged.

## ProviderScope & Setup (Q1–Q2)

**Q1.** What must wrap a Flutter app to use Riverpod anywhere in it?
- A. `MaterialApp`
- B. ✓ **`ProviderScope`**
- C. `ChangeNotifierProvider`
- D. `MultiProvider`

*Source:* "ProviderScope — Wrap the App Once, at the Root"; `week4/lib/main.dart:11`. Without it Riverpod throws at runtime (Riverpod 3 catches it at compile time). *Trap:* C and D are `provider`-package APIs — the legacy predecessor, not Riverpod. A is the app shell; it hosts no provider graph.

**Q2.** Where does `ProviderScope` belong in a FieldLog application?
- A. Inside every screen that uses a provider
- B. ✓ **Around `MaterialApp` (or the highest sensible root)**
- C. Inside each feature folder
- D. In every Notifier class

*Source:* `week4/lib/main.dart:9–15` — `runApp(const ProviderScope(child: FieldLogApp()))`. Note the course rule survives: `main.dart` still contains only `runApp()`; `MaterialApp.router` lives in `src/app.dart`. *Traps:* A gives each screen its own graph — state lost on navigation, nothing shared. C confuses source layout with the widget tree; `ProviderScope` is a widget. D is backwards — a Notifier lives *inside* the scope. *Legitimate exception, not on this exam:* a nested `ProviderScope(overrides: [...])` for a subtree, used mainly in widget tests.

## ref.read vs ref.watch (Q3–Q5)

**Q3.** `ref.watch(myProvider)` is appropriate when:
- A. Used inside `onPressed` callbacks
- B. ✓ **Used inside `build()` to subscribe to state changes**
- C. Used inside `initState()`
- D. Used inside `dispose()`

*Source:* "The #1 Riverpod Bug" slide; `week4/lib/src/features/profile/presentation/profile_screen.dart:45`. C and D are the same error in two costumes — neither has a subscription lifecycle, so watching there misbehaves or throws. One-time work at init belongs in `ref.listenManual`, not `initState` + `watch`.

**Q4.** `ref.read(myProvider)` is appropriate when:
- A. Used inside `build()` to subscribe
- B. ✓ **Used inside callbacks like `onPressed`**
- C. Used to mark the widget for rebuild
- D. Used to dispose a provider

*Source:* same slide; `profile_screen.dart:27` — `ref.read(profileNotifierProvider.notifier).enrol(...)`. *Trap:* C is the exact inverse of what `read` does — not subscribing is its entire purpose. D confuses reading with lifecycle; disposal is `ref.onDispose` inside the provider, or autoDispose (the default for bare `@riverpod`).

**Q5.** **[multi]** Which of the following are SYMPTOMS of misusing `ref.read` and `ref.watch`?
- A. ✓ **The widget never rebuilds when state changes** — `read` in `build()`
- B. ✓ **The widget rebuilds on every callback invocation** — `watch` in a callback
- C. ✓ **Riverpod throws an error about subscription outside build** — `watch` in `initState`/`dispose`/after an `await`
- D. The widget renders perfectly with no warnings — *false; that is correct wiring*

*Source:* "Mix them up and you get rebuild storms or stale state." *Worth internalising:* the stale-state case is often **silent** — no exception, no warning, just wrong UI. `riverpod_lint` (in `week4/pubspec.yaml:27`) catches some of these; not all.

## Code Generation & Packages (Q6–Q8)

**Q6.** Which Dart command runs the Riverpod code generator?
- A. `flutter generate`
- B. ✓ **`dart run build_runner build --delete-conflicting-outputs`**
- C. `flutter pub generate riverpod`
- D. `dart compile riverpod`

*Source:* "Live Coding Step 1". The slide's dev-loop variant is `dart run build_runner watch -d` — `watch` stays running and regenerates on save; `-d` is the short form of `--delete-conflicting-outputs`. *Traps:* A and C are not real commands. D borrows a real command (`dart compile` targets exe/AOT/JS) for a fictional purpose.

**Q7.** What does the `@riverpod` annotation generate?
- A. The widget tree
- B. ✓ **A typed provider for the annotated function or class**
- C. The application's UI
- D. A database schema

*Source:* "What the annotation generates for you"; `week4/.../profile_providers.g.dart`. Naming is mechanical: `profileRepository(ref)` → `profileRepositoryProvider`; `class ProfileNotifier` → `profileNotifierProvider` plus the `_$ProfileNotifier` base class. That mechanical link is what makes renames refactor-safe.

**Q8.** **[multi]** Which packages does this course's Riverpod setup require?
- A. ✓ **`flutter_riverpod`** — runtime: `ProviderScope`, `ConsumerWidget`, `WidgetRef`
- B. ✓ **`riverpod_annotation`** — the `@riverpod` / `@Riverpod(keepAlive: true)` annotations
- C. ✓ **`riverpod_generator` (dev_dependency)** — reads annotations, writes `.g.dart`
- D. `provider` — *false; the legacy predecessor. Two DI graphs in one pubspec.*

*Source:* "Live Coding Step 1"; `week4/pubspec.yaml:17–28`. **The option list omits a required package:** `build_runner` (dev) actually *runs* the generator — `riverpod_generator` alone does nothing. E04.1 checks for it. The week4 snapshot also adds `custom_lint` + `riverpod_lint`, which are recommended, not required.

## Notifier Types (Q9–Q11)

**Q9.** Which Riverpod class is appropriate for state that updates synchronously?
- A. `AsyncNotifier<T>`
- B. ✓ **`Notifier<T>`**
- C. `StreamNotifier<T>`
- D. `FutureProvider<T>`

*Source:* "Three Primitives"; `profile_providers.dart:38–40`. **The tell is the `build()` return type:** `Notifier` returns `T`, `AsyncNotifier` returns `Future<T>`. *Subtle point:* "synchronous" describes the *state type*, not the method bodies — `ProfileNotifier.enrol()` is `async` and still belongs here.

**Q10.** Which Riverpod class is the right tool for state that returns from a `Future<T>` (loading → data / error)?
- A. `Notifier<T>`
- B. ✓ **`AsyncNotifier<T>`**
- C. `StateNotifier<T>`
- D. `ChangeNotifier`

*Source:* "Three Primitives" — *"Async state. Wraps `Future<T>` in `AsyncValue`. Loading / data / error. Next week (W5)."* With A you would hand-roll loading and error flags — which is exactly what `week4`'s `_saving` boolean does, and exactly what W5 deletes.

**Q11.** Which Notifier type does this course use as the default — and which is deprecated for our work?
- A. Use `ChangeNotifier`; `Notifier` is deprecated
- B. ✓ **Use `Notifier`/`AsyncNotifier`; `StateNotifier` is deprecated for our use**
- C. Use `StateNotifier`; `Notifier` is deprecated
- D. Use both equally

*Source:* "Three Primitives" plus the landscape slide's *Legacy* verdict on Provider. *Precision worth keeping:* `StateNotifier` is **superseded** (Riverpod 1.x era), not formally deprecated by the package — but it is off-limits in this course. Practical rule for FieldLog: never write `extends ChangeNotifier` or `extends StateNotifier`; always `@riverpod class X extends _$X`.

## Riverpod as DI & Layer Boundaries (Q12–Q14)

**Q12.** In Week 4, where does the Service get its Repository dependency from?
- A. `new Repository()` inside the Service constructor
- B. ✓ **The Riverpod provider — `ref.watch(profileRepositoryProvider)`**
- C. A global singleton in `main.dart`
- D. The Widget passes it in

*Source:* "The Service depends on the Repository"; `profile_providers.dart:26–29`. **`watch`, not `read`, is deliberate** — a test's `overrideWith` on the repository provider must flow through to the Service. *Trap:* A hard-wires the concrete and kills rule S4. C is the `get_it` pattern the slides explicitly reject. D would force the widget to import `data/`.

**Q13.** The Profile screen in Week 4 imports:
- A. The Repository directly
- B. The Service directly
- C. ✓ **The `profileNotifierProvider` from the application layer**
- D. All three layers — data, domain, application

*Source:* `profile_screen.dart:5` — one feature import, `../application/profile_providers.dart`. Compare Week 3's `profile_screen.dart:5`, which imported `data/fake_profile_repository.dart` (see the Week 3 note's Errata 1) — **that import disappearing is the Week 4 deliverable.** *Nuance:* the screen still touches the `Profile` entity's fields (`profile.role`, line 76) through type inference; entity types from `domain/` are permitted (see Q14).

**Q14.** **[multi]** Which of the following layers is the screen ALLOWED to import in Week 4?
- A. ✓ **`application/`** — providers, notifiers; services reached indirectly
- B. ✓ **`domain/`** — entities like `Profile` for type annotations
- C. `data/` (the concrete repository) — *false; this is the import Week 4 removes*
- D. ✓ **The router** — presentation-to-presentation; `context.pop()` at `profile_screen.dart:52`

**⚠ Shape break:** the false option is **C**, not D. *Source:* Week 3's dependency rule `presentation → application → domain ← data`. Rule of thumb: a screen may import anything pointing inward, plus its siblings in `presentation/` (including routing). `data/` is the far side of the diagram — it also points inward, so nothing above it may name it. Only the repository provider names a concrete implementation, which is what makes the W7 Drift swap a one-line change.

## Testing with ProviderContainer (Q15–Q17)

**Q15.** To test a Notifier in isolation, you create:
- A. A new app with `runApp()`
- B. ✓ **A `ProviderContainer` with overrides for the dependencies**
- C. A widget test
- D. A Drift database

*Source:* "Testable by default"; `week4/test/profile_notifier_test.dart:23–29`. Plain `test()`, no `pumpWidget` — that is what "isolation" means here. *Trap:* C is a legitimate technique for the wrong target — a widget test exercises the *screen* and uses `ProviderScope(overrides: [...])`. D reintroduces a real data source and defeats the fake.

**Q16.** To replace a real repository with a fake during a test, you use:
- A. ✓ **`profileRepositoryProvider.overrideWithValue(fakeRepo)` inside `ProviderContainer`**
- B. Modifying the production code
- C. Static singletons
- D. A global variable

*Source:* `profile_notifier_test.dart:33–36`, which overrides with a `_RecordingRepository` to assert what was saved. **Note the answer is A here, not B** — the option order changed from Q15. Sibling forms: `overrideWith((ref) => ...)` when the fake needs `ref`, and `ProviderScope(overrides: [...])` in widget tests. B, C, D all describe hidden dependencies that cannot be swapped per test and leak state between them.

**Q17.** **[multi]** Which are valid reasons to use `ProviderContainer` in unit tests?
- A. ✓ **To override providers with fakes**
- B. ✓ **To dispose providers correctly with `addTearDown`**
- C. ✓ **To read the notifier's state and assert on it**
- D. To render Flutter widgets — *false; a container has no widget tree*

*Source:* `profile_notifier_test.dart:26, 28, 38–47`. On B: `addTearDown(container.dispose)` matters most for `keepAlive: true` providers, which otherwise survive into the following test. On C: `container.read(provider)` returns state; `container.read(provider.notifier)` returns the Notifier to call methods on. **The split to remember:** `ProviderContainer` tests logic, `ProviderScope` tests UI.

## Debugging Symptoms & Lifecycle (Q18–Q20)

**Q18.** A widget shows a "stale" value and never updates. Most likely cause?
- A. The provider was never created
- B. ✓ **`ref.read` is being used inside `build()` instead of `ref.watch`**
- C. `ProviderScope` is not in the widget tree
- D. The notifier has no state

*Source:* the pitfall slide. *Why the others fail the symptom:* A is impossible — providers are lazy, so reading one creates it. C throws at startup rather than rendering a stale value. D would render null/empty, not a stale value. **Pair Q18 with Q19:** stale = `read` in `build()`; storm = `watch` in a callback.

**Q19.** A widget rebuilds excessively, even when nothing visible has changed. Most likely cause?
- A. Too many widgets in the tree
- B. ✓ **`ref.watch` is being used on a provider whose value isn't meaningful to the UI**
- C. Riverpod is buggy
- D. The notifier extends `StateNotifier`

*Source:* the pitfall slide. Two fixes: narrow the subscription with `ref.watch(p.select((x) => x.field))`, or push a `Consumer` down so only the small subtree rebuilds. *Related trap not in the options:* if the entity is not value-equal, every `state = ...` looks like a change even for identical data — the immutable entity plus `==`/`copyWith` from Week 3 is what lets Riverpod skip the no-op rebuild. A costs render time, not rebuild frequency. D is legacy for us but does not itself cause storms.

**Q20.** `@Riverpod(keepAlive: true)` is appropriate when:
- A. ✓ **The provider holds a singleton-like dependency (repository, service)**
- B. You want the provider disposed every time the screen closes
- C. You want to invalidate the cache constantly
- D. The provider depends on widget lifecycle

*Source:* `profile_providers.dart:20, 26` — both the Repository and the Service are `keepAlive: true`; `ProfileNotifier` (line 37) is bare `@riverpod`, i.e. autoDispose. **The rule:** stateless and expensive to rebuild → `keepAlive`; screen-scoped state that should reset → default autoDispose. *Traps:* B describes the default, the exact opposite. C conflates disposal with refresh (`ref.invalidate()`). D inverts the design goal — providers are deliberately independent of widget lifecycle.

## The Service Pattern After Riverpod (Q21–Q23)

**Q21.** **[multi]** Which of the following remain TRUE about the Service Pattern after introducing Riverpod?
- A. ✓ **The Service still depends only on the abstract Repository** (rule S4)
- B. ✓ **The Service is still a plain Dart class, no Flutter import**
- C. The Service is now disposable / has Flutter lifecycle — *false*
- D. ✓ **Riverpod is the wiring; the Service Pattern's six rules still hold**

**⚠ Shape break:** the false option is **C**, not D. *Source:* *"Service code is unchanged — that's rule S4 paying off."* Riverpod manages the **provider's** lifecycle (`keepAlive` vs autoDispose), never the Service object's. The Service imports neither Flutter nor Riverpod — only the *provider function* in `application/` imports `riverpod_annotation`. **Checkable claim:** the Week 4 diff to `profile_service.dart` should be zero lines. If you edited the Service to make Riverpod work, something is wired wrong.

**Q22.** A common AI mistake when generating Riverpod 2.x code is:
- A. Generating the `@riverpod` annotation correctly
- B. ✓ **Generating `extends StateNotifier<T>` patterns — outdated for our use**
- C. Generating proper `Notifier<T>` classes
- D. Using `ref.watch` inside `build()`

*Note the option shape:* A, C and D are the *correct* outputs; only B is a mistake. Models default to Riverpod 1.x because their training data is thick with Provider-era posts. Companion slips worth watching for: a hand-written `final xProvider = Provider((ref) => ...)` instead of codegen; a missing `part 'x.g.dart';` (the generator then silently emits nothing); and `context.read`, which is `provider`-package API that does not exist in Riverpod. **This is precisely what the README AI Notes section exists to record** — e.g. *"AI produced StateNotifier; replaced with `@riverpod class … extends _$…` and verified against the generated file."*

**Q23.** Forgetting to run `build_runner` after writing a new `@riverpod` annotated class causes:
- A. ✓ **A red squiggly: the generated provider name does not exist**
- B. The app crashes at runtime only
- C. No effect — Riverpod generates lazily
- D. Increased build time

*Note the answer is A, breaking the run of B answers.* You get two errors together — `Undefined name 'profileNotifierProvider'` and `Undefined class '_$ProfileNotifier'` — plus a broken `part` directive, all before the app can run. *Trap:* C misapplies a true fact — laziness governs **provider creation at runtime** (first read), not code generation, which happens at build time.

## Widget Wiring (Q24–Q25)

**Q24.** To call a method on a notifier (e.g. to trigger `enrol`) from a button, the correct call is:
- A. `ref.watch(profileNotifierProvider).enrol(...)`
- B. ✓ **`ref.read(profileNotifierProvider.notifier).enrol(...)`**
- C. `ProfileNotifier().enrol(...)`
- D. `Provider.of(...)`

*Source:* "Live Coding Step 3"; `profile_screen.dart:27`. **Two independent decisions, both required:** `.notifier` (without it you get `Profile?`, which has no `enrol`) and `read` over `watch` (a callback must not subscribe). *Traps:* C constructs an instance outside the graph — its `state` goes nowhere and no widget observes it. D is `provider`-package API.

**Q25.** Week 4 introduces Riverpod to replace which Week 3 line in the Profile screen?
- A. `final theme = Theme.of(context);`
- B. ✓ **`late final _service = ProfileService(FakeProfileRepository());`**
- C. `context.pop();`
- D. `appBar: AppBar(title: const Text('Profile'))`

*Source:* the E03.1 recap slide's red ✗ — *"the screen still constructs the Service manually with `new`."* Two violations in one line: the widget owns the Service's lifetime, and `presentation/` names a concrete class from `data/`. A, C and D all survive into Week 4 unchanged and appear verbatim in `profile_screen.dart:43, 52, 49`.

## Answer key (compact)

| Q | Ans | Q | Ans | Q | Ans | Q | Ans | Q | Ans |
|---|---|---|---|---|---|---|---|---|---|
| 1 | B | 6 | B | 11 | B | 16 | **A** | 21 | **A B D** |
| 2 | B | 7 | B | 12 | B | 17 | A B C | 22 | B |
| 3 | B | 8 | A B C | 13 | **C** | 18 | B | 23 | **A** |
| 4 | B | 9 | B | 14 | **A B D** | 19 | B | 24 | B |
| 5 | A B C | 10 | B | 15 | B | 20 | **A** | 25 | B |

**Bolded cells are the ones that break a run** — B dominates this exam (18 of 25 single-answer questions), so Q13 (C), Q16 (A), Q20 (A) and Q23 (A) are where pattern-matching fails. Multi-select: Q5, Q8, Q17 are A B C; **Q14 and Q21 are A B D**.

## Errata — where `fieldlog_flutter_week4` diverges from this note

1. **E04.1 says "no `setState()` in the Profile feature"; the snapshot uses it.** `presentation/profile_screen.dart:26, 32` call `setState(() => _saving = ...)` to drive a button label. The exercise permits `StatefulWidget` **only** for `TextEditingController` disposal, so this is a genuine criterion miss, not a grey area. The `_saving` flag is also a hand-rolled loading state — exactly what `AsyncNotifier` + `AsyncValue` replaces in Week 5, which is the cleanest fix.
2. **The slides show `ConsumerWidget`; the snapshot uses `ConsumerStatefulWidget`.** Not a violation — E04.1 accepts either — but the snapshot only needs the stateful variant *because* of erratum 1. Remove `_saving` and `ConsumerWidget` suffices.
3. **`application/profile_providers.dart:3` imports `data/`.** Strictly, `application → data` is an outward arrow. It is lesson-sanctioned (the repository provider is the composition root — slide 14 shows this exact code) and it is deliberately the *only* place naming a concrete implementation, which is what makes the W7 Drift swap one line. Worth being able to explain rather than defend as "the rule".
4. **The Notifier reads its Service with `ref.read`, while the Service provider reads its Repository with `ref.watch`.** `profile_providers.dart:43` vs `:28` — both match the slides. The asymmetry is intentional: `watch` inside a provider propagates test overrides down the graph; `read` inside a method body is a one-shot call, same rule as in a widget callback.
