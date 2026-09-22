import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'onboarding_store.dart';

part 'onboarding_controller.g.dart';

/// Overridden in `main.dart` with the `SharedPreferences`-backed store. The default is
/// the forgetful one, so no test has to stub a platform channel to build a screen.
@Riverpod(keepAlive: true)
OnboardingStore onboardingStore(OnboardingStoreRef ref) => InMemoryOnboardingStore();

/// Whether the intro still has to be shown.
///
/// `keepAlive` because the router reads it inside `redirect`, which runs on every
/// navigation — a provider that disposed between routes would re-read the store each
/// time and, worse, reset to "not seen" mid-session.
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
    @override
    bool build() => ref.read(onboardingStoreProvider).hasSeenIntro();

    /// Marks the intro done and lets the router move on.
    ///
    /// State first, write second — same order as `LocaleController.select`, and for the
    /// same reason: the redirect that follows should not wait on a disk write. A failed
    /// write costs one extra showing at next launch, which is the harmless direction to
    /// fail in.
    Future<void> complete() async {
        state = true;
        await ref.read(onboardingStoreProvider).markIntroSeen();
    }
}
