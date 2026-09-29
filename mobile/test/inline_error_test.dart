import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/widgets/inline_error.dart';
import 'package:lifelink_kh/src/features/match/application/match_providers.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/match/presentation/match_detail_screen.dart';

Widget _app(Widget home) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('km'), Locale('en')],
    home: Scaffold(body: home),
);

final class _SlowMatchRepository implements MatchRepository {
    final Completer<Result<List<Match>>> gate = Completer();

    @override
    Future<Result<List<Match>>> fetchMine() => gate.future;

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) =>
        throw UnimplementedError();
}

void main() {
    testWidgets('an action failure says what failed', (tester) async {
        await tester.pumpWidget(_app(const InlineError(message: 'Could not send.')));
        expect(find.text('Could not send.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('a failure from no signal says so instead', (tester) async {
        await tester.pumpWidget(
            _app(const InlineError(message: 'Could not send.', error: NetworkFailure())),
        );
        expect(find.text('Could not send.'), findsNothing);
        expect(
            find.text('No internet connection. Check your network and try again.'),
            findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('an action failure is announced to screen readers', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(const InlineError(message: 'Could not send.')));
        expect(
            tester.getSemantics(find.byType(InlineError)),
            matchesSemantics(isLiveRegion: true, label: 'Could not send.'),
        );
        handle.dispose();
    });

    /// A tapped notification on a cold start opens this screen before the inbox has
    /// loaded; it used to say "could not load" for that first second.
    testWidgets('match detail waits for the inbox instead of saying it failed', (tester) async {
        final repository = _SlowMatchRepository();
        await tester.pumpWidget(
            ProviderScope(
                overrides: [matchRepositoryProvider.overrideWithValue(repository)],
                child: _app(
                    Consumer(
                        builder: (context, ref, _) {
                            ref.watch(myMatchesControllerProvider);
                            return const MatchDetailScreen(matchId: 'm1');
                        },
                    ),
                ),
            ),
        );
        await tester.pump();

        expect(find.byKey(const Key('match-loading')), findsOneWidget);
        expect(find.byKey(const Key('match-not-found')), findsNothing);

        repository.gate.complete(const Success([]));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('match-not-found')), findsOneWidget);
    });
}
