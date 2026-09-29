import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/settings/locale_controller.dart';
import 'package:lifelink_kh/src/core/settings/locale_store.dart';
import 'package:lifelink_kh/src/features/account/application/account_providers.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/domain/reauthentication.dart';
import 'package:lifelink_kh/src/features/home/presentation/me_tab.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';

import 'support/auth_fakes.dart';

/// DEC-016 through the real app: Me tab → confirmation screen → re-authentication →
/// callable → sign-in. Fakes only at the plugin and Function seams.
void main() {
    late FakeAccountRepository accounts;
    late FakeSessionStore sessionStore;
    late FakeGoogleCredentials credentials;
    late FakeFcmTokenRepository fcm;
    late FakePushTokenSource pushTokens;

    setUp(() {
        accounts = FakeAccountRepository();
        sessionStore = FakeSessionStore(testSession());
        credentials = FakeGoogleCredentials();
        fcm = FakeFcmTokenRepository();
        pushTokens = FakePushTokenSource();
    });

    tearDown(() => pushTokens.refreshes.close());

    Future<void> pumpApp(WidgetTester tester) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    // English, so the assertions below read as the copy they check.
                    localeStoreProvider.overrideWithValue(InMemoryLocaleStore(const Locale('en'))),
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(sessionStore),
                    googleCredentialsProvider.overrideWithValue(credentials),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    fcmTokenRepositoryProvider.overrideWithValue(fcm),
                    pushTokenSourceProvider.overrideWithValue(pushTokens),
                    fakeLocalDataEraser(),
                    accountRepositoryProvider.overrideWithValue(accounts),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();
    }

    /// Me tab, scrolled to the bottom where the action sits apart from everything else.
    Future<void> openDeleteAccount(WidgetTester tester) async {
        await tester.tap(find.byKey(const Key('dashboard-tab-me')));
        await tester.pumpAndSettle();
        final action = find.byKey(const Key('me-delete-account'));
        await tester.scrollUntilVisible(
            action,
            200,
            scrollable: find
                .descendant(of: find.byType(MeTab), matching: find.byType(Scrollable))
                .first,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
    }

    testWidgets('the Me tab offers Delete account, and a tap only opens the confirmation',
        (tester) async {
        await pumpApp(tester);
        await openDeleteAccount(tester);

        expect(find.text('Delete your account?'), findsOneWidget);
        expect(
            find.text('Your profile, blood type, location and phone numbers are deleted.'),
            findsOneWidget,
        );
        expect(find.text('This cannot be undone.'), findsOneWidget);
        expect(accounts.calls, 0, reason: 'one tap must never delete an account');
        expect(credentials.reauthCount, 0);
    });

    testWidgets('"Keep my account" goes back and deletes nothing', (tester) async {
        await pumpApp(tester);
        await openDeleteAccount(tester);
        await tester.tap(find.byKey(const Key('delete-account-keep')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('me-delete-account')), findsOneWidget);
        expect(accounts.calls, 0);
        expect(sessionStore.stored, isNotNull);
    });

    testWidgets('confirming deletes, lands on sign-in and says so', (tester) async {
        await pumpApp(tester);
        await openDeleteAccount(tester);
        await tester.tap(find.byKey(const Key('delete-account-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sign-in-google')), findsOneWidget);
        expect(find.text('Your account was deleted.'), findsOneWidget);
        expect(accounts.calls, 1);
        expect(credentials.reauthCount, 1);
        expect(sessionStore.stored, isNull);
        expect(credentials.signedOut, isTrue);
        // users/{uid} is already gone: clearing the push token there would be a refused
        // write, which is why deletion does not go through signOut().
        expect(fcm.clearCount, 0);
        // The device's own token still goes (SEC-REVIEW-003 F-20).
        expect(pushTokens.deleteCount, 1);
    });

    testWidgets('dismissing the re-authentication returns to the Me tab', (tester) async {
        credentials.reauthOutcomes.add(Reauthentication.cancelled);

        await pumpApp(tester);
        await openDeleteAccount(tester);
        await tester.tap(find.byKey(const Key('delete-account-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('me-delete-account')), findsOneWidget);
        expect(find.byKey(const Key('delete-account-error')), findsNothing);
        expect(accounts.calls, 0);
        expect(sessionStore.stored, isNotNull);
    });

    testWidgets('no network shows the connection message and keeps the session',
        (tester) async {
        accounts.results.add(const Failed(NetworkFailure()));

        await pumpApp(tester);
        await openDeleteAccount(tester);
        await tester.tap(find.byKey(const Key('delete-account-confirm')));
        await tester.pumpAndSettle();

        expect(
            find.text("Couldn't delete — check your connection and try again."),
            findsOneWidget,
        );
        expect(find.byKey(const Key('delete-account-confirm')), findsOneWidget);
        expect(sessionStore.stored, isNotNull);
        expect(credentials.signedOut, isFalse);
    });
}
