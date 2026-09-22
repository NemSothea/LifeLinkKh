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

/// The public board on the donor's home screen.
///
/// The screen this protects used to be a status banner and blank space: `GET /matches/me`
/// is empty for a donor between emergencies, which is nearly always, and that emptiness
/// was the whole screen — while hospitals had open requests the app never mentioned.
final class _FakeMatchRepository implements MatchRepository {
    _FakeMatchRepository(this.matches);

    final List<Match> matches;

    @override
    Future<Result<List<Match>>> fetchMine() async => Success(matches);

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) => throw UnimplementedError();
}

final class _FakeRequestRepository implements RequestRepository {
    _FakeRequestRepository({this.board = const [], this.failBoard = false});

    final List<BloodRequest> board;
    bool failBoard;
    int boardFetches = 0;

    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() async {
        boardFetches++;
        if (failBoard) {
            failBoard = false;
            return const Failed(NetworkFailure());
        }
        return Success(board);
    }

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
    Duration age = const Duration(minutes: 10),
}) => BloodRequest(
    id: id,
    status: RequestStatus.open,
    patientBloodType: BloodType.oPositive,
    unitsNeeded: 2,
    urgency: urgency,
    hospitalName: 'Hospital $id',
    alertedCount: 4,
    acceptedCount: 0,
    createdAt: DateTime.now().subtract(age),
);

Match _match(BloodRequest request) => Match(
    matchId: 'm-${request.id}',
    request: request,
    myBloodType: BloodType.oNegative,
    notifiedAt: DateTime.now(),
);

Widget _wrap({
    required _FakeRequestRepository requests,
    List<Match> matches = const [],
}) {
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
            matchRepositoryProvider.overrideWithValue(_FakeMatchRepository(matches)),
            requestRepositoryProvider.overrideWithValue(requests),
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

Future<void> _settle(WidgetTester tester) async {
    // Not pumpAndSettle: a CRITICAL badge pulses forever by design (UrgencyBadge).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
}

void main() {
    testWidgets('an empty alert inbox still shows who needs blood', (tester) async {
        await tester.pumpWidget(
            _wrap(
                requests: _FakeRequestRepository(
                    board: [
                        _request(id: 'calmette', urgency: Urgency.critical),
                        _request(id: 'kossamak', urgency: Urgency.routine),
                    ],
                ),
            ),
        );
        await _settle(tester);

        // The inbox is empty and says so...
        expect(find.byKey(const Key('donor-home-matches-empty')), findsOneWidget);
        // ...and the screen is no longer empty because of it.
        expect(find.byKey(const Key('donor-home-board-calmette')), findsOneWidget);
        expect(find.byKey(const Key('donor-home-board-kossamak')), findsOneWidget);
    });

    /// One request must not appear twice under two different headings — once as an alert
    /// with accept/decline on it, and again as an anonymous board row.
    testWidgets('a request this donor was alerted to is not repeated on the board',
        (tester) async {
        final alerted = _request(id: 'calmette', urgency: Urgency.critical);

        await tester.pumpWidget(
            _wrap(
                matches: [_match(alerted)],
                requests: _FakeRequestRepository(
                    board: [alerted, _request(id: 'kossamak', urgency: Urgency.urgent)],
                ),
            ),
        );
        await _settle(tester);

        expect(find.byKey(const Key('donor-home-match-m-calmette')), findsOneWidget);
        expect(find.byKey(const Key('donor-home-board-calmette')), findsNothing);
        expect(find.byKey(const Key('donor-home-board-kossamak')), findsOneWidget);
    });

    testWidgets('the board sorts CRITICAL above a newer ROUTINE request', (tester) async {
        await tester.pumpWidget(
            _wrap(
                requests: _FakeRequestRepository(
                    board: [
                        // Server order is newest-first, which buries the emergency.
                        _request(id: 'routine', urgency: Urgency.routine, age: const Duration(minutes: 1)),
                        _request(id: 'critical', urgency: Urgency.critical, age: const Duration(hours: 2)),
                    ],
                ),
            ),
        );
        await _settle(tester);

        final critical = tester.getTopLeft(find.byKey(const Key('donor-home-board-critical')));
        final routine = tester.getTopLeft(find.byKey(const Key('donor-home-board-routine')));
        expect(critical.dy, lessThan(routine.dy));
    });

    testWidgets('a failed board is retryable and does not take the rest of the screen with it',
        (tester) async {
        final repository = _FakeRequestRepository(
            board: [_request(id: 'calmette', urgency: Urgency.urgent)],
            failBoard: true,
        );

        await tester.pumpWidget(_wrap(requests: repository));
        await _settle(tester);

        expect(find.byKey(const Key('donor-home-board-failed')), findsOneWidget);
        // The eligibility card above it is unaffected — one failed call is not a failed screen.
        expect(find.byType(DonorHomeTab), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await _settle(tester);

        expect(find.byKey(const Key('donor-home-board-calmette')), findsOneWidget);
        expect(repository.boardFetches, 2);
    });

    testWidgets('an empty board says so rather than showing a bare heading', (tester) async {
        await tester.pumpWidget(_wrap(requests: _FakeRequestRepository()));
        await _settle(tester);

        expect(find.byKey(const Key('donor-home-board-empty')), findsOneWidget);
    });

    /// The empty inbox used to be a full-height card with a tick in it. Above a populated
    /// board that is two answers to the same question, and the taller one is the answer
    /// nobody needs.
    testWidgets('the empty inbox shrinks to one line when the board has requests',
        (tester) async {
        await tester.pumpWidget(
            _wrap(
                requests: _FakeRequestRepository(
                    board: [_request(id: 'calmette', urgency: Urgency.critical)],
                ),
            ),
        );
        await _settle(tester);

        expect(find.byKey(const Key('donor-home-matches-empty')), findsOneWidget);
        expect(
            find.ancestor(
                of: find.byKey(const Key('donor-home-matches-empty')),
                matching: find.byType(Card),
            ),
            findsNothing,
        );
    });

    testWidgets('with nothing below it, the empty inbox stays a card', (tester) async {
        await tester.pumpWidget(_wrap(requests: _FakeRequestRepository()));
        await _settle(tester);

        expect(tester.widget(find.byKey(const Key('donor-home-matches-empty'))), isA<Card>());
    });
}
