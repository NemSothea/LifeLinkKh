import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/request/application/request_providers.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_repository.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';
import 'package:lifelink_kh/src/features/request/presentation/request_detail_screen.dart';

/// DEC-015, requester side: a request under admin review must not look like a request
/// nobody answered, and a refused one must say why.
final class _OneRequestRepository implements RequestRepository {
    _OneRequestRepository(this.request);

    final BloodRequest request;

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) async => Success(request);

    @override
    Future<Result<List<BloodRequest>>> fetchMine() async => Success([request]);

    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() async => const Success([]);

    @override
    Future<Result<List<Hospital>>> fetchHospitals() => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) => throw UnimplementedError();

    @override
    Future<Result<BloodRequest>> cancel(String requestId) => throw UnimplementedError();
}

BloodRequest _request(RequestStatus status, {String? rejectReason}) => BloodRequest(
    id: 'req-1',
    status: status,
    patientBloodType: BloodType.oNegative,
    unitsNeeded: 2,
    urgency: Urgency.critical,
    hospitalName: 'Calmette Hospital',
    alertedCount: 0,
    acceptedCount: 0,
    createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    rejectReason: rejectReason,
);

void main() {
    Future<void> pump(WidgetTester tester, BloodRequest request, {Locale locale = const Locale('en')}) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    requestRepositoryProvider.overrideWithValue(_OneRequestRepository(request)),
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
                    home: const RequestDetailScreen(requestId: 'req-1'),
                ),
            ),
        );
        // Not pumpAndSettle: a critical UrgencyBadge pulses forever, so it never settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('pending explains the review instead of showing "0 donors alerted"',
        (tester) async {
        await pump(tester, _request(RequestStatus.pending));

        expect(find.byKey(const Key('request-pending')), findsOneWidget);
        expect(find.text('Waiting for review'), findsOneWidget);
        expect(find.textContaining('An admin checks every request'), findsOneWidget);
        expect(find.byKey(const Key('request-alerted-count')), findsNothing);
        expect(find.text('Waiting for the first donor to accept'), findsNothing);
    });

    testWidgets('pending can still be cancelled', (tester) async {
        await pump(tester, _request(RequestStatus.pending));
        expect(find.byKey(const Key('request-cancel')), findsOneWidget);
    });

    testWidgets('rejected shows "Not approved" and the admin\'s reason, and no cancel',
        (tester) async {
        await pump(
            tester,
            _request(RequestStatus.rejected, rejectReason: 'The hospital could not confirm this patient.'),
        );

        expect(find.text('Not approved'), findsOneWidget);
        expect(find.text('This request was not approved'), findsOneWidget);
        expect(
            find.text('The hospital could not confirm this patient.'),
            findsOneWidget,
        );
        expect(find.byKey(const Key('request-cancel')), findsNothing);
        expect(find.byKey(const Key('request-alerted-count')), findsNothing);
    });

    testWidgets('rejected without a reason says so rather than showing a blank', (tester) async {
        await pump(tester, _request(RequestStatus.rejected));
        expect(find.text('No reason was given.'), findsOneWidget);
    });

    testWidgets('open still shows the counts and the cancel button', (tester) async {
        await pump(tester, _request(RequestStatus.open));
        expect(find.byKey(const Key('request-alerted-count')), findsOneWidget);
        expect(find.byKey(const Key('request-pending')), findsNothing);
        expect(find.byKey(const Key('request-cancel')), findsOneWidget);
    });

    testWidgets('the pending state exists in Khmer', (tester) async {
        await pump(tester, _request(RequestStatus.pending), locale: const Locale('km'));
        expect(find.text('កំពុងរង់ចាំការពិនិត្យ'), findsOneWidget);
        expect(find.text('Waiting for review'), findsNothing);
    });
}
