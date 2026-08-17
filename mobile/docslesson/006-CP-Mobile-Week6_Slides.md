# Week 6 — Cross-Platform Mobile Application Development

**Topic:** Errors as Values — Sealed Failures & Result Types
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 15 August 2026
**Subtitle:** When your network call fails, who in your code finds out?
**Source:** `006-CP-Mobile-Week6_Slides.pdf` at repo root, 24 slides.
**Capstone:** FieldLog — week 6 = week 5 code + typed domain failures end-to-end.

## Course Process Changes

### Random presentations begin

From this week forward, the first 20 minutes of every session:

- Two students drawn at random demo their previous exercise.
- 10 minutes each: 8 min demo + 2 min Q&A from peers.
- Once drawn, you are out of the pool until everyone has gone.
- Grading: counted toward participation; visibility for the final pitch.

> Why this works: you prepare every exercise expecting to be called.

### M2 wireframe lightning review

30 seconds per team, one screen showing:

- Your three core features wired up as wireframes.
- Your scope statement — what is **NOT** in scope.

The one question asked per team: **"What feature could you cut and still ship?"** If you cannot answer in 30 seconds, the scope is too wide. Update your PRD-lite by next Monday with the cut.

## Today's Question

> *"When your network call fails, who in your code finds out?"*

In W5 the answer was: whoever forgets to catch the exception, finds out at runtime, in production. This week we fix that.

## The Disease — What Thrown Exceptions Hide

- **Invisible control flow** — `Future<List<LogEntry>>` does not say "this might throw NetworkException". The signature lies.
- **Easy to forget** — no compiler help on "did you catch this?" The type checker stays quiet while a bug ships.
- **Fights the type system** — exceptions are an out-of-band signaling mechanism, bypassing every other tool we use.
- **Stringly-typed UI** — the widget sees `e.toString()`, never a typed Failure with a clear UI strategy.

## The Fix — Errors as Values

```dart
// Before:
Future<List<LogEntry>> fetchAll();          // may throw

// After:
Future<Result<List<LogEntry>>> fetchAll();  // never throws
```

> The signature tells you the truth. The compiler enforces handling.

## Sealed Classes for Closed Unions (Dart 3)

```dart
sealed class Failure {
  const Failure({required this.message});
  final String message;
}

class NetworkFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class UnauthorizedFailure extends Failure { ... }
class UnknownFailure extends Failure { ... }
```

`sealed class` = all subclasses are declared in this file. The compiler can enumerate them.

## Pattern Matching Is Exhaustive

```dart
final (icon, title) = switch (failure) {
  NetworkFailure() => (Icons.wifi_off, 'Network unavailable'),
  NotFoundFailure() => (Icons.search_off, 'Not found'),
  UnauthorizedFailure() => (Icons.lock, 'Please sign in'),
  UnknownFailure() => (Icons.error_outline, 'Something went wrong'),
};
```

> Forget a variant? The compiler tells you exactly which one and where.

## The Return Type — `Result<T> = Success<T> | Failed<T>`

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
```

## Design Choice — `Result<T>` vs `Either<L, R>`

| `Result<T>` (our choice) | `Either<L, R>` (alternative) |
|---|---|
| ✓ Failure is the only error type | ✓ Generic in both sides |
| ✓ Hand-rolled — no fpdart dependency | ✓ Standard in functional Dart (fpdart) |
| ✓ Simpler for students | ✗ Adds a package dependency |
| ✓ Pattern matches as Success / Failed | ✗ Left / Right names are abstract |

> Either approach is acceptable for E06.1. Document your choice and rationale in the README.

## Layer Boundaries — Who Maps Platform Errors to Domain Failures?

| Layer | Responsibility |
|---|---|
| **Platform** | `DioException`, `SqliteException` |
| **Data** | Catches platform errors, returns `Failed(...)` |
| **Application** | Passes Failure up unchanged |
| **Presentation** | Pattern-matches per variant |

> The DATA layer is where the translation happens. The UI never sees a `DioException`.

**Break exercise:** grep your code for `try` and `catch` — which ones still belong?

## Pattern Catalog — Failure Is the Strategy Pattern, Type-Checked

- **Classical Strategy:** each algorithm in its own class, swapped at runtime — but no compiler help.
- **Our Failure:** each variant carries its display strategy (icon, title, retry semantics). The compiler enforces that every UI handles every variant.

> Result: a pattern from a 1994 book made safe by 2024 Dart 3.

## AI Workflow — Where AI Helps and Hurts on Freezed-Like Code

**AI helps:**
- Generating the boilerplate of a sealed union.
- Suggesting common Failure variants for a domain.
- Writing the switch-case pattern for typed error UI.

**AI hurts:**
- Often mixes Dart 2 syntax with Dart 3 sealed classes.
- Suggests outdated `freezed` package syntax (pre-3.0).
- Recommends `Either` when `Result` is simpler for your case.

> Write your AI Notes — one prompt where AI got it wrong and how you fixed it.

## Live Coding — 4 Steps

### Step 1 of 4 — Define Failure and Result

```bash
$ touch lib/src/features/logs/domain/failure.dart
$ touch lib/src/features/logs/domain/result.dart
```

```dart
// In failure.dart:
sealed class Failure { ... }
class NetworkFailure extends Failure { ... }
// (4 variants total)

