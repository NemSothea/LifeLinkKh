import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_repository.dart';
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

/// The `GLOBAL-home-dashboard` prototype's shell, exercised at the repository seam
/// (rule S4) — no network, no Firebase. `sessionStoreProvider` supplies the signed-in
/// session directly, the same technique `sign_in_flow_test.dart` uses, so the real
/// `AuthController` resolves the role this shell branches on.
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

const _requesterSession = AuthSession(
    token: 'jwt-requester',
    user: AuthUser(
        id: '99999999-9999-9999-9999-999999999999',
        role: UserRole.requester,
        displayName: 'Chea Srey',
        isNewAccount: false,
    ),
);

Widget _wrap({
    DonorRepository? donorRepository,
    AuthSession? session,
    Locale locale = const Locale('en'),
}) {
    return ProviderScope(
        overrides: [
            sessionStoreProvider.overrideWithValue(
                FakeSessionStore(session ?? testSession()),
            ),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
            telegramAuthRepositoryProvider.overrideWithValue(FakeTelegramAuthRepository()),
            donorRepositoryProvider.overrideWithValue(
                donorRepository ?? FakeDonorRepository(),
            ),
            matchRepositoryProvider.overrideWithValue(_FakeMatchRepository()),
            requestRepositoryProvider.overrideWithValue(_FakeRequestRepository()),
            donationRepositoryProvider.overrideWithValue(_FakeDonationRepository()),
        ],
        child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('km'), Locale('en')],
            home: const HomeScreen(),
        ),
    );
}

void main() {
    testWidgets('a donor sees three tabs, Home first, with the become-a-donor prompt',
        (tester) async {
        await tester.pumpWidget(_wrap(donorRepository: FakeDonorRepository()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dashboard-tab-home')), findsOneWidget);
        expect(find.byKey(const Key('dashboard-tab-history')), findsOneWidget);
        expect(find.byKey(const Key('dashboard-tab-me')), findsOneWidget);
        expect(find.byKey(const Key('donor-home-start-setup')), findsOneWidget);
        // No donor profile yet means "requests near you" cannot mean anything (GET
        // /matches/me 404s without one) — the section is hidden, not shown empty.
        expect(find.byKey(const Key('donor-home-matches-empty')), findsNothing);
        expect(find.text('Requests near you'), findsNothing);
    });

    testWidgets('a registered donor sees their eligibility card on the Home tab',
        (tester) async {
        final repository = FakeDonorRepository()..profile = testProfile(isEligible: true);
        await tester.pumpWidget(_wrap(donorRepository: repository));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('eligibility-card')), findsOneWidget);
        expect(find.text('You can donate now'), findsOneWidget);
    });

    testWidgets('a registered donor with no nearby requests sees the empty state, not a stray heading',
        (tester) async {
        final repository = FakeDonorRepository()..profile = testProfile(isEligible: true);
        await tester.pumpWidget(_wrap(donorRepository: repository));
        await tester.pumpAndSettle();

        expect(find.text('Requests near you'), findsOneWidget);
        expect(find.byKey(const Key('donor-home-matches-empty')), findsOneWidget);
    });

    testWidgets('the History tab shows the donation history screen', (tester) async {
        await tester.pumpWidget(_wrap(donorRepository: FakeDonorRepository()));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dashboard-tab-history')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('donation-history-empty')), findsOneWidget);
    });

    testWidgets('the Me tab offers the donor profile, request blood, and sign-out',
        (tester) async {
        await tester.pumpWidget(_wrap(donorRepository: FakeDonorRepository()));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dashboard-tab-me')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('me-donor-profile')), findsOneWidget);
        expect(find.byKey(const Key('me-request-blood')), findsOneWidget);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
    });

    testWidgets('a requester sees two tabs and the oversized request-blood button',
        (tester) async {
        await tester.pumpWidget(_wrap(session: _requesterSession));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dashboard-tab-home')), findsOneWidget);
        expect(find.byKey(const Key('dashboard-tab-history')), findsNothing);
        expect(find.byKey(const Key('dashboard-tab-me')), findsOneWidget);
        expect(find.byKey(const Key('requester-home-request-new')), findsOneWidget);
        expect(find.byKey(const Key('requester-home-empty')), findsOneWidget);
    });

    testWidgets("a requester's Me tab has no donor-only entries", (tester) async {
        await tester.pumpWidget(_wrap(session: _requesterSession));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dashboard-tab-me')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('me-donor-profile')), findsNothing);
        expect(find.byKey(const Key('me-request-blood')), findsNothing);
        expect(find.byKey(const Key('sign-out')), findsOneWidget);
    });
}
