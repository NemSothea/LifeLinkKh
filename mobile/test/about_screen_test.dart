import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/config/env.dart';
import 'package:lifelink_kh/src/core/links/link_opener.dart';
import 'package:lifelink_kh/src/core/links/link_providers.dart';
import 'package:lifelink_kh/src/core/settings/locale_controller.dart';
import 'package:lifelink_kh/src/core/settings/locale_store.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_controller.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_store.dart';
import 'package:lifelink_kh/src/features/about/application/about_providers.dart';
import 'package:lifelink_kh/src/features/about/presentation/about_screen.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/presentation/sign_in_screen.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';
import 'package:lifelink_kh/src/features/onboarding/presentation/intro_screen.dart';

import 'support/auth_fakes.dart';

final class _RecordingLinkOpener implements LinkOpener {
    final List<Uri> opened = [];

    @override
    Future<bool> open(Uri uri) async {
        opened.add(uri);
        return true;
    }
}

/// The trust surface: the sign-in footer (how it works, privacy, about & help, version)
/// and the About screen behind it. What these tests protect is that all of it is
/// reachable *signed out* — the questions matter before anyone hands over an account —
/// and that the footer never pushes the non-scrolling sign-in screen into an overflow.
/// Scrolls [finder] fully on screen: `scrollUntilVisible` stops at the first pixel,
/// which can leave a tap's centre point just off the bottom edge.
Future<void> _bring(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
}

