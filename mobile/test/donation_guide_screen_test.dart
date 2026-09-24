import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/features/donation/presentation/donation_guide_screen.dart';

/// `BRIEF-DONATION-001`. The guide is static, so what is worth pinning is what it must
/// never say: a gift the centre may not hand out, stated as a promise.
Widget _wrap(Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('km'), Locale('en')],
    home: const DonationGuideScreen(),
);

void main() {
    testWidgets('the after-donation section hedges the gift and frames the snack as care',
        (tester) async {
        await tester.pumpWidget(_wrap(const Locale('en')));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
            find.textContaining('Gifts vary by centre'),
            200,
            scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('help your body recover'), findsOneWidget);
        expect(find.textContaining('you will get'), findsNothing);
    });

    testWidgets('the whole guide exists in Khmer, not just its title', (tester) async {
        await tester.pumpWidget(_wrap(const Locale('km')));
        await tester.pumpAndSettle();

        expect(find.text('អ្វីដែលត្រូវរំពឹង'), findsOneWidget);
        expect(find.text('មុនពេលទៅ'), findsOneWidget);
        expect(find.textContaining('Before you go'), findsNothing);
    });
}
