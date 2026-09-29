import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/theme/app_theme.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/application/match_providers.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/match/presentation/match_detail_screen.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

/// Accept and decline ask once more before anything is sent: an accidental accept is
/// a promise to a family that nobody made.
final class _FakeMatchRepository implements MatchRepository {
    final List<MatchResponseType> responses = [];

    @override
    Future<Result<List<Match>>> fetchMine() async => Success([
        Match(
            matchId: 'm1',
            request: BloodRequest(
                id: 'req-1',
                status: RequestStatus.open,
                patientBloodType: BloodType.aPositive,
                unitsNeeded: 1,
                // Not CRITICAL: that badge pulses forever and pumpAndSettle would hang.
                urgency: Urgency.urgent,
                hospitalName: 'Calmette Hospital',
                alertedCount: 3,
                acceptedCount: 0,
                createdAt: DateTime.now().subtract(const Duration(minutes: 14)),
                distanceKm: 2.5,
            ),
            myBloodType: BloodType.oNegative,
            notifiedAt: DateTime.now(),
        ),
    ]);

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) async {
        responses.add(response);
        return Success(
            RespondResult(matchId: matchId, response: response, respondedAt: DateTime.now()),
        );
    }
}

Widget _wrap(_FakeMatchRepository repository) => ProviderScope(
    overrides: [matchRepositoryProvider.overrideWithValue(repository)],
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
        home: Consumer(
            builder: (context, ref, _) {
                // The screen reads the already-loaded inbox; load it first.
                ref.watch(myMatchesControllerProvider);
                return const MatchDetailScreen(matchId: 'm1');
            },
        ),
    ),
);

void main() {
    testWidgets('accept opens a confirm sheet and sends only on confirm', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('match-accept')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-accept-confirm')), findsOneWidget);
        expect(repository.responses, isEmpty);

        await tester.tap(find.byKey(const Key('match-accept-confirm')));
        await tester.pumpAndSettle();
        expect(repository.responses, [MatchResponseType.accepted]);
        expect(find.byKey(const Key('match-accepted')), findsOneWidget);
    });

    testWidgets('cancelling the sheet sends nothing', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('match-decline')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-decline-confirm')), findsOneWidget);

        await tester.tap(find.byKey(const Key('match-respond-cancel')));
        await tester.pumpAndSettle();
        expect(repository.responses, isEmpty);
        expect(find.byKey(const Key('match-decline')), findsOneWidget);
    });

    testWidgets('decline confirmed is sent as a decline', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('match-decline')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('match-decline-confirm')));
        await tester.pumpAndSettle();
        expect(repository.responses, [MatchResponseType.declined]);
        expect(find.byKey(const Key('match-declined')), findsOneWidget);
    });

    /// DEC-019: the donor sees the request was checked, and is told never to pay or be paid,
    /// before answering and again once the family's number is on screen.
    testWidgets('a donor sees the admin check and the money warning', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-reviewed')), findsOneWidget);
        expect(find.text('Checked by a LifeLink admin'), findsOneWidget);
        expect(find.byKey(const Key('match-money-notice')), findsOneWidget);
    });

    /// DEC-019: the self-check warns, and never stops a donor from accepting.
    testWidgets('ticking a self-check line warns but accept still works', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('match-accept')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-self-check')), findsOneWidget);
        expect(find.byKey(const Key('match-self-check-warning')), findsNothing);

        await tester.tap(find.byKey(const Key('match-self-check-1')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-self-check-warning')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('match-accept-confirm')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('match-accept-confirm')));
        await tester.pumpAndSettle();
        expect(repository.responses, [MatchResponseType.accepted]);
    });

    testWidgets('declining asks no health questions', (tester) async {
        final repository = _FakeMatchRepository();
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('match-decline')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-self-check')), findsNothing);
    });
}