// In result.dart:
sealed class Result<T> { ... }
class Success<T> extends Result<T> { ... }
class Failed<T> extends Result<T> { ... }
```

### Step 2 of 4 — Refactor the repository

```dart
// Before:
Future<List<LogEntry>> fetchAll() async {
  if (failure) throw Exception(...);
  return entries;
}

// After:
Future<Result<List<LogEntry>>> fetchAll() async {
  if (networkFailure) return const Failed(NetworkFailure());
  if (authFailure) return const Failed(UnauthorizedFailure());
  return Success(entries);
}
```

### Step 3 of 4 — Update Service & Notifier

```dart
// Service: signature changes, body passes Result through.
Future<Result<List<LogEntry>>> loadAll() => _repository.fetchAll();

// Notifier: unpack the Result.
@riverpod
class LogsNotifier extends _$LogsNotifier {
  Future<List<LogEntry>> build() async {
    final r = await service.loadAll();
    return switch (r) {
      Success(:final value) => value,
      Failed(:final failure) => throw failure,
    };
  }
}
```

### Step 4 of 4 — Typed error UI per Failure variant

```dart
error: (e, _) {
  final failure = e is Failure ? e : const UnknownFailure();
  final (icon, title) = switch (failure) {
    NetworkFailure() => (Icons.wifi_off, 'Network unavailable'),
    NotFoundFailure() => (Icons.search_off, 'Not found'),
    UnauthorizedFailure() => (Icons.lock, 'Please sign in'),
    UnknownFailure() => (Icons.error_outline, 'Something went wrong'),
  };
  return ErrorState(icon, title, failure.message);
},
```

## Two Kinds of Errors — When `throw` Is Still Right

**Domain failures — use Result:**
- Network unavailable, record not found, token expired, validation rejected.
- Anything the user might encounter.

**Programmer errors — still throw:**
- Null dereferences, illegal arguments, broken invariants.
- Things that mean: a developer made a mistake.

> Rule of thumb: if the user could cause it, it's a Failure.

## What Changes in Week 7

W7: local persistence with Drift.

- `FakeLogsRepository` is replaced by `DriftLogsRepository` (real SQLite).
- SQL exceptions get mapped to our Failure variants — in the DATA layer.
- **Service, Notifier, UI: unchanged. That is Rule S4 paying off again.**

Watch for: the Failure mapping moves with the data layer. Wherever errors come FROM is responsible for translation.

### Before Week 7 begins

- Push E06.1 with sealed Failures end-to-end.
- Read: Drift docs — "Getting started" + "Defining tables" (20 min).
- Test-install Drift: `flutter pub add drift drift_flutter sqlite3_flutter_libs` in a scratch repo.
- Be ready: random presentations continue every week.

> Next week: logs survive app restart. Drift turns FieldLog into a real local-first app.

## Exercise — E06.1: Sealed Errors and Result Types

- [ ] `Failure` is a sealed union with at least 4 variants
- [ ] `LogsRepository` returns `Future<Result<T>>` — does not throw for domain failures
- [ ] Pattern matching on `Failure` is exhaustive (compiler verifies)
- [ ] Error UI shows different content per variant — verify each
- [ ] README documents your choice (`Result` vs `Either`) and rationale
- [ ] AI Notes: one prompt where AI generated incorrect code
- [ ] Demo all 4 Failure UIs in your video submission — simulate each variant explicitly

### Stretch tasks (if you finish E06.1 early)

- [ ] **`Failure.fromException` factory** — handle `DioException`'s major types and `SocketException`
- [ ] **Severity logging** — log every Failure with severity at the data layer; use the `logger` package
- [ ] **"Report this error" CTA** — button that copies failure details to clipboard for support tickets

## Key Terms

- **Errors as values** — returning failure as part of the return type instead of throwing, so the signature states the truth and the compiler enforces handling.
- **Sealed class** — Dart 3 class whose subclasses are all declared in the same file, letting the compiler enumerate every variant.
- **Exhaustive pattern matching** — a `switch` over a sealed type that the compiler rejects unless every variant is handled.
- **`Result<T>`** — sealed union of `Success<T>` (carries a value) and `Failed<T>` (carries a `Failure`); the repository return type this week.
- **`Either<L, R>`** — fpdart's generic-on-both-sides alternative to `Result`; acceptable for E06.1 if the README documents the rationale.
- **Domain failure vs programmer error** — user-encounterable conditions become `Failure` values; developer mistakes (null deref, illegal argument, broken invariant) still `throw`.
