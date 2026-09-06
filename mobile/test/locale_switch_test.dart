import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/settings/locale_controller.dart';
import 'package:lifelink_kh/src/core/settings/locale_store.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/home/presentation/home_screen.dart';
import 'package:lifelink_kh/src/features/match/application/match_providers.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/request/application/request_providers.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_repository.dart';

import 'support/auth_fakes.dart';

/// `FR-GLOBAL-001`, mobile half: the Me tab's language toggle, wired the way the real
/// app wires it — `MaterialApp.locale` fed by `LocaleController`, so a tap has to
/// repaint the whole tree to pass, not merely change a provider's value.
final class _FakeMatchRepository implements MatchRepository {
    @override
    Future<Result<List<Match>>> fetchMine() async => const Success([]);

    @override
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) =>
        throw UnimplementedError();
}

final class _FakeRequestRepository implements RequestRepository {
    @override
    Future<Result<List<BloodRequest>>> fetchMine() async => const Success([]);

    @override
    Future<Result<List<Hospital>>> fetchHospitals() => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> cancel(String requestId) => throw UnimplementedError();
}

final class _FakeDonationRepository implements DonationRepository {
    @override
    Future<Result<List<Donation>>> fetchMine() async => const Success([]);
}

/// Deliberately not `MaterialApp(locale: ...)` with a fixed value like the other widget
/// tests use: this one is about the wiring itself, so the locale comes from the
/// controller exactly as `LifeLinkApp` takes it.
Widget _wrap(LocaleStore store) {
    return ProviderScope(
        overrides: [
            localeStoreProvider.overrideWithValue(store),
            sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
            telegramAuthRepositoryProvider.overrideWithValue(FakeTelegramAuthRepository()),
            donorRepositoryProvider.overrideWithValue(FakeDonorRepository()),
            matchRepositoryProvider.overrideWithValue(_FakeMatchRepository()),
            requestRepositoryProvider.overrideWithValue(_FakeRequestRepository()),
            donationRepositoryProvider.overrideWithValue(_FakeDonationRepository()),
        ],
        child: Consumer(
            builder: (context, ref, _) => MaterialApp(
                locale: ref.watch(localeControllerProvider),
                localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LocaleController.supported,
                home: const HomeScreen(),
            ),
        ),
    );
}

Future<void> _openMeTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dashboard-tab-me')));
    await tester.pumpAndSettle();
}

void main() {
    testWidgets('a fresh install starts in Khmer', (tester) async {
        await tester.pumpWidget(_wrap(InMemoryLocaleStore()));
        await tester.pumpAndSettle();
        await _openMeTab(tester);

        expect(find.text('ភាសា'), findsOneWidget);
        expect(find.text('Language'), findsNothing);
    });

    testWidgets('tapping English repaints the app in English and stores the choice',
        (tester) async {
        final store = InMemoryLocaleStore();
        await tester.pumpWidget(_wrap(store));
        await tester.pumpAndSettle();
        await _openMeTab(tester);

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        // The tab bar is the check, not the card: it proves the whole tree rebuilt,
        // not just the control that was tapped.
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);
        expect(store.read(), const Locale('en'));
    });

    testWidgets('the stored choice survives a restart', (tester) async {
        await tester.pumpWidget(_wrap(InMemoryLocaleStore(const Locale('en'))));
        await tester.pumpAndSettle();
        await _openMeTab(tester);

        expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('a stored language this build no longer supports falls back to Khmer',
        (tester) async {
        await tester.pumpWidget(_wrap(InMemoryLocaleStore(const Locale('fr'))));
        await tester.pumpAndSettle();
        await _openMeTab(tester);

        expect(find.text('ភាសា'), findsOneWidget);
    });
}
