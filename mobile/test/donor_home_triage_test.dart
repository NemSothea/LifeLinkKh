import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/home/presentation/donor_home_tab.dart';
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

/// The donor Home tab's triage order, answered state, and retry path.
///
/// `GET /matches/me` answers newest-first, which is the wrong order for a screen whose
/// whole job is "what should I do next" — this is the test that says so.
final class _FakeMatchRepository implements MatchRepository {
    _FakeMatchRepository(this.matches, {this.failFirst = false});

    final List<Match> matches;
    bool failFirst;
    int fetchCount = 0;

    @override
    Future<Result<List<Match>>> fetchMine() async {
        fetchCount++;
        if (failFirst) {
            failFirst = false;
            return const Failed(NetworkFailure());
        }
        return Success(matches);
    }

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

BloodRequest _request({
    required String id,
    required Urgency urgency,
    required double? distanceKm,
    required Duration age,
}) => BloodRequest(
    id: id,
    status: RequestStatus.open,
    patientBloodType: BloodType.oPositive,
    unitsNeeded: 1,
    urgency: urgency,
    hospitalName: 'Hospital $id',
    alertedCount: 3,
    acceptedCount: 0,
    createdAt: DateTime.now().subtract(age),
    distanceKm: distanceKm,
);

Match _match({
    required String id,
    required Urgency urgency,
    double? distanceKm,
    Duration age = const Duration(minutes: 10),
    MatchResponseType? response,
}) => Match(
    matchId: id,
    request: _request(id: id, urgency: urgency, distanceKm: distanceKm, age: age),
    myBloodType: BloodType.oNegative,
    notifiedAt: DateTime.now(),
    response: response,
);

Widget _wrap(_FakeMatchRepository matchRepository) {
    return ProviderScope(
        overrides: [
            sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
            telegramAuthRepositoryProvider.overrideWithValue(FakeTelegramAuthRepository()),
            donorRepositoryProvider.overrideWithValue(
                FakeDonorRepository()..profile = testProfile(isEligible: true),
            ),
            matchRepositoryProvider.overrideWithValue(matchRepository),
            requestRepositoryProvider.overrideWithValue(_FakeRequestRepository()),
            donationRepositoryProvider.overrideWithValue(_FakeDonationRepository()),
        ],
        child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('km'), Locale('en')],
            home: DonorHomeTab(),
        ),
    );
}

double _tileTop(WidgetTester tester, String matchId) =>
    tester.getTopLeft(find.byKey(Key('donor-home-match-$matchId'))).dy;

void main() {
    testWidgets('urgency outranks recency — a CRITICAL request sorts above a newer ROUTINE one',
        (tester) async {
        await tester.pumpWidget(
            _wrap(
                _FakeMatchRepository([
                    // Server order: newest first. The ROUTINE one arrives at the top.
                    _match(id: 'routine', urgency: Urgency.routine, age: const Duration(minutes: 2)),
                    _match(id: 'urgent', urgency: Urgency.urgent, age: const Duration(minutes: 30)),
                    _match(
                        id: 'critical',
                        urgency: Urgency.critical,
                        age: const Duration(hours: 1),
                    ),
                ]),
            ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(_tileTop(tester, 'critical'), lessThan(_tileTop(tester, 'urgent')));
        expect(_tileTop(tester, 'urgent'), lessThan(_tileTop(tester, 'routine')));
    });

    testWidgets('at equal urgency the closer request sorts first', (tester) async {
        await tester.pumpWidget(
            _wrap(
                _FakeMatchRepository([
                    _match(id: 'far', urgency: Urgency.critical, distanceKm: 9.5),
                    _match(id: 'near', urgency: Urgency.critical, distanceKm: 1.5),
                ]),
            ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(_tileTop(tester, 'near'), lessThan(_tileTop(tester, 'far')));
    });

    testWidgets('an answered request drops below every unanswered one and says so',
        (tester) async {
        await tester.pumpWidget(
            _wrap(
                _FakeMatchRepository([
                    _match(
                        id: 'answered',
                        urgency: Urgency.critical,
                        response: MatchResponseType.accepted,
                    ),
                    _match(id: 'open', urgency: Urgency.routine),
                ]),
            ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // CRITICAL, and still below a ROUTINE one: answering is what moved it.
        expect(_tileTop(tester, 'open'), lessThan(_tileTop(tester, 'answered')));
        expect(find.text('Accepted'), findsOneWidget);
        expect(find.text('WAITING FOR YOUR ANSWER'), findsOneWidget);
        expect(find.text('ALREADY ANSWERED'), findsOneWidget);
    });

    testWidgets('a request tile shows its age, not a wall-clock timestamp', (tester) async {
        await tester.pumpWidget(
            _wrap(
                _FakeMatchRepository([
                    _match(
                        id: 'aged',
                        urgency: Urgency.urgent,
                        age: const Duration(minutes: 14, seconds: 30),
                    ),
                ]),
            ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('14 minutes ago'), findsOneWidget);
    });

    testWidgets('a failed nearby-requests fetch offers a retry that actually refetches',
        (tester) async {
        final repository = _FakeMatchRepository(
            [_match(id: 'recovered', urgency: Urgency.urgent)],
            failFirst: true,
        );
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('donor-home-matches-failed')), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(repository.fetchCount, 2);
        expect(find.byKey(const Key('donor-home-match-recovered')), findsOneWidget);
        expect(find.byKey(const Key('donor-home-matches-failed')), findsNothing);
    });
}
