import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/network/connectivity_providers.dart';
import 'package:lifelink_kh/src/core/widgets/offline_banner.dart';
import 'package:lifelink_kh/src/core/widgets/retryable_failure.dart';

/// What a donor sees with no network: a strip that says so above every screen, and
/// "no connection" in place of a section's "could not load" when that was the cause.
Widget _wrap(Widget home, {Stream<bool>? offline}) => ProviderScope(
    overrides: [
        if (offline != null) isOfflineProvider.overrideWith((ref) => offline),
    ],
    child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('km'), Locale('en')],
        builder: (context, child) => OfflineBanner(child: child!),
        home: home,
    ),
);

class _Counter extends StatefulWidget {
    const _Counter();

    @override
    State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
    int taps = 0;

    @override
    Widget build(BuildContext context) => Scaffold(
        body: TextButton(
            onPressed: () => setState(() => taps++),
            child: Text('taps $taps'),
        ),
    );
}

void main() {
    group('OfflineBanner', () {
        testWidgets('shows while the phone has no network, hides when it is back',
            (tester) async {
            final offline = StreamController<bool>();
            addTearDown(offline.close);
            await tester.pumpWidget(_wrap(const _Counter(), offline: offline.stream));

            offline.add(true);
            await tester.pump();
            expect(find.byKey(const Key('offline-banner')), findsOneWidget);
            expect(find.textContaining('No internet connection'), findsOneWidget);

            offline.add(false);
            await tester.pump();
            await tester.pump();
            expect(find.byKey(const Key('offline-banner')), findsNothing);
        });

        testWidgets('the screen under it keeps its state across the switch', (tester) async {
            final offline = StreamController<bool>();
            addTearDown(offline.close);
            await tester.pumpWidget(_wrap(const _Counter(), offline: offline.stream));

            await tester.tap(find.text('taps 0'));
            await tester.pump();
            offline.add(true);
            await tester.pump();
            offline.add(false);
            await tester.pump();

            expect(find.text('taps 1'), findsOneWidget,
                reason: 'the banner must not re-parent the router and drop the back stack');
        });

        testWidgets('reads as online when the connectivity plugin is missing', (tester) async {
            await tester.pumpWidget(_wrap(const _Counter()));
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('offline-banner')), findsNothing);
        });
    });

    group('RetryableFailure', () {
        Widget section(Object? error) => _wrap(
            Scaffold(
                body: RetryableFailure(
                    message: 'Could not load your requests.',
                    error: error,
                    onRetry: () {},
                ),
            ),
            offline: Stream.value(false),
        );

        testWidgets('a network failure says "no connection", not "could not load"',
            (tester) async {
            await tester.pumpWidget(section(const NetworkFailure()));
            await tester.pump();

            expect(find.textContaining('No internet connection'), findsOneWidget);
            expect(find.text('Could not load your requests.'), findsNothing);
            expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        });

        testWidgets('any other failure keeps the section\'s own message', (tester) async {
            await tester.pumpWidget(section(const ServerFailure()));
            await tester.pump();

            expect(find.text('Could not load your requests.'), findsOneWidget);
            expect(find.byIcon(Icons.cloud_off), findsOneWidget);
        });
    });
}
