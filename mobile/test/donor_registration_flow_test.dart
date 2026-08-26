import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/location/location_providers.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/presentation/donor_profile_screen.dart';
import 'package:lifelink_kh/src/features/donor/presentation/donor_setup_screen.dart';

import 'support/auth_fakes.dart';

/// The three-step registration flow and the profile screen, with a fake at the repository seam
/// so the service, the wizard controller and the providers all run for real.
void main() {
    late FakeDonorRepository repository;
    late FakeLocationService locationService;

    setUp(() {
        repository = FakeDonorRepository();
        // Declined by default: every existing test never taps the location button, and a
        // fix must not be assumed just because the fake exists.
        locationService = FakeLocationService();
    });

    Future<void> pump(WidgetTester tester, Widget screen, {Locale locale = const Locale('en')}) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: [
                    donorRepositoryProvider.overrideWithValue(repository),
                    locationServiceProvider.overrideWithValue(locationService),
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
                    home: screen,
                ),
            ),
        );
        await tester.pumpAndSettle();
    }

    group('setup wizard', () {
        testWidgets('all eight blood types are visible at once, and no unknown option',
            (tester) async {
            await pump(tester, const DonorSetupScreen());

            for (final type in ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']) {
                expect(find.byKey(Key('blood-type-$type')), findsOneWidget, reason: type);
            }
            // FR-DONOR-001: a donor who does not know their type is sent to a hospital, because
            // an unknown type has no blood_compatibility row and would never match.
            expect(find.text('Unknown'), findsNothing);
        });

        testWidgets('cannot leave step 1 without a name and a blood type', (tester) async {
            await pump(tester, const DonorSetupScreen());

            final next = find.byKey(const Key('donor-next'));
            expect(tester.widget<FilledButton>(next).onPressed, isNull);

            await tester.enterText(find.byKey(const Key('donor-full-name')), 'Nem Sothea');
            await tester.pump();
            expect(
                tester.widget<FilledButton>(next).onPressed,
                isNull,
                reason: 'a name alone is not enough',
            );

            await tester.tap(find.byKey(const Key('blood-type-O-')));
            await tester.pump();
            expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
        });

        testWidgets('cannot leave step 2 without a district', (tester) async {
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);

            final next = find.byKey(const Key('donor-next'));
            expect(tester.widget<FilledButton>(next).onPressed, isNull);

            await _pickDistrict(tester);
            expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
        });

        testWidgets('the district list comes from the server, in server order', (tester) async {
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);

            await tester.tap(find.byKey(const Key('donor-district')));
            await tester.pumpAndSettle();

            // English locale, so the Latin labels show; the order is the Khmer-alphabetical one
            // the server sent and the client does not re-sort.
            expect(find.text('Chamkar Mon').hitTestable(), findsOneWidget);
            expect(find.text('Tuol Kouk').hitTestable(), findsOneWidget);
            await tester.tap(find.text('Chamkar Mon').last);
            await tester.pumpAndSettle();
        });

        testWidgets('shows the privacy promise on the location step', (tester) async {
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);

            // The user-facing half of ADR 0003.
            expect(
                find.text(
                    'Other people only ever see your district — never your exact location.',
                ),
                findsOneWidget,
            );
        });

        testWidgets('use my current location acquires a fix and saves it as an update',
            (tester) async {
            locationService.fix = (latitude: 11.55, longitude: 104.92);
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);
            await _pickDistrict(tester);

            await tester.tap(find.byKey(const Key('donor-use-current-location')));
            await tester.pumpAndSettle();

            expect(find.text('Location added'), findsOneWidget);
            expect(find.byKey(const Key('donor-location-unavailable')), findsNothing);

            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();

            final saved = repository.saves.single;
            expect(saved.latitude, 11.55);
            expect(saved.longitude, 104.92);
            // CR-MAPI-004: without this the server would leave stored coordinates alone.
            expect(saved.updateCoordinates, isTrue);
        });

        testWidgets('declining location still lets a donor finish setup', (tester) async {
            locationService.fix = null;
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);
            await _pickDistrict(tester);

            await tester.tap(find.byKey(const Key('donor-use-current-location')));
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('donor-location-unavailable')), findsOneWidget);

            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();

            // Declining GPS must never block setup (ADR 0003).
            expect(find.byKey(const Key('donor-saved')), findsOneWidget);
            final saved = repository.saves.single;
            expect(saved.latitude, isNull);
            expect(saved.updateCoordinates, isFalse);
        });

        testWidgets('a first-time donor finishes without entering any date', (tester) async {
            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);
            await _pickDistrict(tester);
            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();

            // Step 3 is skippable by design: the Save button is enabled with no date chosen.
            await tester.tap(find.byKey(const Key('donor-next')));
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('donor-saved')), findsOneWidget);
            expect(repository.saves.single.lastDonationDate, isNull);
            expect(repository.saves.single.districtCode, '1201');
            expect(repository.saves.single.fullName, 'Nem Sothea');
        });

        testWidgets('the result screen shows both the day count and the calendar date',
            (tester) async {
            await pump(tester, const DonorSetupScreen());
            await _completeSetup(tester);

            // FR-DONOR-001 acceptance criterion: a countdown alone cannot be planned around,
            // a date alone hides how close it is.
            expect(find.textContaining('12 days'), findsOneWidget);
            expect(find.textContaining('Aug 30, 2026'), findsOneWidget);
        });

        testWidgets('a refused save keeps the form and shows one error', (tester) async {
            repository.saveFailure = const ValidationFailure(code: 'UNKNOWN_DISTRICT');

            await pump(tester, const DonorSetupScreen());
            await _completeSetup(tester);

            expect(find.byKey(const Key('donor-save-failed')), findsOneWidget);
            expect(
                find.byKey(const Key('donor-saved')),
                findsNothing,
                reason: 'nothing was saved, so nothing is confirmed',
            );
        });

        testWidgets('a failed district load offers a retry instead of an empty dropdown',
            (tester) async {
            repository.districtsFailure = const NetworkFailure();

            await pump(tester, const DonorSetupScreen());
            await _completeIdentityStep(tester);

            expect(find.byKey(const Key('districts-failed')), findsOneWidget);
            expect(find.text('Try again'), findsOneWidget);
        });
    });

    group('profile screen', () {
        testWidgets('no profile yet is a prompt, not an error', (tester) async {
            repository.profile = null;

            await pump(tester, const DonorProfileScreen());

            expect(find.byKey(const Key('donor-start-setup')), findsOneWidget);
            expect(find.byKey(const Key('donor-profile-failed')), findsNothing);
        });

        testWidgets('shows blood type, district and eligibility — never a coordinate',
            (tester) async {
            repository.profile = testProfile();

            await pump(tester, const DonorProfileScreen());

            expect(find.byKey(const Key('donor-blood-type-value')), findsOneWidget);
            expect(find.text('O-'), findsOneWidget);
            expect(find.text('Tuol Kouk'), findsOneWidget);
            expect(find.byKey(const Key('eligibility-card')), findsOneWidget);
            // ADR 0003: no screen shows coordinates, and the read model has none to show.
            expect(find.textContaining('11.5'), findsNothing);
            expect(find.textContaining('104.'), findsNothing);
        });

        testWidgets('the Khmer locale shows the Khmer district label', (tester) async {
            repository.profile = testProfile();

            await pump(tester, const DonorProfileScreen(), locale: const Locale('km'));

            // Both labels arrive together (CR-MAPI-001), so switching locale needs no re-fetch.
            expect(find.text('ទួលគោក'), findsOneWidget);
            expect(find.text('Tuol Kouk'), findsNothing);
        });

        testWidgets('the availability toggle sends the whole profile with one field changed',
            (tester) async {
            repository.profile = testProfile();

            await pump(tester, const DonorProfileScreen());
            await tester.tap(find.byKey(const Key('donor-availability')));
            await tester.pumpAndSettle();

            final sent = repository.saves.single;
            expect(sent.isAvailable, isFalse);
            // PUT replaces the row: sending only isAvailable would blank the rest.
            expect(sent.bloodType?.wireValue, 'O-');
            expect(sent.districtCode, '1204');
            expect(sent.fullName, 'Nem Sothea');
        });

        testWidgets('an eligible donor sees the eligible message with no countdown',
            (tester) async {
            repository.profile = testProfile(isEligible: true);

            await pump(tester, const DonorProfileScreen());

            expect(find.text('You can donate now'), findsOneWidget);
            expect(find.textContaining('days'), findsNothing);
        });

        testWidgets('a failed load offers a retry', (tester) async {
            repository.profileFailure = const NetworkFailure();

            await pump(tester, const DonorProfileScreen());

            expect(find.byKey(const Key('donor-profile-failed')), findsOneWidget);
            expect(find.byKey(const Key('donor-profile-retry')), findsOneWidget);
        });

        testWidgets('a failed save leaves the donor registered', (tester) async {
            repository.profile = testProfile();
            repository.saveFailure = const ServerFailure();

            await pump(tester, const DonorProfileScreen());
            await tester.tap(find.byKey(const Key('donor-availability')));
            await tester.pumpAndSettle();

            // The old profile stays visible under the error. Dropping to "no profile yet" would
            // route a registered donor back into setup because one write failed.
            expect(find.byKey(const Key('donor-blood-type-value')), findsOneWidget);
            expect(find.byKey(const Key('donor-profile-save-failed')), findsOneWidget);
        });
    });
}

Future<void> _completeIdentityStep(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('donor-full-name')), 'Nem Sothea');
    await tester.tap(find.byKey(const Key('blood-type-O-')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('donor-next')));
    await tester.pumpAndSettle();
}

Future<void> _pickDistrict(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('donor-district')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chamkar Mon').last);
    await tester.pumpAndSettle();
}

Future<void> _completeSetup(WidgetTester tester) async {
    await _completeIdentityStep(tester);
    await _pickDistrict(tester);
    await tester.tap(find.byKey(const Key('donor-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('donor-next')));
    await tester.pumpAndSettle();
}
