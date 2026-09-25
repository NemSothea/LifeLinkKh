import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donation/presentation/donation_history_screen.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';

import 'support/auth_fakes.dart';

/// The history screen's subject is the 56-day cycle, so the two things a donor came to
/// find out — what their donations added up to, and when they can give again — have to be
/// on it. Before this they were on neither: the screen was a count and a list of dates.
final class _FakeDonationRepository implements DonationRepository {
    _FakeDonationRepository(this.donations);

    final List<Donation> donations;

    @override
    Future<Result<List<Donation>>> fetchMine() async => Success(donations);
}

Donation _donation(int day) => Donation(
    id: 'd$day',
    donatedOn: DateTime(2026, 6, day),
    hospitalName: 'Calmette Hospital',
    hospitalDistrictEn: 'Doun Penh',
    bloodRequestId: 'req-$day',
);

Widget _wrap({
    required List<Donation> donations,
    required bool isEligible,
    FakeDonorRepository? donorRepository,
    DonationRepository? donationRepository,
}) {
    return ProviderScope(
        overrides: [
            sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
            telegramAuthRepositoryProvider.overrideWithValue(FakeTelegramAuthRepository()),
            donorRepositoryProvider.overrideWithValue(
                donorRepository ??
                    (FakeDonorRepository()..profile = testProfile(isEligible: isEligible)),
            ),
            donationRepositoryProvider.overrideWithValue(
                donationRepository ?? _FakeDonationRepository(donations),
            ),
        ],
        child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('km'), Locale('en')],
            home: DonationHistoryScreen(),
        ),
    );
}

void main() {
    testWidgets('three donations state their ceiling, not a count of people helped',
        (tester) async {
        await tester.pumpWidget(
            _wrap(donations: [_donation(1), _donation(2), _donation(3)], isEligible: true),
        );
        await tester.pumpAndSettle();

        // Three units, separated into components, can reach up to nine patients.
        expect(find.byKey(const Key('donation-history-reach')), findsOneWidget);
        expect(find.text('Up to 9 patients reached'), findsOneWidget);
    });

    /// "Up to 0 patients reached" would be a worse first impression than silence.
    testWidgets('a donor with no donations is told nothing about reach', (tester) async {
        await tester.pumpWidget(_wrap(donations: const [], isEligible: true));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('donation-history-reach')), findsNothing);
    });

    testWidgets('an eligible donor is told they can give again now', (tester) async {
        await tester.pumpWidget(_wrap(donations: [_donation(1)], isEligible: true));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('donation-history-cycle')), findsOneWidget);
        expect(find.text('You can donate again now.'), findsOneWidget);
    });

    testWidgets('a donor inside the 56 days gets the date, not just a countdown',
        (tester) async {
        await tester.pumpWidget(_wrap(donations: [_donation(1)], isEligible: false));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('donation-history-cycle')), findsOneWidget);
        expect(find.textContaining('You can donate again on'), findsOneWidget);
    });

    /// The hospital confirms while the donor has History open, and the donor pulls to
    /// refresh. The new donation and the new cooldown have to arrive together.
    testWidgets('pull to refresh updates the cooldown line with the list', (tester) async {
        final donors = FakeDonorRepository()..profile = testProfile(isEligible: true);
        final donations = _MutableDonationRepository();
        await tester.pumpWidget(_wrap(
            donations: const [],
            isEligible: true,
            donorRepository: donors,
            donationRepository: donations,
        ));
        await tester.pumpAndSettle();

        donations.donations = [_donation(1)];
        donors.profile = testProfile(isEligible: false);
        await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
        await tester.pumpAndSettle();

        expect(find.textContaining('You can donate again on'), findsOneWidget);
        expect(find.text('You can donate again now.'), findsNothing);
    });
}

final class _MutableDonationRepository implements DonationRepository {
    List<Donation> donations = const [];

    @override
    Future<Result<List<Donation>>> fetchMine() async => Success(donations);
}
