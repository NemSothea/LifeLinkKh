import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/google_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/session_store.dart';
import 'package:lifelink_kh/src/features/home/application/health_providers.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';

import 'support/auth_fakes.dart';

/// A [SessionStore] whose `read()` only resolves when the test says so — the fake in
/// `auth_fakes.dart` completes within one microtask, too fast for a `pump()` in between
/// to ever observe the loading state it produces.
final class _GatedSessionStore implements SessionStore {
    _GatedSessionStore(this._gate);

    final Completer<AuthSession?> _gate;

    @override
    Future<AuthSession?> read() => _gate.future;

    @override
    Future<void> write(AuthSession session) async {}

    @override
    Future<void> clear() async {}
}

/// A [GoogleCredentials] whose `signIn()` only resolves when the test says so — same
/// reason as `_GatedSessionStore`.
final class _GatedGoogleCredentials implements GoogleCredentials {
    _GatedGoogleCredentials(this._gate);

    final Completer<String?> _gate;

    @override
    Future<String?> signIn() => _gate.future;

    @override
    Future<String?> idToken({bool forceRefresh = false}) async => null;

    @override
    Future<void> signOut() async {}
}

/// Drives the whole M3 sign-in path — screen, controller, service, router redirect — with
/// fakes only at the plugin and transport seams. No Firebase, no emulator, no network.
void main() {
    late FakeAuthRepository repository;
    late FakeSessionStore sessionStore;
    late FakeGoogleCredentials credentials;
    late FakeFacebookCredentials facebookCredentials;
    late FakeTelegramAuthRepository telegramRepository;
    late FakeFcmTokenRepository fcm;
    late FakePushTokenSource pushTokens;

    setUp(() {
        repository = FakeAuthRepository();
        sessionStore = FakeSessionStore();
        credentials = FakeGoogleCredentials();
        facebookCredentials = FakeFacebookCredentials();
        telegramRepository = FakeTelegramAuthRepository();
        fcm = FakeFcmTokenRepository();
        pushTokens = FakePushTokenSource();
    });

    tearDown(() => pushTokens.refreshes.close());

    Future<void> pumpApp(WidgetTester tester) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    authRepositoryProvider.overrideWithValue(repository),
                    sessionStoreProvider.overrideWithValue(sessionStore),
                    googleCredentialsProvider.overrideWithValue(credentials),
                    facebookCredentialsProvider.overrideWithValue(facebookCredentials),
                    telegramAuthRepositoryProvider.overrideWithValue(telegramRepository),
                    fcmTokenRepositoryProvider.overrideWithValue(fcm),
                    pushTokenSourceProvider.overrideWithValue(pushTokens),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        // Two pumps: one for the keystore read, one for the redirect it triggers.
        await tester.pumpAndSettle();
    }

    // Sign-out lives on the dashboard's "Me" tab (GLOBAL-home-dashboard prototype),
    // not on the Home tab a fresh sign-in lands on.
    Future<void> goToMeTab(WidgetTester tester) async {
        await tester.tap(find.byKey(const Key('dashboard-tab-me')));
        await tester.pumpAndSettle();
    }

    testWidgets('a fresh install lands on sign-in, not home', (tester) async {
        await pumpApp(tester);

        expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
        expect(find.byKey(const Key('sign-out')), findsNothing);
    });

    testWidgets(
        'restoring the session shows a neutral splash, not "Signing in…" on unpressed buttons',
        (tester) async {
        // `FakeSessionStore.read()` completes within one microtask — too fast for a
        // `pump()` in between to ever observe. A store that only resolves once this test
        // says so is the only way to actually see the frame the router calls "still
        // reading the keystore".
        final restoreGate = Completer<AuthSession?>();
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    authRepositoryProvider.overrideWithValue(repository),
                    sessionStoreProvider.overrideWithValue(_GatedSessionStore(restoreGate)),
                    googleCredentialsProvider.overrideWithValue(credentials),
                    facebookCredentialsProvider.overrideWithValue(facebookCredentials),
                    telegramAuthRepositoryProvider.overrideWithValue(telegramRepository),
                    fcmTokenRepositoryProvider.overrideWithValue(fcm),
                    pushTokenSourceProvider.overrideWithValue(pushTokens),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pump();

        expect(find.byKey(const Key('sign-in-google')), findsNothing);
        expect(find.text('Signing in…'), findsNothing);

        restoreGate.complete(null);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
    });

    testWidgets(
        'tapping Google does not draw the untouched Facebook button as "Signing in…"',
        (tester) async {
        final signInGate = Completer<String?>();
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    authRepositoryProvider.overrideWithValue(repository),
                    sessionStoreProvider.overrideWithValue(sessionStore),
                    googleCredentialsProvider.overrideWithValue(
                        _GatedGoogleCredentials(signInGate),
                    ),
                    facebookCredentialsProvider.overrideWithValue(facebookCredentials),
                    telegramAuthRepositoryProvider.overrideWithValue(telegramRepository),
                    fcmTokenRepositoryProvider.overrideWithValue(fcm),
                    pushTokenSourceProvider.overrideWithValue(pushTokens),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pump();

        // Google — the one actually tapped — is busy.
        expect(find.text('Signing in…'), findsOneWidget);
        // Facebook is disabled (a concurrent attempt is still wrong) but must not claim
        // to be signing in too — it wasn't touched.
        expect(find.text('Continue with Facebook'), findsOneWidget);
        final facebookButton = tester.widget<OutlinedButton>(
            find.byKey(const Key('sign-in-facebook')),
        );
        expect(facebookButton.onPressed, isNull);

        signInGate.complete('firebase-id-token');
        await tester.pumpAndSettle();
    });

    testWidgets('a stored session skips sign-in entirely', (tester) async {
        // The FR-AUTH-003 criterion: the session persists across app restarts.
        sessionStore = FakeSessionStore(testSession());

        await pumpApp(tester);

        expect(find.byKey(const Key('sign-in-google')), findsNothing);
        await goToMeTab(tester);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
    });

    testWidgets('signing in stores the session, registers for push, and routes home',
        (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();

        await goToMeTab(tester);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
        expect(sessionStore.stored?.token, 'jwt-1');
        // DEC-002 pulled token registration into M3 precisely so that M4's request alert
        // has somewhere to send.
        expect(fcm.registered, ['fcm-token-1']);
    });

    testWidgets(
        'signing in via Facebook stores the session, registers for push, and routes home',
        (tester) async {
        await pumpApp(tester);

        expect(find.byKey(const Key('sign-in-facebook')), findsOneWidget);
        await tester.tap(find.byKey(const Key('sign-in-facebook')));
        await tester.pumpAndSettle();

        await goToMeTab(tester);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
        expect(sessionStore.stored?.token, 'jwt-1');
        expect(fcm.registered, ['fcm-token-1']);
    });

    testWidgets('a dismissed Facebook login dialog leaves the user on sign-in with no error',
        (tester) async {
        facebookCredentials.interactiveToken = null;

        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('sign-in-facebook')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-facebook')), findsOneWidget);
        expect(
            find.byKey(const Key('sign-in-error')),
            findsNothing,
            reason: 'a cancel is a choice, not a failure',
        );
        expect(repository.exchangeCount, 0);
    });

    testWidgets(
        'signing in via Telegram opens the sheet, verifies the code, and routes home',
        (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byKey(const Key('sign-in-telegram')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('telegram-code-entry')), findsOneWidget);

        await tester.enterText(
            find.byKey(const Key('telegram-code-field')),
            telegramRepository.validCode,
        );
        await tester.tap(find.byKey(const Key('telegram-submit')));
        await tester.pumpAndSettle();

        // The sheet closes itself on a real session, not on the tap.
        expect(find.byKey(const Key('telegram-code-entry')), findsNothing);
        await goToMeTab(tester);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
        expect(sessionStore.stored?.token, 'jwt-1');
        expect(fcm.registered, ['fcm-token-1']);
    });

    testWidgets('a wrong Telegram code shows an error and keeps the sheet open',
        (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byKey(const Key('sign-in-telegram')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('telegram-code-field')), '000000');
        await tester.tap(find.byKey(const Key('telegram-submit')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-error')), findsOneWidget);
        expect(find.byKey(const Key('telegram-code-entry')), findsOneWidget);
        expect(sessionStore.stored, isNull);
    });

    testWidgets('a dismissed account chooser leaves the user on sign-in with no error',
        (tester) async {
        credentials.interactiveToken = null;

        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
        expect(
            find.byKey(const Key('sign-in-error')),
            findsNothing,
            reason: 'a cancel is a choice, not a failure',
        );
        expect(repository.exchangeCount, 0);
    });

    testWidgets('a network failure renders its own message and offers a retry',
        (tester) async {
        repository.failure = const NetworkFailure();

        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-error')), findsOneWidget);
        expect(find.text('No connection. Check the network and try again.'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(sessionStore.stored, isNull);
    });

    testWidgets('a rate limit says wait, not retry-immediately', (tester) async {
        repository.failure = const RateLimitedFailure();

        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();

        expect(
            find.text('Too many attempts. Wait a minute before trying again.'),
            findsOneWidget,
        );
    });

    testWidgets('a retry after a failure can succeed', (tester) async {
        repository.failure = const ServerFailure();

        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sign-in-error')), findsOneWidget);

        repository.failure = null;
        await tester.tap(find.byKey(const Key('sign-in-google')));
        await tester.pumpAndSettle();

        await goToMeTab(tester);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
    });

    testWidgets('signing out clears push registration and returns to sign-in',
        (tester) async {
        sessionStore = FakeSessionStore(testSession());

        await pumpApp(tester);
        await goToMeTab(tester);
        await tester.tap(find.byKey(const Key('sign-out')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
        expect(sessionStore.stored, isNull);
        expect(credentials.signedOut, isTrue);
        // DELETE /auth/fcm-token, or the phone keeps receiving urgent-request alerts for
        // someone who signed out (ADR 0007 §5).
        expect(fcm.clearCount, 1);
    });
}
