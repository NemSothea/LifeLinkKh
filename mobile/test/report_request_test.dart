import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/report/application/report_providers.dart';
import 'package:lifelink_kh/src/features/report/data/firestore_report_repository.dart';
import 'package:lifelink_kh/src/features/report/domain/report_reason.dart';
import 'package:lifelink_kh/src/features/report/domain/report_repository.dart';
import 'package:lifelink_kh/src/features/report/presentation/report_request_sheet.dart';

/// DEC-019: a donor flags a request to the admin.
final class _FakeReports implements ReportRepository {
    _FakeReports({this.fail});
    final Failure? fail;
    final List<(String, ReportReason, String?)> sent = [];

    @override
    Future<Result<void>> report({
        required String requestId,
        required ReportReason reason,
        String? note,
    }) async {
        if (fail != null) return Failed(fail!);
        sent.add((requestId, reason, note));
        return const Success(null);
    }
}

Widget _app(ReportRepository reports, void Function(bool?) onResult) => ProviderScope(
    overrides: [reportRepositoryProvider.overrideWithValue(reports)],
    child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('km'), Locale('en')],
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    key: const Key('open'),
                    onPressed: () async =>
                        onResult(await showReportRequestSheet(context, requestId: 'r1')),
                    child: const Text('open'),
                ),
            ),
        ),
    ),
);

void main() {
    group('FirestoreReportRepository', () {
        test('writes reports/{requestId}_{uid} in the shape the rules accept', () async {
            final db = FakeFirebaseFirestore();
            final repository = FirestoreReportRepository(db, () => 'd1');
            final result = await repository.report(
                requestId: 'r1',
                reason: ReportReason.money,
                note: '  Asked me for \$50  ',
            );
            expect(result, isA<Success<void>>());
            final stored = (await db.doc('reports/r1_d1').get()).data()!;
            expect(stored['requestId'], 'r1');
            expect(stored['reporterUid'], 'd1');
            expect(stored['reason'], 'MONEY');
            expect(stored['note'], r'Asked me for $50');
            expect(stored.keys.toSet(), {'requestId', 'reporterUid', 'reason', 'note', 'createdAt'});
        });

        test('an empty note is stored as null', () async {
            final db = FakeFirebaseFirestore();
            await FirestoreReportRepository(db, () => 'd1')
                .report(requestId: 'r1', reason: ReportReason.fake, note: '   ');
            expect((await db.doc('reports/r1_d1').get()).data()!['note'], isNull);
        });

        test('signed out is refused before anything is written', () async {
            final db = FakeFirebaseFirestore();
            final result = await FirestoreReportRepository(db, () => null)
                .report(requestId: 'r1', reason: ReportReason.other);
            expect((result as Failed<void>).failure, isA<UnauthorizedFailure>());
        });
    });

    group('report sheet', () {
        testWidgets('send stays disabled until a reason is picked, then sends it', (tester) async {
            final reports = _FakeReports();
            bool? result;
            await tester.pumpWidget(_app(reports, (r) => result = r));
            await tester.tap(find.byKey(const Key('open')));
            await tester.pumpAndSettle();

            final send = find.byKey(const Key('report-send'));
            expect(tester.widget<FilledButton>(send).onPressed, isNull);

            await tester.tap(find.byKey(const Key('report-reason-MONEY')));
            await tester.enterText(find.byKey(const Key('report-note')), 'Asked for money');
            await tester.pumpAndSettle();
            await tester.tap(send);
            await tester.pumpAndSettle();

            expect(reports.sent, [('r1', ReportReason.money, 'Asked for money')]);
            expect(result, isTrue);
        });

        testWidgets('a second report says it was already sent', (tester) async {
            final reports = _FakeReports(fail: const ForbiddenFailure(code: 'PERMISSION_DENIED'));
            await tester.pumpWidget(_app(reports, (_) {}));
            await tester.tap(find.byKey(const Key('open')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('report-reason-FAKE')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('report-send')));
            await tester.pumpAndSettle();
            expect(find.text('You have already reported this request.'), findsOneWidget);
            expect(find.byKey(const Key('report-sheet')), findsOneWidget);
        });
    });
}
