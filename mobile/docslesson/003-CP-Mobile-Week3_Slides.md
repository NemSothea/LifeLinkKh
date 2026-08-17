# Week 3 — Cross-Platform Mobile Application Development

**Topic:** Layered Architecture & the Service Pattern
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 25 July 2026
**Subtitle:** The lesson that separates Master's from Bachelor's

## Where We Are After Week 2 (E02.1 recap)

- Two routes via `go_router`, Material 3 theme (light + dark), `TextEditingController` properly disposed, profile screen receives `:name` from the route, AI Notes section in every README.
- Team M1 check (Track B): problem statement in one sentence, target user described as a real person, three core features ranked, why mobile not web.

**Today's question:** "Where does business logic live in a Flutter app?" Most answers in this room are wrong — and the cost of that wrongness shows up in Week 8.

## The Rot — What a Bachelor's Project Looks Like

```dart
class ProfileScreen extends StatefulWidget { ... }

class _State extends State<...> {
  Future<void> _loadProfile() async {
    final response = await http.get(...);        // network in a widget?!
    final json = jsonDecode(response.body);
    setState(() => _profile = Profile.fromJson(json));
  }
}
```
Network in a widget, JSON in a widget, state in a widget, everything in one place — untestable, unmaintainable, unfixable.

## The Fix — Four Layers, One Direction

| Layer | Contains |
|---|---|
| `presentation/` | Widgets, screens, routes — and nothing else |
| `application/` | Services orchestrate; Notifiers hold UI state (Week 4) |
| `domain/` | Entities, abstract repository contracts, failures |
| `data/` | DTOs, concrete repositories, DAOs, API clients |

**The dependency rule:** `presentation → application → domain ← data`. Arrows point inward — inner layers know nothing about outer ones.
- `data` depends on `domain` (it implements the abstract Repository).
- `presentation` imports `application` — never `data` directly.
- `domain` imports nothing from the rest of the app — it is pure.

**What lives in `data/`:** concrete repositories that talk to a real source — `FakeProfileRepository` (in-memory, this week), `DriftProfileRepository` (local DB, Week 7), `ApiProfileRepository` (REST client, Week 10); DTOs (wire-format data classes, Week 10); mappers (DTO ↔ domain Entity converters, Week 10).

**What lives in `domain/`:** pure types — no Flutter, no Dio, no Drift. Entities (immutable value classes: `Profile`, `LogEntry`), repository contracts (abstract classes: `ProfileRepository`), failure types (sealed unions, Week 6), value objects (`Money`, `EmailAddress`, etc). If you import `flutter/material.dart` in this folder — refactor.

