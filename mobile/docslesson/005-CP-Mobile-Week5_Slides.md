# Week 5 — Cross-Platform Mobile Application Development

**Topic:** Async State Done Right — AsyncNotifier & AsyncValue
**Instructor:** Mr. Sok Pongsametrey · Asia Euro University · 8 August 2026
**Subtitle:** Every screen has four states — most apps render two

> Source PDF is named `003-CP-Mobile-Week5_Slides.pdf` at repo root (prefix mis-numbered by the lecturer, same as Week 4; content is Week 5 of 16, 22 slides).

## Where We Are After Week 4 (E04.1 recap)

Common bugs the lecturer saw in submitted W4 work:

- **`ref.read` in `build()`** — doesn't subscribe, so the UI never rebuilds when state changes.
- **`ref.watch` in callbacks** — subscribes on every tap and rebuilds the world. Use `read` for one-shots.
- **Forgot `build_runner`** — generator never ran, `.g.dart` files missing. Run `dart run build_runner watch`.
- **`ConsumerWidget` confusion** — mixed `StatefulWidget` with `ConsumerStatefulWidget` incorrectly.

**Today's question:** *"What does your screen show while data is loading?"* And what does it show when the data is empty? When it fails? Most Bachelor's projects answer "a spinner" or "nothing". We do better.

## The Four-State Framework

Every async surface has four states:

| State | What it must render |
|---|---|
| **Loading** | Skeleton placeholder rows. **NOT** a centered spinner. |
| **Data** | The actual list, detail, or form. |
| **Error** | Typed message + Retry CTA. Never swallow. |
| **Empty** | Its own UI with a clear next action. |

> **If your screen does not render all four, it is not done.**

## The Silent-Failure Anti-Pattern

```dart
// Forbidden in this course:
try {
  data = await repo.fetchAll();
} catch (_) {}

// Why: the user sees 'nothing happened'. You see 'works on my machine'.
```

Every `catch` must either **log + surface + retry**, OR **throw further**. Never both swallow and continue.

## AsyncValue&lt;T&gt; as a Sealed Union

```dart
sealed class AsyncValue<T> {
  // AsyncLoading<T>  — operation in flight
  // AsyncData<T>     — completed with value T
  // AsyncError<T>    — completed with an error
}
```

Three variants. The compiler enforces handling all three when you use `state.when(...)`.

### `state.when` — exhaustive matching

```dart
final state = ref.watch(logsNotifierProvider);

return state.when(
  loading: () => const LoadingSkeleton(),
  data: (entries) => entries.isEmpty
      ? const EmptyState()
      : LogList(entries),
  error: (e, _) => ErrorState(
    message: e.toString(),
    onRetry: () => ref.invalidate(logsNotifierProvider),
  ),
);
```

Note: the union has **three** variants but the screen has **four** states — Empty is carved out of Data by the `isEmpty` branch, not by the type system.

## Notifier vs AsyncNotifier

**`Notifier<T>` (W4)** — synchronous state. No loading concept.

```dart
@riverpod
class P extends _$P {
  Profile? build() {
    return null;
  }
}
```

**`AsyncNotifier<T>` (W5)** — async. Wrapped in `AsyncValue` automatically.

```dart
@riverpod
class L extends _$L {
  Future<List<E>> build() async {
    return service.loadAll();
  }
}
```

## The Layer Boundary — the Service Does Not Know About AsyncValue

- Service returns a plain `Future<T>`: `Future<List<LogEntry>> loadAll()`
- The **Notifier** — not the Service — wraps it: `AsyncValue<List<LogEntry>>`

Same rule as W3's **S5**: the Service has no Flutter or Riverpod imports. It is testable on the command line with `dart test`.

## Loading UX — Skeletons, Not Spinners

- **Spinner ✗** — what most apps do. Implies failure when slow. Hides layout.
- **Skeleton ✓** — what we do. Matches eventual layout. Perceived faster.

## Empty State — Not a Special Case of Data

The mistake:

```dart
data: (list) => ListView(children: list...)
```

An empty list renders nothing. The user wonders if the app is broken.

The fix:

```dart
data: (list) => list.isEmpty
    ? const EmptyState()
    : LogList(list),
```

`EmptyState` shows an icon, a message, and a clear next action.

## Live Coding — Build the Logs Feature (4 steps)

### Step 1 — Structure the feature

```bash
mkdir -p lib/src/features/logs/{domain,data,application,presentation}
```

Same four-layer pattern as `profile`. Same Six Rules of Service from W3. What changes: the Notifier becomes an `AsyncNotifier`.

Files created today:

```
domain/log_entry.dart              (entity)
domain/logs_repository.dart        (abstract contract)
data/fake_logs_repository.dart     (1s + 20% failure)
application/logs_service.dart      (Six-Rules service)
application/logs_providers.dart    (AsyncNotifier)
presentation/logs_list_screen.dart (four states)
```

