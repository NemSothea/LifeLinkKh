import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_controller.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_store.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/home/application/health_providers.dart';
import 'package:lifelink_kh/src/features/onboarding/presentation/intro_screen.dart';

import 'support/auth_fakes.dart';

/// The intro exists to answer "why should I?" before the app asks for a Google account,
/// so what these tests actually protect is that it appears exactly once and never stands
/// between a donor and a request.
void main() {
    late InMemoryOnboardingStore onboarding;

    /// Boots the whole app — router included — because the intro is a routing decision
    /// before it is a screen. Building `IntroScreen` directly would test the carousel and
    /// none of the behaviour that matters.
    Future<void> pumpApp(WidgetTester tester) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    onboardingStoreProvider.overrideWithValue(onboarding),
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(FakeSessionStore(null)),
                    googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    telegramAuthRepositoryProvider.overrideWithValue(
                        FakeTelegramAuthRepository(),
                    ),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();
    }

    testWidgets('a fresh install sees the intro before it is asked to sign in', (tester) async {
        onboarding = InMemoryOnboardingStore(seen: false);

        await pumpApp(tester);

        expect(find.byType(IntroScreen), findsOneWidget);
    });

    testWidgets('skipping goes straight to sign-in and does not come back', (tester) async {
        onboarding = InMemoryOnboardingStore(seen: false);
        await pumpApp(tester);

        await tester.tap(find.byKey(const Key('intro-skip')));
        await tester.pumpAndSettle();

        expect(find.byType(IntroScreen), findsNothing);
        // Skipping is a legitimate way to finish: the flag is written, so the next launch
        // is not asked the same question again.
        expect(onboarding.hasSeenIntro(), isTrue);
    });

    testWidgets('the last slide ends the intro', (tester) async {
        onboarding = InMemoryOnboardingStore(seen: false);
        await pumpApp(tester);

        // Three slides: two taps to reach the last one, a third to leave.
        for (var i = 0; i < 3; i++) {
            await tester.tap(find.byKey(const Key('intro-next')));
            await tester.pumpAndSettle();
        }

        expect(find.byType(IntroScreen), findsNothing);
        expect(onboarding.hasSeenIntro(), isTrue);
    });

    testWidgets('a returning donor never sees it', (tester) async {
        onboarding = InMemoryOnboardingStore(seen: true);

        await pumpApp(tester);

        expect(find.byType(IntroScreen), findsNothing);
    });

    /// The 03:00 case. A donor who answers an alert has a session, and a session must not
    /// be routed through an explainer — whatever the flag says.
    testWidgets('a signed-in donor is never routed through the intro', (tester) async {
        onboarding = InMemoryOnboardingStore(seen: false);

        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    onboardingStoreProvider.overrideWithValue(onboarding),
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
                    googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    telegramAuthRepositoryProvider.overrideWithValue(
                        FakeTelegramAuthRepository(),
                    ),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(IntroScreen), findsNothing);
    });
}
