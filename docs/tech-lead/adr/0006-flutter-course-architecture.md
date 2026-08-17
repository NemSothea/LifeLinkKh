---
id: 0006-flutter-course-architecture
title: Flutter app follows the course architecture — layered features, Riverpod 2.x with code generation
status: accepted
date: 2026-08-17
deciders: Tech Lead
---

> **ACCEPTED 2026-08-17** by Nem Sothea as Tech Lead and Mobile owner. `mobile/` is a single-owner
> scope, so this is not a cross-role decision — but it changes a pinned dependency downward, which
> is the kind of thing that looks like a mistake in six weeks unless it is written down.
>
> This also discharges the ADR owed since M2 for **Riverpod** and **go_router**
> (`docs/fullstack/specs/foundation/mobile-flutter.md` § follow-ups, and the standing item in
> `.claude/RESUME.md`).

## Context

The Flutter app was scaffolded at M2 to be *working*, not to be *conformant*. It grew a
`lib/features/` + `lib/core/` layout with hand-written Riverpod providers, and each of those choices
is individually defensible in a normal Flutter project.

They are not defensible here, because this app is graded by the lecturer who wrote
`mobile/docslesson/` — six weeks of slides and chapter exams that prescribe a specific architecture
in checkable detail. An audit against Weeks 1–6 found ten divergences. Two mattered more than the
rest:

1. **`home_screen.dart` imported `../data/health_repository.dart`.** Week 4 exists to remove that
   exact import; its exam calls doing so "the Week 4 deliverable" and asks about it twice.
2. **Every provider was hand-written** as `final xProvider = Provider((ref) => ...)`. Week 4's exam
   names that as the canonical AI-generated Riverpod error, alongside `extends StateNotifier`.

The rest: source outside `lib/src/` (Week 1 Rule #1), no `domain/` or `application/` layer, no
abstract repository and so no Service Pattern at all (Week 3, rules S1–S6), providers declared in
`data/`, no dark theme (Week 2), and a default Flutter README with no AI Notes section.

The course targets are not arbitrary style. The layering is what makes the M3 auth work testable
without an emulator, and `docs/qa/test-strategy.md` already assumes a mobile layer it can substitute
fakes into.

## Decision

**Build `mobile/` to the course architecture.** Concretely, as of this ADR:

| Rule | Applied |
|---|---|
| W1 — source under `lib/src/` | `lib/src/{app.dart,core,router,features}`; `main.dart` is `runApp()` only |
| W2 — Material 3, light **and** dark | one seed colour, `AppTheme.light` + `AppTheme.dark` |
| W2 — go_router only, routes declared centrally | already held; `lib/src/router/app_router.dart`, zero `Navigator.push` |
| W3 — four layers per feature | `home/{domain,data,application,presentation}` |
| W3 — entity is a `final class` with value equality, no Flutter import | `HealthStatus` |
| W3 — abstract repository in `domain/`, concrete in `data/` | `HealthRepository` / `DioHealthRepository` |
| W3 — Service Pattern S1–S6 | `HealthService`; the table in `mobile/README.md` maps each rule |
| W4 — `ProviderScope` at the root, `ConsumerWidget`, no `setState` | already held |
| W4 — providers via `@riverpod` code generation | `riverpod_annotation` + `riverpod_generator` + `build_runner` |
| W4 — providers live in `application/`, screen never imports `data/` | `health_providers.dart`; the screen has one feature import |
| W1/W2 — README with a layer diagram and AI Notes | `mobile/README.md` rewritten |

**Riverpod moves from 3.4.2 down to 2.6.x.** Two reasons, and the second is what forces it:

- The course prescribes 2.x ("Riverpod 2.x — OUR PICK", Week 4).
- **`riverpod_generator` cannot be solved against `flutter_riverpod` 3.x on Flutter 3.44.6.** The
  generator's dependency chain requires `matcher <0.12.19`; this SDK's `flutter_test` pins
  `matcher 0.12.19` exactly. Verified by probing a scratch package: Riverpod 2.6.1 + generator 2.6.3
  resolves cleanly, 3.4.2 + any generator does not.

Code generation is a Week 4 requirement and the runtime is not, so the runtime moved.

**Two rules are deliberately deferred, and both are dated:**

- **Week 5 — `AsyncNotifier`, four-state rendering, skeleton loading, retry, pull-to-refresh.**
- **Week 6 — sealed `Failure` and `Result<T>`; repositories stop throwing for domain failures.**

Both land with the M3 auth and donor screens. The only async surface today is a health check that
returns one string: it has no empty state, and a `Retry` on it retries nothing a user cares about.
Building either now means writing the plumbing twice.

## Consequences

**What improves immediately.** The M3 mobile work has somewhere to go: `AuthService` and
`DonorService` drop into `application/` beside `HealthService`, their repositories are abstract from
the first line, and the sign-in screen can be widget-tested against a fake token exchange with no
Firebase and no emulator — which matters, because the Firebase project still does not exist.

**What it costs.** Riverpod 2.x is a real downgrade in one respect: 3.x's automatic retry of failed
providers is gone. That was working *against* us — `home_screen_test.dart` had to pass
`ProviderScope(retry: ...)` to keep an error state from flipping back to loading — so the workaround
disappeared with the upgrade path. If a future dependency demands Riverpod 3, code generation is the
thing that breaks, and this ADR is the record of why that trade was made this way round.

**A pass-through Service is not a smell here.** `HealthService.check()` only forwards to the
repository. That is the seam being installed before it is needed, which is the cheap order — Week 4's
own recap shows the Service surviving the Riverpod refactor with a zero-line diff, and that only
works if the Service already exists.

**`.g.dart` files are committed.** Week 4's exercise checks that generation happened, and a graded
checkout should not depend on the grader running `build_runner`.

**`custom_lint` + `riverpod_lint` are not installed.** The course lists them as recommended rather
than required. They also cannot be solved on this SDK — `custom_lint` pulls an analyzer that wants
the `_macros` package, which has been removed from the Dart SDK. Revisit when the toolchain moves.

**The M2 mobile spec is now stale** — `docs/fullstack/specs/foundation/mobile-flutter.md` still
records `flutter_riverpod ^3.4.2`, a folder tree without `src/`, per-feature layers as
`{data,domain,presentation}` with no `application/`, and a Riverpod-3 retry note. That file is
Fullstack's scope, not Tech Lead's; the correction is owed there.

## Alternatives considered

**Stay on Riverpod 3 and hand-write providers.** Keeps the newer runtime and the automatic retry.
Rejected: it fails a Week 4 acceptance criterion outright, and hand-written providers are the
specific thing the course flags as the AI-generated mistake. Being knowingly wrong on the graded
criterion to keep a minor-version advantage is the wrong trade in a course project.

**Stay on Riverpod 3 and upgrade the Flutter SDK to unblock the generator.** Possibly viable, and
rejected as the wrong risk at the wrong time: an SDK bump six weeks before M7 puts the Android build
and the signed AAB in play to fix a dependency-resolution problem that a documented downgrade solves
for free.

**Apply the layering to M3 features only, leaving `home/` as it is.** Cheaper today. Rejected because
`home/` is the worked example every later feature gets copied from, and because the divergence would
then be permanent — nobody refactors a screen that works.

**Do everything including Weeks 5 and 6 now.** Fully conformant immediately. Rejected: it writes
`Result<T>` plumbing for one endpoint and invents an empty state for a value that cannot be empty,
and both get rewritten when the real screens arrive.
