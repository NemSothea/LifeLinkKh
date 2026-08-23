import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/theme/app_theme.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
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
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

import 'support/auth_fakes.dart';

/// Not a correctness test — a real-device-shaped render of the dashboard with
/// realistic data, captured as PNGs (`--update-goldens`) so the actual pixels can be
/// looked at and critiqued, without depending on a live Google sign-in.
final class _FakeMatchRepository implements MatchRepository {
    _FakeMatchRepository(this.matches);
    final List<Match> matches;
    @override
    Future<Result<List<Match>>> fetchMine() async => Success(matches);
    @override
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) =>
        throw UnimplementedError();
}

final class _FakeRequestRepository implements RequestRepository {
    _FakeRequestRepository(this.requests);
    final List<BloodRequest> requests;
    @override
    Future<Result<List<BloodRequest>>> fetchMine() async => Success(requests);
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
    _FakeDonationRepository(this.donations);
    final List<Donation> donations;
    @override
    Future<Result<List<Donation>>> fetchMine() async => Success(donations);
}

const _requesterSession = AuthSession(
    token: 'jwt-requester',
    user: AuthUser(
        id: 'r1',
        role: UserRole.requester,
        displayName: 'Chea Srey',
        isNewAccount: false,
    ),
);

Widget _wrap({required AuthSession session, required List<Override> overrides}) {
    return ProviderScope(
        overrides: [
            sessionStoreProvider.overrideWithValue(FakeSessionStore(session)),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            ...overrides,
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
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

Future<void> _setPhoneSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
}

BloodRequest _nearbyRequest() => BloodRequest(
    id: 'req-1',
    status: RequestStatus.open,
    patientBloodType: BloodType.oPositive,
    unitsNeeded: 2,
    urgency: Urgency.critical,
    hospitalName: 'Calmette Hospital',
    hospitalDistrictKm: 'ដូនពេញ',
    hospitalDistrictEn: 'Doun Penh',
    alertedCount: 12,
    acceptedCount: 1,
    createdAt: DateTime(2026, 8, 23, 9, 0),
    distanceKm: 2.5,
);

void main() {
    testWidgets('donor Home tab — eligible, one nearby request', (tester) async {
        await _setPhoneSize(tester);
        await tester.pumpWidget(
            _wrap(
                session: testSession(),
                overrides: [
                    donorRepositoryProvider.overrideWithValue(
                        FakeDonorRepository()..profile = testProfile(isEligible: true),
                    ),
                    matchRepositoryProvider.overrideWithValue(
                        _FakeMatchRepository([
                            Match(
                                matchId: 'm1',
                                request: _nearbyRequest(),
                                myBloodType: BloodType.oNegative,
                                notifiedAt: DateTime(2026, 8, 23, 9, 1),
                            ),
                        ]),
                    ),
                    requestRepositoryProvider.overrideWithValue(_FakeRequestRepository([])),
                    donationRepositoryProvider.overrideWithValue(_FakeDonationRepository([])),
                ],
            ),
        );
        // Not pumpAndSettle: the CRITICAL badge on the nearby request pulses forever by
        // design (see UrgencyBadge), which pumpAndSettle waits on indefinitely.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/donor_home.png'),
        );
    });

    testWidgets('donor History tab — one donation', (tester) async {
        await _setPhoneSize(tester);
        await tester.pumpWidget(
            _wrap(
                session: testSession(),
                overrides: [
                    donorRepositoryProvider.overrideWithValue(
                        FakeDonorRepository()..profile = testProfile(isEligible: false),
                    ),
                    matchRepositoryProvider.overrideWithValue(_FakeMatchRepository([])),
                    requestRepositoryProvider.overrideWithValue(_FakeRequestRepository([])),
                    donationRepositoryProvider.overrideWithValue(
                        _FakeDonationRepository([
                            Donation(
                                id: 'd1',
                                donatedOn: DateTime(2026, 6, 14),
                                hospitalName: 'Calmette Hospital',
                                hospitalDistrictEn: 'Doun Penh',
                                bloodRequestId: 'req-0',
                            ),
                        ]),
                    ),
                ],
            ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dashboard-tab-history')));
        await tester.pumpAndSettle();
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/donor_history.png'),
        );
    });

    testWidgets('donor Me tab', (tester) async {
        await _setPhoneSize(tester);
        await tester.pumpWidget(
            _wrap(
                session: testSession(),
                overrides: [
                    donorRepositoryProvider.overrideWithValue(
                        FakeDonorRepository()..profile = testProfile(isEligible: true),
                    ),
                    matchRepositoryProvider.overrideWithValue(_FakeMatchRepository([])),
                    requestRepositoryProvider.overrideWithValue(_FakeRequestRepository([])),
                    donationRepositoryProvider.overrideWithValue(_FakeDonationRepository([])),
                ],
            ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dashboard-tab-me')));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/donor_me.png'));
    });

    testWidgets('requester Home tab — one open request', (tester) async {
        await _setPhoneSize(tester);
        await tester.pumpWidget(
            _wrap(
                session: _requesterSession,
                overrides: [
                    donorRepositoryProvider.overrideWithValue(FakeDonorRepository()),
                    matchRepositoryProvider.overrideWithValue(_FakeMatchRepository([])),
                    requestRepositoryProvider.overrideWithValue(
                        _FakeRequestRepository([_nearbyRequest()]),
                    ),
                    donationRepositoryProvider.overrideWithValue(_FakeDonationRepository([])),
                ],
            ),
        );
        // Not pumpAndSettle — same reason as the donor Home tab above.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/requester_home.png'),
        );
    });
}
