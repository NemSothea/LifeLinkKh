import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/features/home/data/health_repository.dart';
import 'package:lifelink_kh/features/home/presentation/home_screen.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';

/// Pumps the home screen with the health provider overridden, so no test touches the
/// network or Env.apiBaseUrl.
Widget _wrap({required Locale locale, required Future<String> Function() health}) {
    return ProviderScope(
        // Riverpod 3 retries a failed provider automatically, which flips the state back
        // to loading and makes the error state untestable. Off for tests only.
        retry: (retryCount, error) => null,
        overrides: [healthStatusProvider.overrideWith((ref) => health())],
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
    testWidgets('shows the English app title and the up state', (tester) async {
        await tester.pumpWidget(
            _wrap(
                locale: const Locale('en'),
                health: () async => 'UP',
            ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LifeLink KH'), findsWidgets);
        expect(find.byKey(const Key('health-up')), findsOneWidget);
        expect(find.byKey(const Key('health-down')), findsNothing);
    });

    testWidgets('shows the Khmer app title under the km locale', (tester) async {
        await tester.pumpWidget(
            _wrap(
                locale: const Locale('km'),
                health: () async => 'UP',
            ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ជីវិត — LifeLink KH'), findsWidgets);
    });

    // M2 acceptance: a failing health call is a handled state, not a crash, and the
    // cause never reaches the screen.
    testWidgets('renders the handled error state when the health call fails', (tester) async {
        await tester.pumpWidget(
            _wrap(
                locale: const Locale('en'),
                health: () async => throw Exception('connect failed to 10.0.2.2:8080'),
            ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('health-down')), findsOneWidget);
        expect(find.text('Cannot reach the API'), findsOneWidget);
        expect(find.textContaining('10.0.2.2'), findsNothing);
    });
}