### Step 2 — Fake repository with simulated failure

```dart
class FakeLogsRepository implements LogsRepository {
  final _entries = <LogEntry>[];
  final _r = Random();

  @override
  Future<List<LogEntry>> fetchAll() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_r.nextInt(5) == 0) {
      throw Exception('Network unavailable');
    }
    return List.unmodifiable(_entries.reversed);
  }
}
```

### Step 3 — The AsyncNotifier

```dart
@riverpod
class LogsNotifier extends _$LogsNotifier {
  @override
  Future<List<LogEntry>> build() async {
    final service = ref.read(logsServiceProvider);
    return service.loadAll();
  }
}
```

Riverpod wraps the Future in `AsyncValue`. Exceptions become `AsyncError` automatically.

### Step 4 — Render the four states

```dart
final state = ref.watch(logsNotifierProvider);

return RefreshIndicator(
  onRefresh: () async => ref.invalidate(logsNotifierProvider),
  child: state.when(
    loading: () => const LoadingSkeleton(),
    error: (e, _) => ErrorState(
      message: e.toString(),
      onRetry: () => ref.invalidate(logsNotifierProvider),
    ),
    data: (entries) => entries.isEmpty
        ? const EmptyState()
        : LogList(entries),
  ),
);
```

## Live Test on the Emulator

1. First load → Loading (skeleton) → Empty (no entries yet)
2. Tap 'Add sample' → 500 ms → Data (1 entry)
3. Pull to refresh repeatedly → eventually Error (20% rate)
4. Tap Retry → Loading → Data again

> Every reload exercises a different state. Students who only saw 'data' aren't done.

## What We Will Fix Next Week

The Repository still **throws** exceptions. Problems with thrown exceptions:

- Invisible control flow — the signature lies
- Easy to forget to catch
- The UI sees raw `Exception` strings, not typed failures

**Week 6:** errors become values. `Future<Result<T>>` instead of `Future<T>` that throws.

## Exercise — E05.1: AsyncNotifier with Four States

- [ ] `LogsRepository` simulates 1s latency and 20% failure rate (`Random().nextInt(5) == 0`)
- [ ] `logsNotifierProvider` is an `@riverpod` `AsyncNotifier`
- [ ] Screen renders loading, error, empty, and data states distinctly
- [ ] Error state has a Retry button calling `ref.invalidate`
- [ ] Loading is a skeleton (shimmer or hand-rolled), **NOT** a centered spinner
- [ ] Pull-to-refresh wired up with `RefreshIndicator`
- [ ] README has an AI Notes section

**Verification:** verify all four states by reloading multiple times. Submit a video or 4 screenshots.

### Stretch tasks (if E05.1 finishes early)

- **`AsyncValue.guard`** — use it somewhere it improves code clarity over `try`/`catch`.
- **Family provider** — add `logsByCategoryProvider(String category)` using a family modifier.
- **Khmer translations** — localize all four state messages: Empty, Error, Retry, Loading skeleton ARIA label.

## Team Milestone M2 — Wireframes & Feature Scope (due W6)

- Wireframes for all 3 core features (Figma, Excalidraw, or hand-drawn photo)
- Written scope statement that names what is **NOT** in scope
- Push to team repo as `docs/M2-wireframes/`
- First random presentations begin next week — prepare your demo

> The scope statement is graded harder than the wireframes. Saying NO is the deliverable.

## Before Week 6 Begins

- Push E05.1 with the four states demonstrable
- M2 wireframes committed to your team repo by Monday
- Read: `freezed` package README — Union types section (10 min)
- Reflect: when the network fails, who in your code finds out?

> Next week: random presentations begin. Two students × 10 minutes. Be ready.

## Key Terms

- **AsyncValue&lt;T&gt;** — Riverpod's sealed union with three variants: `AsyncLoading`, `AsyncData`, `AsyncError`.
- **AsyncNotifier** — a Notifier whose `build()` returns `Future<T>`; Riverpod wraps the result in `AsyncValue` automatically and turns thrown exceptions into `AsyncError`.
- **`state.when(...)`** — exhaustive pattern match over the three `AsyncValue` variants; the compiler forces all three to be handled.
- **Skeleton** — a placeholder UI matching the eventual layout, used instead of a spinner so loading feels faster and the layout does not jump.
- **Empty state** — a distinct UI (icon + message + next action) carved out of the data branch when the collection is empty; not "an empty list".
- **Silent-failure anti-pattern** — `catch (_) {}`: swallowing an error and continuing, so the user sees nothing happen and the developer sees "works on my machine".
- **`ref.invalidate`** — discards a provider's cached state so it rebuilds; the mechanism behind both Retry and pull-to-refresh in this lesson.
