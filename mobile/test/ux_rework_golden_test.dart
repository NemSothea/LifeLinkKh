@Tags(['golden'])
// Goldens for the screens reworked in the UI polish pass, in light and dark, English and
// Khmer, plus Khmer at 1.3x text scale — the case most likely to overflow. A macOS
// review tool, not a CI gate: CI runs `flutter test --exclude-tags golden` (see the note
// at the top of ux_snapshot_test.dart). Any RenderFlex overflow fails the test outright,
// which is the real check for the 1.3x variant. Regenerate with
// `flutter test --update-goldens test/ux_rework_golden_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_controller.dart';
import 'package:lifelink_kh/src/core/settings/onboarding_store.dart';
import 'package:lifelink_kh/src/core/theme/app_theme.dart';
import 'package:lifelink_kh/src/core/widgets/inline_error.dart';
import 'package:lifelink_kh/src/core/widgets/retryable_failure.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/presentation/sign_in_screen.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_providers.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/home/presentation/home_screen.dart';
import 'package:lifelink_kh/src/features/match/application/match_providers.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/match/presentation/match_detail_screen.dart';
import 'package:lifelink_kh/src/features/onboarding/presentation/intro_screen.dart';
import 'package:lifelink_kh/src/features/request/application/request_providers.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_repository.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';
import 'package:lifelink_kh/src/features/request/presentation/blood_guide_screen.dart';

import 'support/auth_fakes.dart';

typedef _Variant = ({String name, Brightness brightness, String locale, double textScale});

const List<_Variant> _variants = [
    (name: 'light_en', brightness: Brightness.light, locale: 'en', textScale: 1.0),
    (name: 'dark_en', brightness: Brightness.dark, locale: 'en', textScale: 1.0),
    (name: 'light_km', brightness: Brightness.light, locale: 'km', textScale: 1.0),
    (name: 'dark_km', brightness: Brightness.dark, locale: 'km', textScale: 1.0),
    (name: 'light_km_scale130', brightness: Brightness.light, locale: 'km', textScale: 1.3),
];

BloodRequest _request() => BloodRequest(
    id: 'req-1',
    status: RequestStatus.open,
    patientBloodType: BloodType.oPositive,
    unitsNeeded: 2,
    urgency: Urgency.critical,
    hospitalName: 'Calmette Hospital',
    hospitalDistrictKm: 'ដូនពេញ',
    hospitalDistrictEn: 'Doun Penh',
    alertedCount: 12,
    acceptedCount: 1,
    // Relative to now: these screens render the request's age, not a date.
    createdAt: DateTime.now().subtract(const Duration(minutes: 14, seconds: 30)),
    distanceKm: 2.5,
);

Match _match() => Match(
    matchId: 'm1',
    request: _request(),
    myBloodType: BloodType.oNegative,
    notifiedAt: DateTime.now(),
);

final class _FakeMatchRepository implements MatchRepository {
    @override
    Future<Result<List<Match>>> fetchMine() async => Success([_match()]);
    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) =>
        throw UnimplementedError();
}

final class _FakeRequestRepository implements RequestRepository {
    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() async => const Success([]);
    @override
    Future<Result<List<BloodRequest>>> fetchMine() async => const Success([]);
    @override
    Future<Result<List<Hospital>>> fetchHospitals() => throw UnimplementedError();
    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) => throw UnimplementedError();
    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) => throw UnimplementedError();
    @override
    Future<Result<BloodRequest>> cancel(String requestId) => throw UnimplementedError();
}

final class _FakeDonationRepository implements DonationRepository {
    @override
    Future<Result<List<Donation>>> fetchMine() async => const Success([]);
}

Future<void> _pumpScreen(
    WidgetTester tester,
    _Variant variant, {
    required Widget home,
    bool signedIn = true,
}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        ProviderScope(
            overrides: [
                sessionStoreProvider.overrideWithValue(
                    FakeSessionStore(signedIn ? testSession() : null),
                ),
                authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
                onboardingStoreProvider.overrideWithValue(InMemoryOnboardingStore(seen: false)),
                donorRepositoryProvider.overrideWithValue(
                    FakeDonorRepository()..profile = testProfile(isEligible: true),
                ),
                matchRepositoryProvider.overrideWithValue(_FakeMatchRepository()),
                requestRepositoryProvider.overrideWithValue(_FakeRequestRepository()),
                donationRepositoryProvider.overrideWithValue(_FakeDonationRepository()),
            ],
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: variant.brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
                locale: Locale(variant.locale),
                localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('km'), Locale('en')],
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(variant.textScale),
                    ),
                    child: child!,
                ),
                home: home,
            ),
        ),
    );
    // Not pumpAndSettle: the CRITICAL badge pulses forever by design. 700ms is past
    // Home's staggered fade-in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
}

/// The match detail screen reads the already-loaded inbox, so load it first.
Widget _matchDetail() => Consumer(
    builder: (context, ref, _) {
        ref.watch(myMatchesControllerProvider);
        return const MatchDetailScreen(matchId: 'm1');
    },
);

Future<void> _expectGolden(String screen, _Variant variant) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/rework/${screen}_${variant.name}.png'),
);

void main() {
    for (final variant in _variants) {
        testWidgets('sign-in — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: const SignInScreen(), signedIn: false);
            await _expectGolden('sign_in', variant);
        });

        testWidgets('intro — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: const IntroScreen(), signedIn: false);
            await _expectGolden('intro', variant);
        });

        testWidgets('home — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: const HomeScreen());
            await _expectGolden('home', variant);
        });

        testWidgets('match detail — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: _matchDetail());
            await _expectGolden('match_detail', variant);
        });

        testWidgets('family blood guide — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: const BloodGuideScreen(), signedIn: false);
            await _expectGolden('blood_guide', variant);
        });

        testWidgets('error states — ${variant.name}', (tester) async {
            await _pumpScreen(
                tester,
                variant,
                home: Builder(
                    builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Scaffold(
                            body: ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                    InlineError(message: l10n.requestCreateFailed),
                                    const SizedBox(height: 16),
                                    InlineError(
                                        message: l10n.requestCreateFailed,
                                        error: const NetworkFailure(),
                                    ),
                                    const SizedBox(height: 24),
                                    RetryableFailure(
                                        message: l10n.homeBoardFailed,
                                        onRetry: () {},
                                    ),
                                    const SizedBox(height: 16),
                                    RetryableFailure(
                                        message: l10n.homeBoardFailed,
                                        onRetry: () {},
                                        isRetrying: true,
                                    ),
                                ],
                            ),
                        );
                    },
                ),
                signedIn: false,
            );
            await _expectGolden('error_states', variant);
        });

        testWidgets('accept confirm sheet — ${variant.name}', (tester) async {
            await _pumpScreen(tester, variant, home: _matchDetail());
            await tester.ensureVisible(find.byKey(const Key('match-accept')));
            await tester.pump();
            await tester.tap(find.byKey(const Key('match-accept')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            await _expectGolden('match_accept_sheet', variant);
        });
    }
}
