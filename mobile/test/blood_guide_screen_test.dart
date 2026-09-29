import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/features/donation/presentation/donation_guide_screen.dart';
import 'package:lifelink_kh/src/features/request/presentation/blood_guide_screen.dart';

Widget _app(Widget home, {String locale = 'en'}) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('km'), Locale('en')],
    home: home,
);

/// DEC-019. The family guide says what the research found families are never told.
void main() {
    testWidgets('the family guide says any blood type can help, and blood is free',
        (tester) async {
        await tester.pumpWidget(_app(const BloodGuideScreen()));
        expect(find.byKey(const Key('blood-guide-any-type')), findsOneWidget);
        expect(find.textContaining('whatever their blood type'), findsOneWidget);
        expect(find.byKey(const Key('blood-guide-free')), findsOneWidget);
        expect(find.textContaining('Never pay anyone for blood'), findsOneWidget);
    });

    testWidgets('the family guide exists in Khmer', (tester) async {
        await tester.pumpWidget(_app(const BloodGuideScreen(), locale: 'km'));
        expect(find.text('ក្រុមឈាមណាក៏អាចជួយបាន'), findsOneWidget);
        expect(find.text('ឈាមមិនគិតថ្លៃ'), findsOneWidget);
    });

    testWidgets('the donor guide lists when to wait and where to donate', (tester) async {
        await tester.pumpWidget(_app(const DonationGuideScreen()));
        await tester.scrollUntilVisible(find.byKey(const Key('donation-guide-where')), 200);
        expect(find.byKey(const Key('donation-guide-wait')), findsOneWidget);
        expect(find.textContaining('45 kg'), findsOneWidget);
        expect(find.textContaining('next to Khmer-Soviet Friendship Hospital'), findsOneWidget);
    });

    /// DEC-019 phase 2: the guide says the interval the app now counts.
    testWidgets('the donor guide says 3 months for men and 4 for women', (tester) async {
        await tester.pumpWidget(_app(const DonationGuideScreen()));
        await tester.scrollUntilVisible(find.textContaining('3 months (90 days) for men'), 200);
        expect(find.textContaining('4 months (120 days) for women'), findsOneWidget);
    });
}
