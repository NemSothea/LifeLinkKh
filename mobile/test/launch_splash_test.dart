import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/theme/app_theme.dart';
import 'package:lifelink_kh/src/core/widgets/brand_badge.dart';
import 'package:lifelink_kh/src/core/widgets/launch_splash.dart';

/// The cold start's in-Flutter splash: the native launch screen's badge, in the same
/// place, plus the spinner the still picture could not show.
void main() {
    testWidgets('the badge stays dead centre, with a spinner under it', (tester) async {
        await tester.pumpWidget(
            MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('km'), Locale('en')],
                locale: const Locale('en'),
                home: const LaunchSplash(),
            ),
        );

        final screen = tester.getCenter(find.byType(Scaffold));
        final badge = tester.getCenter(find.byType(BrandBadge));
        expect(badge, screen);

        final spinner = tester.getCenter(find.byType(CircularProgressIndicator));
        expect(spinner.dx, badge.dx);
        expect(spinner.dy, greaterThan(badge.dy + BrandBadge.size / 2));
        // Android 12+ draws its own 160 dp icon; the hand-off must not shrink it. (Tests
        // run as Android.) Corners, not getSize: they include the scale.
        final drawn = tester.getBottomRight(find.byType(BrandBadge)) -
            tester.getTopLeft(find.byType(BrandBadge));
        expect(drawn.dx, LaunchSplash.badgeDiameter(TargetPlatform.android));
        expect(spinner.dy, greaterThan(badge.dy + drawn.dx / 2));
        expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    });
}
