import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/settings/locale_controller.dart';
import 'package:lifelink_kh/src/core/settings/locale_store.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_controller.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_store.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/home/application/health_providers.dart';
import 'package:lifelink_kh/src/features/match/application/match_providers.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';
import 'package:lifelink_kh/src/features/notify/domain/push_arrival.dart';
import 'package:lifelink_kh/src/features/request/application/request_providers.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_repository.dart';
import 'package:lifelink_kh/src/features/request/presentation/request_detail_screen.dart';
import 'package:lifelink_kh/src/router/app_router.dart';

import 'support/auth_fakes.dart';

/// FR-NOTIFY-003, client half: a push that lands while the app is open refreshes what
/// it made stale, and an acceptance says so on screen — Android shows no system
/// notification for a foreground app.
final class _CountingMatchRepository implements MatchRepository {
    int fetches = 0;

    @override
    Future<Result<List<Match>>> fetchMine() async {
        fetches++;
        return const Success([]);
    }

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) =>
        throw UnimplementedError();
}

final class _CountingRequestRepository implements RequestRepository {
    int fetches = 0;

    @override
    Future<Result<List<BloodRequest>>> fetchMine() async {
        fetches++;
        return const Success([]);
    }

    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() async => const Success([]);

    @override
    Future<Result<List<Hospital>>> fetchHospitals() => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) =>
        Completer<Result<BloodRequest>>().future;

    @override
    Future<Result<BloodRequest>> cancel(String requestId) => throw UnimplementedError();
}

void main() {
    late StreamController<PushArrival> pushes;
    late _CountingMatchRepository matches;
    late _CountingRequestRepository requests;

    setUp(() {
        pushes = StreamController<PushArrival>.broadcast();
        matches = _CountingMatchRepository();
        requests = _CountingRequestRepository();
    });

    tearDown(() => pushes.close());

    Future<void> pumpApp(WidgetTester tester) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    localeStoreProvider.overrideWithValue(
                        InMemoryLocaleStore(const Locale('en')),
                    ),
                    onboardingStoreProvider.overrideWithValue(InMemoryOnboardingStore()),
                    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                    sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
                    googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                    facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                    telegramAuthRepositoryProvider.overrideWithValue(
                        FakeTelegramAuthRepository(),
                    ),
                    healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
                    donorRepositoryProvider.overrideWithValue(FakeDonorRepository()),
                    matchRepositoryProvider.overrideWithValue(matches),
                    requestRepositoryProvider.overrideWithValue(requests),
                    pushArrivalsProvider.overrideWith((ref) => pushes.stream),
                ],
                child: const LifeLinkApp(),
            ),
        );
        await tester.pumpAndSettle();
    }

    testWidgets('an acceptance refetches the requester\'s requests and says so',
        (tester) async {
        await pumpApp(tester);
        final requestsBefore = requests.fetches;

        pushes.add(PushArrival(PushArrival.donorAccepted, requestId: 'req-1'));
        await tester.pump();
        await tester.pump();

        expect(requests.fetches, greaterThan(requestsBefore));
        expect(find.text('A donor accepted your request.'), findsOneWidget);
        expect(find.text('View'), findsOneWidget);
    });

    testWidgets('a second acceptance is not swallowed as unchanged', (tester) async {
        await pumpApp(tester);

        pushes.add(PushArrival(PushArrival.donorAccepted, requestId: 'req-1'));
        await tester.pump();
        await tester.pump();
        final afterFirst = requests.fetches;

        pushes.add(PushArrival(PushArrival.donorAccepted, requestId: 'req-1'));
        await tester.pump();
        await tester.pump();

        expect(requests.fetches, greaterThan(afterFirst));
    });

    testWidgets('a donor alert refetches the inbox without the acceptance notice',
        (tester) async {
        await pumpApp(tester);
        final matchesBefore = matches.fetches;

        pushes.add(PushArrival('REQUEST_ALERT', requestId: 'req-2'));
        await tester.pump();
        await tester.pump();

        expect(matches.fetches, greaterThan(matchesBefore));
        expect(find.text('A donor accepted your request.'), findsNothing);
    });

    testWidgets('a donor alert that lands while the app is open says so', (tester) async {
        await pumpApp(tester);

        pushes.add(
            PushArrival(PushArrival.requestAlert, requestId: 'req-2', foreground: true),
        );
        await tester.pump();
        await tester.pump();

        expect(
            find.text('Urgent blood request near you — you are a match.'),
            findsOneWidget,
        );
        expect(find.text('View'), findsOneWidget);
    });

    testWidgets('a donor alert tapped from the tray raises no second notice',
        (tester) async {
        await pumpApp(tester);

        pushes.add(PushArrival(PushArrival.requestAlert, requestId: 'req-2'));
        await tester.pump();
        await tester.pump();

        expect(
            find.text('Urgent blood request near you — you are a match.'),
            findsNothing,
        );
    });

    testWidgets('"View" on the request already on screen does not stack a second copy',
        (tester) async {
        await pumpApp(tester);
        final router = ProviderScope.containerOf(tester.element(find.byType(LifeLinkApp)))
            .read(appRouterProvider);
        unawaited(router.push(RequestDetailScreen.routeFor('req-1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        pushes.add(PushArrival(PushArrival.donorAccepted, requestId: 'req-1'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('View'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
            find.byType(RequestDetailScreen, skipOffstage: false),
            findsOneWidget,
        );
    });
}
