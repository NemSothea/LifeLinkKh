import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/error/crash_handling.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_controller.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_store.dart';
import 'package:lifelink_kh/src/core/widgets/screen_failure.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
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
import 'package:lifelink_kh/src/router/app_router.dart';

import 'support/auth_fakes.dart';

final class _EmptyMatches implements MatchRepository {
    @override
    Future<Result<List<Match>>> fetchMine() async => const Success([]);
    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) =>
        throw UnimplementedError();
}

final class _EmptyRequests implements RequestRepository {
    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() async => const Success([]);
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

final class _EmptyDonations implements DonationRepository {
    @override
    Future<Result<List<Donation>>> fetchMine() async => const Success([]);
}

class _Throws extends StatelessWidget {
    const _Throws();
    @override
    Widget build(BuildContext context) => throw StateError('a bug in a build method');
}

Widget _localized(Widget home, {String locale = 'en'}) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('km'), Locale('en')],
    home: home,
);

void main() {
    final details = FlutterErrorDetails(exception: StateError('boom'));

    test('debug keeps the red box, release shows the friendly screen', () {
        expect(buildErrorWidget(details, debug: true), isA<ErrorWidget>());
        expect(buildErrorWidget(details, debug: false), isA<ScreenFailure>());
    });

    testWidgets('a widget that throws is replaced by the friendly screen in release',
        (tester) async {
        final original = ErrorWidget.builder;
        ErrorWidget.builder = (details) => buildErrorWidget(details, debug: false);
        // Restored in the body, not addTearDown: the framework checks this global is
        // back to its original value before teardowns run.
        try {
            await tester.pumpWidget(_localized(const _Throws()));
            expect(tester.takeException(), isStateError);

            expect(find.byKey(const Key('screen-failure')), findsOneWidget);
            expect(find.text('Something went wrong on this screen'), findsOneWidget);
        } finally {
            ErrorWidget.builder = original;
        }
    });

    testWidgets('the friendly screen speaks the user language', (tester) async {
        await tester.pumpWidget(_localized(const ScreenFailure(), locale: 'km'));
        expect(find.text('មានបញ្ហាលើអេក្រង់នេះ'), findsOneWidget);
    });

    /// An error above MaterialApp has no theme, no localisations and no text direction.
    /// An error widget that throws there would loop, so it must draw anyway.
    testWidgets('the friendly screen draws with nothing above it', (tester) async {
        await tester.pumpWidget(const ScreenFailure());
        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong on this screen'), findsOneWidget);
    });

    testWidgets('an unknown address shows page-not-found with a way home', (tester) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    onboardingStoreProvider.overrideWithValue(InMemoryOnboardingStore(seen: true)),
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
                    googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    donorRepositoryProvider.overrideWithValue(
                        FakeDonorRepository()..profile = testProfile(isEligible: true),
                    ),
                    matchRepositoryProvider.overrideWithValue(_EmptyMatches()),
                    requestRepositoryProvider.overrideWithValue(_EmptyRequests()),
                    donationRepositoryProvider.overrideWithValue(_EmptyDonations()),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(tester.element(find.byType(LifeLinkApp)));
        container.read(appRouterProvider).go('/no-such-screen');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('route-not-found')), findsOneWidget);

        await tester.tap(find.byKey(const Key('route-not-found-home')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('route-not-found')), findsNothing);
        expect(find.byKey(const Key('home-list')), findsOneWidget);
    });
}