void main() {
    late _RecordingLinkOpener links;
    late InMemoryOnboardingStore onboarding;
    late FakePushTokenSource pushTokens;

    setUp(() {
        links = _RecordingLinkOpener();
        onboarding = InMemoryOnboardingStore(seen: true);
        pushTokens = FakePushTokenSource();
    });

    tearDown(() => pushTokens.refreshes.close());

    Future<void> pumpApp(
        WidgetTester tester, {
        Locale locale = const Locale('km'),
        bool signedIn = false,
    }) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(
                        FakeSessionStore(signedIn ? testSession() : null),
                    ),
                    googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    fcmTokenRepositoryProvider.overrideWithValue(FakeFcmTokenRepository()),
                    pushTokenSourceProvider.overrideWithValue(pushTokens),
                    fakeLocalDataEraser(),
                    onboardingStoreProvider.overrideWithValue(onboarding),
                    localeStoreProvider.overrideWithValue(InMemoryLocaleStore(locale)),
                    linkOpenerProvider.overrideWithValue(links),
                    appVersionProvider.overrideWith(
                        (ref) async => (version: '1.0.0', build: '1'),
                    ),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();
    }

    group('sign-in footer', () {
        testWidgets('shows the three links and the version', (tester) async {
            await pumpApp(tester);

            expect(find.byKey(const Key('sign-in-how-it-works')), findsOneWidget);
            expect(find.byKey(const Key('sign-in-privacy')), findsOneWidget);
            expect(find.byKey(const Key('sign-in-about')), findsOneWidget);
            expect(find.text('v1.0.0 (1)'), findsOneWidget);
        });

        // The screen does not scroll by design, so the footer has to fit. A RenderFlex
        // overflow is reported as an exception, which fails the test on its own.
        for (final (name, locale, scale) in [
            ('en', const Locale('en'), 1.0),
            ('km', const Locale('km'), 1.0),
            ('km at 1.3x text', const Locale('km'), 1.3),
        ]) {
            testWidgets('fits a 360x640 phone without overflow — $name', (tester) async {
                tester.view.physicalSize = const Size(1080, 1920);
                tester.view.devicePixelRatio = 3.0;
                tester.platformDispatcher.textScaleFactorTestValue = scale;
                addTearDown(tester.view.reset);
                addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

                await pumpApp(tester, locale: locale);

                expect(find.byType(SignInScreen), findsOneWidget);
                expect(find.byKey(const Key('sign-in-version')), findsOneWidget);
                expect(tester.takeException(), isNull);
            });
        }

        testWidgets('Privacy opens the policy before sign-in', (tester) async {
            await pumpApp(tester);

            await tester.tap(find.byKey(const Key('sign-in-privacy')));
            await tester.pump();

            expect(links.opened, [Uri.parse('${Env.defaultPortalUrl}/km/privacy')]);
        });

        testWidgets('About opens signed out, and back returns to sign-in', (tester) async {
            await pumpApp(tester, locale: const Locale('en'));

            await tester.tap(find.byKey(const Key('sign-in-about')));
            await tester.pumpAndSettle();

            expect(find.byType(AboutScreen), findsOneWidget);
            expect(find.text('Group 2, Cross-Platform Mobile App Development course.'),
                findsOneWidget);
            await _bring(tester, find.byKey(const Key('about-version')));
            expect(find.text('Version 1.0.0 (build 1)'), findsOneWidget);

            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(find.byType(SignInScreen), findsOneWidget);
        });

        testWidgets('How it works reopens the intro without resetting it', (tester) async {
            await pumpApp(tester);

            await tester.tap(find.byKey(const Key('sign-in-how-it-works')));
            await tester.pumpAndSettle();
            expect(find.byType(IntroScreen), findsOneWidget);

            for (var i = 0; i < 3; i++) {
                await tester.tap(find.byKey(const Key('intro-next')));
                await tester.pumpAndSettle();
            }

            expect(find.byType(IntroScreen), findsNothing);
            expect(find.byType(SignInScreen), findsOneWidget);
            expect(onboarding.hasSeenIntro(), isTrue);
        });
    });

    group('About screen', () {
        testWidgets('answers each question with a string the app already shows',
            (tester) async {
            await pumpApp(tester, locale: const Locale('en'));
            await tester.tap(find.byKey(const Key('sign-in-about')));
            await tester.pumpAndSettle();

            final money = find.byKey(const Key('faq-money'));
            await _bring(tester, money);
            await tester.tap(money);
            await tester.pumpAndSettle();
            final moneyAnswer = find.textContaining('LifeLink never asks for money.');
            await _bring(tester, moneyAnswer);
            expect(moneyAnswer, findsOneWidget);

            final delete = find.byKey(const Key('faq-delete'));
            await _bring(tester, delete);
            await tester.tap(delete);
            await tester.pumpAndSettle();
            final deleteAnswer = find.text('Open the “Me” tab and tap “Delete account”.');
            await _bring(tester, deleteAnswer);
            expect(deleteAnswer, findsOneWidget);
        });

        testWidgets('is reachable from the Me tab when signed in', (tester) async {
            await pumpApp(tester, signedIn: true);

            await tester.tap(find.byKey(const Key('dashboard-tab-me')));
            await tester.pumpAndSettle();
            final about = find.byKey(const Key('me-about'));
            await tester.scrollUntilVisible(about, 200);
            await tester.tap(about);
            await tester.pumpAndSettle();

            expect(find.byType(AboutScreen), findsOneWidget);
        });

        testWidgets('How it works from About returns to About', (tester) async {
            await pumpApp(tester, signedIn: true);

            await tester.tap(find.byKey(const Key('dashboard-tab-me')));
            await tester.pumpAndSettle();
            final about = find.byKey(const Key('me-about'));
            await tester.scrollUntilVisible(about, 200);
            await tester.tap(about);
            await tester.pumpAndSettle();
            await _bring(tester, find.byKey(const Key('about-how-it-works')));
            await tester.tap(find.byKey(const Key('about-how-it-works')));
            await tester.pumpAndSettle();
            expect(find.byType(IntroScreen), findsOneWidget);

            await tester.tap(find.byKey(const Key('intro-skip')));
            await tester.pumpAndSettle();

            expect(find.byType(IntroScreen), findsNothing);
            expect(find.byType(AboutScreen), findsOneWidget);
        });
    });
}