**What lives in `application/`:** the orchestrators — Services (domain operations, this week's focus), Notifiers (Riverpod-managed UI state, Week 4), use-case classes (one-action wrappers, optional), Providers (dependency injection wiring, Week 4). The Service is what we add this week — the heart of the application layer.

**What lives in `presentation/`:** only screens (Scaffold + body), widgets (reusable view components), routes (consumed by `go_router`). And nothing else: no HTTP, no SQL, no business rules, no error mapping.

## The Service Pattern

**What a Service IS:** "A class that exposes the domain operations of one feature, orchestrating the repositories it needs." Domain operations, not CRUD — `enrol(name, role)` yes; `insert(profile)` no (that's a repository method).

**What a Service is NOT:**
- Not a god-class — one Service per feature, not one for the whole app.
- Not a state holder — UI state belongs in Notifiers (Week 4).
- Not a Flutter import — Services never import `flutter/material.dart`.
- Not a CRUD wrapper — Services speak the domain, not the storage.
- Not a singleton you `new` up everywhere — they're injected via Riverpod (Week 4).

**The six rules of the Service — referenced for the rest of the course:**
| Rule | Description |
|---|---|
| S1 — One per feature | `ProfileService`, `LogsService` — not a giant `AppService` |
| S2 — Stateless | No instance fields holding UI state (exceptions documented, e.g. `SyncService` Week 9) |
| S3 — Returns domain types | `Profile`, `List<LogEntry>`, `Result<T>` (Week 6) — never an HTTP `Response` |
| S4 — Depends on abstractions | Constructor takes `ProfileRepository` (abstract), not `DriftProfileRepository` |
| S5 — No Flutter import | Pure Dart, testable on the command line with `dart test` |
| S6 — Orchestrates, doesn't render | Coordinates repositories; never builds widgets |

**The shape of a Service:**
```dart
class ProfileService {
  const ProfileService(this._repository);
  final ProfileRepository _repository;  // S4 — abstract!

  Future<Profile> enrol({required String id, required String name}) async {
    final profile = Profile(id: id, name: name, role: 'Member');
    await _repository.save(profile);
    return profile;
  }
}
```
Notice: no Flutter, no HTTP, no SQL — pure orchestration.

**The repository contract (`domain/profile_repository.dart`):**
```dart
abstract class ProfileRepository {
  Future<Profile?> load(String id);
  Future<void> save(Profile profile);
}
```
The Service depends on this — nothing else. In Week 4, Riverpod wires a concrete implementation here; in Week 7 that concrete becomes Drift-backed. The Service never changes.

**The concrete repository (`data/fake_profile_repository.dart`):**
```dart
class FakeProfileRepository implements ProfileRepository {
  Profile? _stored;
  @override
  Future<Profile?> load(String id) async => _stored;
  @override
  Future<void> save(Profile profile) async { _stored = profile; }
}
```
In Week 7 a `DriftProfileRepository` replaces this — the Service code stays unchanged.

**The full picture:** `Widget (presentation/) → Notifier (Week 4 preview) → Service (application/) → Repository abstract (domain/) → Storage concrete (data/)`. Outer depends on inner; each box knows only the abstraction in front of it.

## OOP Fundamentals Applied, Line by Line

- **Encapsulation** — `_repository` is private; outside code cannot reach the data layer.
- **Dependency Injection** — passed via constructor; tests inject a fake; no `new` inside the class.
- **Composition** — Service HAS a Repository; it doesn't EXTEND Repository.
- **Polymorphism (LSP)** — any `ProfileRepository` can be passed; `FakeRepo`, `DriftRepo`, `ApiRepo` all fit.
- **Immutability** — Service's `_repository` is `final`; once constructed, the dependency is fixed.

**SOLID in 90 seconds, one Flutter-specific example per letter:**
| Letter | Principle | Example |
|---|---|---|
| S | Single Responsibility | `ProfileService.enrol` — one job, not also email-sending |
| O | Open/Closed | Add a new `Failure` variant without touching existing Service code |
| L | Liskov Substitution | Any `ProfileRepository` works wherever the abstract type is used |
| I | Interface Segregation | `ProfileRepository` has only what `ProfileService` needs — nothing else |
| D | Dependency Inversion | Service depends on abstraction; concrete repo wired in by Riverpod (Week 4) |

## Live Coding — Refactoring FieldLog to Layered Architecture

1. Create the folders: `mkdir -p lib/src/features/profile/{data,domain,application,presentation}`. The structure is the architecture — once the folders exist, every file knows where it goes.
2. `domain/profile.dart` — the entity: `final class Profile { const Profile({required this.id, required this.name, required this.role}); final String id; final String name; final String role; }`. `final class` — cannot be extended, composition only.
3. The contract and the fake: `domain/profile_repository.dart` (abstract class with `load`/`save`) and `data/fake_profile_repository.dart` (`FakeProfileRepository implements ProfileRepository`).
4. `application/profile_service.dart` — the Service, constructed with the abstract repository, exposing `enrol(...)`.
5. Wire the screen — Service only: `presentation/profile_screen.dart` imports the Service only, no `data/` reference, no repository reference. `late final _service = ProfileService(FakeProfileRepository());`. In Week 4 replace `late final _service` with a Riverpod provider — less wiring, same architecture.

## Exercise E03.1 — Refactor FieldLog to Layered Architecture

- [ ] Folder structure: `lib/src/features/profile/{data,domain,application,presentation}/`
- [ ] `Profile` entity in `domain/` — `final class`, `==`, `hashCode`, no Flutter import
- [ ] `ProfileRepository` abstract in `domain/`
- [ ] `FakeProfileRepository implements ProfileRepository` in `data/`
- [ ] `ProfileService` depends ONLY on the abstract `ProfileRepository`
- [ ] Profile screen imports Service — never the repository directly
- [ ] README documents layer dependencies as a diagram

**Self-check:** `grep -r ProfileRepository lib/src/features/profile/presentation/` must return nothing.

## Before Week 4 Begins

- Push E03.1 — four-layer structure visible in the file tree.
- M1 (Team + PRD-lite) committed to your team's repo by Monday.
- Read Riverpod 2.x official docs — "Why Riverpod?" and "Notifier" (20 min).
- Watch Code With Andrea — Riverpod 2 first 30 minutes.
- Next week we replace `ProfileService(FakeProfileRepository())` with a Riverpod provider.

**If the Service Pattern is unclear, fix it this week — every later week assumes it.**

## Key Terms

- **Layered architecture** — `presentation → application → domain ← data`, dependencies point inward only.
- **Service** — stateless class per feature that orchestrates repositories and exposes domain operations (six rules S1–S6).
- **Repository contract** — abstract class in `domain/` defining what storage must support, with concrete implementations in `data/`.
- **Entity** — immutable, pure `final class` value type living in `domain/` (e.g. `Profile`).
- **Dependency Inversion** — Services depend on abstractions (`ProfileRepository`), never concrete implementations.

---

# Week 3 QCM — Chapter Exam (25 questions, with answer key)

**Provenance:** questions as presented in the Week 3 chapter exam; answers worked through against this note and the `fieldlog_flutter_week3` / `week4` snapshots. Not lesson content from the source PDF — this is an exam record appended for revision. `✓` marks the correct option; multi-select questions are flagged **[multi]**.

**Read this before using the key:** unlike Week 2, this exam **breaks the multi-select pattern twice**. Q20 and Q24 are *not* "A, B, C true, D false." Answer on content, not shape. Q24 also flips polarity — it asks which options **violate** the rules, so the correct selections are the bad code.

## Layers & Folder Placement (Q1–Q6)

**Q1.** Which is the correct dependency direction in our layered architecture?
- A. Presentation depends on Data directly
- B. Each layer depends on the next outer layer
- C. ✓ **Outer layers depend on inner layers; never the reverse**
- D. All layers depend on each other equally

*Source:* line 38 — `presentation → application → domain ← data`, *"arrows point inward — inner layers know nothing about outer ones."* B is the direction reversed (would mean `domain` imports `data`). **`data` is the case that looks exceptional but isn't** — it is an outer layer that also points inward, because it *implements* the abstract contract (line 39). Both arrows in `application → domain ← data` point at `domain`; nothing points out of it. *Caution:* line 108's *"Repository abstract → Storage concrete"* uses forward arrows for **runtime call flow**, not dependency — the two are opposite on that hop. If a question says "arrows" without qualifying, answer from line 38.

**Q2.** Which folder is the correct location for a `Profile` immutable entity?
- A. `data/`
- B. ✓ **`domain/`**
- C. `application/`
- D. `presentation/`

*Source:* lines 45, 162. *Trap:* A — `data/` holds **DTOs** (wire-format, `fromJson`/`toJson`, Week 10), which are a different thing from entities. If an entity grows a `fromJson`, it has drifted into `data/`. `final class` (line 130) is the language-level enforcement of composition-over-inheritance.

**Q3.** Where does a `FakeProfileRepository` (concrete implementation) belong?
- A. ✓ **`data/`**
- B. `domain/`
- C. `application/`
- D. `presentation/`

*Source:* lines 43, 96. The abstract/concrete split across two folders is the point: contract in `domain/`, implementations in `data/` (line 161). *Note:* correct folder ≠ correct consumer — `week3` places the fake in `data/` correctly, yet `presentation/profile_screen.dart:5` imports it. See Errata 1.

**Q4.** The abstract `ProfileRepository` contract belongs in:
- A. `data/`
- B. ✓ **`domain/`**
- C. `application/`
- D. `presentation/`

*Source:* lines 45, 87, 161. *Trap:* A — "repository sounds like data" is the intuition to resist. The contract lives in `domain/` **so the Service can depend on it without depending on `data/`**. Move it to `data/` and the arrow from `application` flips outward; the architecture collapses. This is the whole content of Dependency Inversion (line 125).

**Q5.** **[multi]** Which of these belong in the `application/` layer?
- A. ✓ **Services**
- B. ✓ **Riverpod Notifiers (from W4 onwards)**
- C. ✓ **Use-case orchestration** (line 47 marks these *optional*)
- D. Drift table definitions — *false; storage schema belongs in `data/`, Week 7*

*Source:* line 47. The **fourth** resident this question omits: **Providers** (Riverpod DI wiring) — which is why `week4/application/profile_providers.dart` sits in this layer rather than a top-level `providers/`. Unifying test: everything here **orchestrates**; nothing stores, renders, or defines domain types. D in `application/` would force a Drift import into the Service, breaking S5 and Dependency Inversion at once.

**Q6.** The `presentation/` layer should NEVER:
- A. Use `Theme.of(context)`
- B. ✓ **Import from `data/` directly**
- C. Call methods on a Service
- D. Use Material 3 widgets

*Source:* lines 40, 49. A and D are **inverted rules** — things presentation *must* do (Week 2 line 108 mandates `Theme.of(context)`). C is the sanctioned path *through* the layers; confusing "calls a Service" with "reaches past a Service" is the intended misread. **Against your own repo: `week3` fails this, `week4` passes it** — see Errata 1.

## The Service Pattern (Q7–Q12)

**Q7.** The Service Pattern's primary purpose is to:
- A. Render UI
- B. Store data persistently
- C. ✓ **Expose domain operations for one feature, orchestrating repositories**
- D. Replace `Navigator.push`

*Source:* line 53, near-verbatim. A breaks S6 (and S5). B is the repository's job — line 94 calls storage *"a detail"*. *Why B is the strongest distractor:* `enrol()` **does** cause a save. The distinction is **orchestrating** persistence versus **being** persistence — the Service decides *that* a profile is stored and what shape it has, with no idea whether storage is memory, Drift, or REST.

**Q8.** **[multi]** Which of these are among the Six Rules of a Service?
- A. ✓ **S1 — One Service per feature**
- B. ✓ **S2 — Stateless (no instance fields holding UI state)**
- C. ✓ **S4 — Depends on abstractions only**
- D. Use `extends` to inherit from Repository — *false; the negation of line 114*

*Not asked:* **S3** returns domain types (line 67), **S5** no Flutter import (69), **S6** orchestrates, doesn't render (70). D is not merely absent but inverts a named principle: *"Service HAS a Repository; it doesn't EXTEND Repository."* Keyword map — `implements` is correct one layer down (`FakeProfileRepository implements ProfileRepository`); `extends` is correct almost nowhere (Riverpod's generated `_$ProfileNotifier` is the rare sanctioned case).

**Q9.** `LogsService.recordToday(entry)` is preferred over `LogsService.insert(entry)` because:
- A. It is shorter
- B. ✓ **It expresses a domain operation (intent), not a CRUD operation**
- C. `insert` is a reserved word in Dart
- D. It uses fewer characters

*Source:* lines 53, 59. A and D are the same claim twice and both are **factually backwards** — `recordToday` (11 chars) is *longer* than `insert` (6). C is invented. *Substance:* `recordToday` carries business knowledge the storage verb destroys — "today" says the entry is date-stamped and that logs have a one-per-day notion at all. Verb test: `recordToday`/`enrol`/`archive` → Service; `insert`/`save`/`load`/`delete` → Repository. Your own chain shows both vocabularies: `ProfileService.enrol()` calls `_repository.save(profile)`.

**Q10.** A `ProfileService` constructor parameter should be typed as:
- A. `FakeProfileRepository` (concrete)
- B. `DriftProfileRepository` (concrete, future implementation)
- C. ✓ **`ProfileRepository` (abstract)**
- D. `dynamic`

*Source:* S4, lines 68, 76. *Trap:* B looks responsible because Drift is the *real* implementation — **concreteness is the defect, not fakeness**. Line 94's promise (*"the Service never changes"*) only holds if the parameter names the abstraction. D discards type safety, moving failures to runtime.

**Q11.** The Service file should NEVER import from:
- A. `dart:async`
- B. Its own `domain/` folder
- C. ✓ **`package:flutter/material.dart`**
- D. Other Services in the same feature

*Source:* S5, lines 58, 69. *Trap:* B **inverts a required dependency** — `application → domain` is the sanctioned arrow; the Service can't return a `Profile` without importing `Profile`. A is pure Dart and fine. *Why the ban is load-bearing:* importing `material.dart` drags in `BuildContext` and the Flutter binding, so the Service can then only be tested under `flutter_test` with a pumped widget — line 69's `dart test` stops working, and `Widget` becomes a legal return type (S6 exposure). Riverpod's `riverpod_annotation` is pure Dart, which is why W4's DI wiring can live in `application/` without breaking S5.

**Q12.** **[multi]** Which of these are TRUE about a Service?
- A. ✓ **It returns domain types, not DTOs** (S3, line 67)
- B. ✓ **It holds no UI state (no loading flags, no error messages)** (S2, line 66)
- C. ✓ **It depends on abstractions only** (S4, line 68)
- D. It calls `setState` in widgets — *false; breaks S5 and S6 simultaneously*

*On A:* if a Service returned `ProfileDto`, JSON field names would leak to `presentation/`. Mappers convert DTO → entity inside `data/`. *On B:* line 66 permits **documented exceptions** (`SyncService`, Week 9), so S2 is "stateless unless justified in writing," not absolute.

## Repository & the Week 7 Swap (Q13–Q14)

**Q13.** A Repository's responsibility is to:
- A. Hold UI state
- B. ✓ **Abstract the data source (DB, API, in-memory) behind a contract**
- C. Orchestrate multiple Services
- D. Render widgets

*Source:* lines 94, 161. *Trap:* C **inverts control** — Services orchestrate repositories (line 53), never the reverse; the repository is innermost in the call chain (line 108) and has no idea a Service exists. The three sources in B are line 43's progression: `Fake` (in-memory, W3) → `Drift` (local DB, W7) → `Api` (REST, W10), all satisfying one two-method contract. Discriminator from a Service: **repositories speak storage verbs, Services speak domain verbs.**

**Q14.** When swapping `FakeProfileRepository` → `DriftProfileRepository` in Week 7, the `ProfileService` code should:
- A. Be rewritten entirely
- B. ✓ **Need no changes — only the provider wiring is updated**
- C. Require its tests to be rewritten
- D. Be deleted

*Source:* lines 94, 106. *Trap:* C **inverts the payoff** — Service tests inject a fake, so they never touch Drift. Tests passing untouched is the regression net proving the swap was behaviour-preserving; if Drift invalidated them, they were coupled to storage too. In `week4`, the single changing line is `profile_providers.dart:22` — `FakeProfileRepository` appears **once** in the whole app. *Contrast:* in `week3` the same swap would require editing `presentation/profile_screen.dart:23` — a widget file, outermost layer. That is the concrete cost of Errata 1. *Honest caveat:* the signature survives, but a real DB adds failure modes memory lacks (I/O, migrations, constraints) — hence Week 6's `Result<T>` / sealed failures. "No changes" means no rewrite *forced by the swap*.

## OOP & SOLID (Q15–Q18)

**Q15.** Encapsulation in the Service is achieved by:
- A. Making the repository field public
- B. ✓ **Making the repository field private (`_repository`) and `final`**
- C. Using static methods
- D. Inheriting from the Repository

*Source:* lines 112, 116. C can't hold an injected dependency — forces the Service to construct its own repository, killing DI and testability. *Mechanism:* Dart's `_` is **library-private**, so `_repository` is invisible to every widget, test, and other Service outside `profile_service.dart`. Drop the underscore and encapsulation is gone app-wide, because the field joins the public API. One line, three principles: `final ProfileRepository _repository;` → `_` encapsulation (112), `final` immutability (116), abstract type Dependency Inversion (125).

**Q16.** Composition over inheritance, applied to the Service, means:
- A. The Service `extends` the Repository
- B. ✓ **The Service holds a Repository as a field (composition)**
- C. The Service `implements` the Repository interface
- D. The Service has no dependencies

*Source:* line 114. *Best distractor:* C — `implements` is genuinely **correct one layer down**, in `data/`. Here it would make the Service *become* a repository, adopting `load`/`save` as its public API: storage verbs on an orchestrator, breaking S1 and the CRUD ban (line 59). D leaves nothing to orchestrate. *Why composition wins concretely:* `extends` fixes one repository type at compile time and exposes its methods; a field lets any implementation be swapped at construction — which is what makes the W7 migration one line and lets tests inject a `_RecordingRepository` the Service has never heard of.

**Q17.** **[multi]** Which SOLID principles are directly applied by the Service Pattern?
- A. ✓ **Single Responsibility (one feature)** — **S**, line 121
- B. ✓ **Dependency Inversion (depend on abstractions)** — **D**, line 125
- C. ✓ **Open-Closed (extend by adding new Repository implementations)** — **O**, line 122
- D. Singleton — *false on two independent grounds*

*Why D fails twice:* **Singleton is not a SOLID letter** (it is a Gang-of-Four creational pattern), **and** line 60 explicitly rejects it — *"not a singleton you `new` up everywhere — they're injected via Riverpod."* Note `keepAlive: true` in W4 is **not** a singleton: it gives one instance per `ProviderContainer`, which is exactly why a test can spin up a fresh container with a different repository. *Not asked:* **L** Liskov (123), **I** Interface Segregation (124). *Precision:* the deck's own O example is *"add a new `Failure` variant"* (W6 sealed unions), not repository implementations — the option's phrasing differs but is still a valid O application.

**Q18.** Which test verifies the Single Responsibility Principle?
- A. "Can I name the class in one word?"
- B. ✓ **"Can I name the class without using *and* or *or*?"**
- C. "Is the class fewer than 50 lines?"
- D. "Does the class have one public method?"

*Consistent with* line 121 — *"one job, **not also** email-sending."* A is too strict (`ProfileService` is two words and fine — conjunctions are the problem, not compounds). C measures size, not cohesion. **D is refuted by your own code:** `week3/profile_service.dart` has **two** public methods (`find`, `enrol`), both profile operations, SRP intact — one-public-method is the *use-case class* pattern, which line 47 lists separately and marks optional. That file is also 34 lines, so it would pass C while telling you nothing. **Coverage gap: this heuristic appears nowhere in this note** — see Errata 5.

## Entity & Value Equality (Q19–Q20)

**Q19.** A domain entity like `Profile` should be:
- A. Mutable, with public setters
- B. ✓ **Immutable, with `final` fields, value equality**
- C. A subclass of `ChangeNotifier`
- D. A `StatefulWidget`

*Source:* lines 45, 138, 162. *Best distractor:* C — a real Flutter pattern that *sounds* like state management done properly. `ChangeNotifier` is `package:flutter/foundation.dart`, so it breaks `domain/` purity (line 45: *"if you import `flutter/material.dart` in this folder — refactor"*), and makes an entity that notifies rather than just *is*. It is also the pre-Riverpod approach W4's README names as a common AI mistake. D is "The Rot" (lines 16-27) — the entity *becoming* the widget. `copyWith` is how you "change" an immutable entity, which is why A is unnecessary rather than merely forbidden.

**Q20.** ⚠ **PATTERN BREAK** — To give a Dart class value equality manually, you implement:
- A. ✓ **`operator ==`**
- B. ✓ **`hashCode` getter**
- C. `toString` for debugging — *recommended, not required for equality (the option says so itself)*
- D. `copyWith` — *recommended, optional*

**Answer is A + B only**, matching E03.1 line 138's two requirements. *The substantive point:* **never one alone.** Dart's contract is that `a == b` implies `a.hashCode == b.hashCode`. Override `==` and skip `hashCode` and objects compare equal but hash to different buckets — a `Set` holds visible duplicates, `Map` lookups miss. It compiles, `expect(a, equals(b))` passes, and it fails silently the moment a collection is involved. The analyzer catches it via `hash_and_equals`. In `profile.dart`, `Object.hash(id, name, role)` covers **exactly** the three fields `==` compares — mismatched field sets between the two is the classic bug. The `identical(this, other)` short-circuit is a cheap same-instance fast path. This manual boilerplate is why other courses reach for `freezed`/`equatable`; here you write it by hand.

## Refactoring, Testing, Documentation (Q21–Q23)

**Q21.** The refactor from W2 to W3 should leave the behaviour of the app:
- A. Significantly different
- B. ✓ **Identical from the user's perspective (only structure changes)**
- C. Broken until W4
- D. Improved with new features

*Source:* the exercise title itself, line 135, and the commit convention `E03.1: Refactor to layered architecture`. *Pedagogical weight:* **behaviour preservation is what makes a refactor verifiable** — same inputs, same outputs, different internals, so a break is attributable to the restructure. D (features + restructure in one commit) destroys that attribution. *Honest complication in this repo:* `week3` is **not** strictly behaviour-identical to `week2` — it adds `_enrol()`, an "Enrol me" button, a snackbar, and an "Enrolled as …" label. That is the deck's doing, not a student slip: `enrol` is the domain operation lines 78-83 need to demonstrate anything. All *existing* W2 behaviour (routing, theming, `:name`, back button) is untouched — nothing rewritten, only relocated. Answer B; but if asked in short-answer whether E03.1 was a *pure* refactor, the accurate answer is "structural refactor plus one additive domain operation, required by the worked example."

**Q22.** Why is the Service Pattern testable without a database?
- A. Services use mocks of the framework
- B. ✓ **The Service depends on an abstract Repository — tests inject a fake**
- C. Dart provides automatic mocks
- D. Services have no dependencies

*Source:* lines 69, 113. A has nothing to mock (S5 means no framework present). C is fabricated — `mockito`/`mocktail` are third-party; this course uses hand-written fakes. *Trap:* D is backwards — testability comes from **how** the dependency is expressed, not its absence. Two properties from line 113, both needed: **abstract type** (any implementation substitutable, LSP line 123) and **no `new` inside the class** (the test controls what arrives). Break either and testability dies. *Why "no database" matters beyond convenience:* a DB-backed test needs setup, teardown, migrations, and file I/O — slow, order-dependent, flaky. `week3/test/profile_service_test.dart` (three Service tests with a fake) is line 69's claim exercised.

**Q23.** The README for E03.1 should document:
- A. Nothing — code speaks for itself
- B. ✓ **A simple diagram showing the four layers and their dependency directions**
- C. A full UML class diagram
- D. Every method signature

*Source:* line 143. *Trap:* C is *more* work, which makes it feel safer — but the criterion says **layer dependencies**, and a perfectly drawn class diagram of `Profile`/`ProfileService`/`ProfileRepository`/`FakeProfileRepository` still would not show the line-38 rule. D duplicates code and rots on first edit. A also drops the AI Notes section, mandatory in every project README. *Note on the `week3` README:* the folder tree at lines 12-19 satisfies the letter of the criterion, but a tree shows **structure**, not **direction** — the graded content is the arrows. Adding the literal line `presentation → application → domain ← data` makes the rule explicit.

## Violations & Track B (Q24–Q25)

**Q24.** ⚠ **PATTERN BREAK + POLARITY FLIP** — Which of these would VIOLATE the Six Rules of a Service?
- A. ✓ **VIOLATES** — a Service that imports `package:flutter/material.dart` → **S5** (line 69); kills `dart test`, opens S6 exposure
- B. ✓ **VIOLATES** — a Service with a `bool _loading = false;` instance field → **S2** (line 66); a loading flag is UI state, belongs in a Notifier (line 57)
- C. Fine — returns `Stream<List<LogEntry>>` → **S3 satisfied**; `LogEntry` is a domain entity (line 45), `Stream` is `dart:async`
- D. Fine — constructor takes an abstract Repository → **S4 satisfied**; this *is* the rule (line 68)

**Answer is A + B.** *Sharpest distractor on either exam:* D states a rule **being followed** and invites you to flag it as a breach — misread the polarity and the whole answer inverts. *C requires real judgment:* a `Stream` return looks stateful and reactive, but S3 constrains the **payload type**, not the container. `Stream<List<LogEntry>>` carries domain entities, so it passes; `Stream<http.Response>` or `Stream<ProfileDto>` would fail. Streams of domain types are how W7+ reactive repositories surface DB watches. *On B:* line 66 permits documented S2 exceptions (`SyncService`, W9), but `bool _loading` is precisely the UI-state case S2 names — not justifiable. `week4` sits exactly on this line: `ProfileService` holds no `_loading` (S2 clean) while `profile_screen.dart:23` holds `bool _saving` in **presentation**, which W5's `AsyncNotifier` folds into `AsyncValue`.

**Q25.** The M1 deliverable due in W4 from each team includes:
- A. A working prototype on Play Store
- B. ✓ **PRD-lite with problem, target user, three features** *(see discrepancy below)*
- C. The completed final pitch deck
- D. A signed AAB

*Source:* line 150 (*"M1 (Team + PRD-lite) committed to your team's repo by Monday"*) and line 10 for contents. A is **M7, Week 15**. *Discrepancy:* option B's fourth element reads *"API approach"*, but the note's fourth M1 item is **"why mobile not web."** Grepping both decks for "API approach" returns nothing — it appears nowhere in the course notes. Select B (first three items verbatim correct, other options off by 10+ weeks), but in a short answer write *"why mobile, not web"*. What line 10 actually lists: (1) problem statement **in one sentence**; (2) target user **described as a real person**; (3) three core features **ranked**; (4) **why mobile not web** — matching Week 2's Track B brief (lines 129-130), since M1 is where that assignment gets committed. The question's premise is correct: line 150 sits under "Before Week 4 Begins," and W2 line 131 says milestones run *"from Week 3 onward"*, so M1 is assigned W3 and lands Monday of W4.

## Answer key (compact)

| Q | Ans | Q | Ans | Q | Ans | Q | Ans | Q | Ans |
|---|---|---|---|---|---|---|---|---|---|
| 1 | C | 6 | B | 11 | C | 16 | B | 21 | B |
| 2 | B | 7 | C | 12 | A B C | 17 | A B C | 22 | B |
| 3 | A | 8 | A B C | 13 | B | 18 | B | 23 | B |
| 4 | B | 9 | B | 14 | B | 19 | B | 24 | **A B** ⚠ |
| 5 | A B C | 10 | C | 15 | B | 20 | **A B** ⚠ | 25 | B |

**Multi-select shape:** Q5, Q8, Q12, Q17 follow Week 2's "A B C true, D false." **Q20 and Q24 do not** — both are A+B, and Q24 additionally asks for the *violations* rather than the compliant options. Do not answer by pattern.

## Errata — internal contradictions in this note

Found while working the exam. Unlike Week 2, there is **no version staleness** here — this deck teaches patterns, not package APIs, so nothing has rotted. All findings are internal consistency, and Errata 1 is the only one that costs marks.

1. **Line 133 contradicts itself inside one bullet.** Step 5 reads *"imports the Service only, **no `data/` reference, no repository reference**"* and then gives `late final _service = ProfileService(FakeProfileRepository());` — which **is** a repository reference and cannot compile without importing `data/`. `week3/presentation/profile_screen.dart:5` follows the instruction and therefore breaches line 40 and line 49, and **fails the deck's own self-check at line 145** (`grep -r ProfileRepository .../presentation/` returns one match, since `FakeProfileRepository` contains the substring). The tension is real — W3 has no DI mechanism, so *something* must construct the fake — but the deck never says the intermediate state knowingly violates the rule. **E03.1 as written cannot pass while step 5 is followed as written.** `week4` resolves it: one import (`../application/profile_providers.dart`), self-check clean. Secondary defect: the check is stricter than its wording — `grep -rw` or grepping the import line would express the intent.
2. **Line 101 — the fake's `load` ignores its parameter.** `Future<Profile?> load(String id) async => _stored;` takes `id` and never reads it, so `load('anyone')` returns whoever was saved last. `week3`/`week4` both diverge from the slide and fix it: `return _stored?.id == id ? _stored : null;`.
3. **Line 130's entity sample omits what line 138 requires.** Step 2 shows fields and constructor only; the checklist demands `final class`, `==`, `hashCode`, no Flutter import. The slide's own sample would fail two of its four criteria. `profile.dart` has all four.
4. **Line 108's arrows reverse line 38's.** *"Repository abstract → Storage concrete"* read as dependency says `domain` depends on `data` — the exact inversion the lesson prevents. Line 108 describes **runtime call flow**, which genuinely runs left-to-right, but it reuses the same arrow glyph 70 lines after the dependency diagram and never labels the switch. Dependency and call direction are opposite on that hop, which *is* Dependency Inversion (line 125) — obscured here.
5. **Coverage gap (Q18).** The SRP naming heuristic ("without *and* or *or*") appears nowhere in this markdown; line 121 is the only SRP content and gives an example, not a test. Together with Week 2's `context.go` gap, that is two exam questions across two decks testing material absent from the conversions — worth re-running `lesson-to-markdown` on both PDFs before the final.
6. **Q25's "API approach"** is not an M1 item in this note. Line 10's fourth item is *"why mobile not web."*
