import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/app.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/links/link_opener.dart';
import 'package:lifelink_kh/src/core/links/link_providers.dart';
import 'package:lifelink_kh/src/core/settings/locale_controller.dart';
import 'package:lifelink_kh/src/core/settings/locale_store.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/home/presentation/me_tab.dart';
import 'package:lifelink_kh/src/features/notify/application/push_providers.dart';
import 'package:lifelink_kh/src/features/update/application/app_update_providers.dart';
import 'package:lifelink_kh/src/features/update/domain/app_config.dart';
import 'package:lifelink_kh/src/features/update/domain/app_config_repository.dart';
import 'package:lifelink_kh/src/features/update/domain/installed_version.dart';
import 'package:lifelink_kh/src/features/update/domain/update_dismissal_store.dart';
import 'package:lifelink_kh/src/features/update/presentation/update_gate.dart';

import 'support/auth_fakes.dart';

/// The update notice as a donor meets it: over every screen, blocking only when the
/// build is below `minVersionCode`, and the Me tab's privacy link only when the config
/// names one.
final Uri _download = Uri.parse('https://lifelink.example/km/download');
final Uri _privacy = Uri.parse('https://lifelink.example/km/privacy');

final class _FakeAppConfigRepository implements AppConfigRepository {
    const _FakeAppConfigRepository(this.config);

    final AppConfig config;

    @override
    Future<Result<AppConfig>> fetch() async => Success(config);
}

final class _FakeInstalledVersion implements InstalledVersion {
    const _FakeInstalledVersion(this.build);

    final int build;

    @override
    Future<int?> buildNumber() async => build;
}

final class _RecordingLinkOpener implements LinkOpener {
    _RecordingLinkOpener({this.succeeds = true});

    final bool succeeds;
    final List<Uri> opened = [];

    @override
    Future<bool> open(Uri uri) async {
        opened.add(uri);
        return succeeds;
    }
}

List<Override> _updateOverrides({
    required AppConfig config,
    required LinkOpener links,
    int installed = 3,
    UpdateDismissalStore? dismissals,
}) =>
    [
        appConfigRepositoryProvider.overrideWithValue(_FakeAppConfigRepository(config)),
        installedVersionProvider.overrideWithValue(_FakeInstalledVersion(installed)),
        updateDismissalStoreProvider
            .overrideWithValue(dismissals ?? InMemoryUpdateDismissalStore()),
        linkOpenerProvider.overrideWithValue(links),
    ];

void main() {
    /// The gate alone over a one-button screen — the same `builder` slot the app uses —
    /// so "can the screen behind it still be tapped" has a direct answer.
    Future<void> pumpGate(
        WidgetTester tester, {
        required AppConfig config,
        required LinkOpener links,
        UpdateDismissalStore? dismissals,
        VoidCallback? onBehindTapped,
    }) async {
        await tester.pumpWidget(
            ProviderScope(
                overrides: _updateOverrides(
                    config: config,
                    links: links,
                    dismissals: dismissals,
                ),
                child: MaterialApp(
                    locale: const Locale('en'),
                    localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: LocaleController.supported,
                    builder: (context, child) => UpdateGate(child: child!),
                    home: Scaffold(
                        body: Center(
                            child: ElevatedButton(
                                key: const Key('behind'),
                                onPressed: onBehindTapped ?? () {},
                                child: const Text('behind'),
                            ),
                        ),
                    ),
                ),
            ),
        );
        await tester.pumpAndSettle();
    }

    testWidgets('a build below minVersionCode is walled off until it updates',
        (tester) async {
        final links = _RecordingLinkOpener();
        var behindTaps = 0;
        await pumpGate(
            tester,
            config: AppConfig(
                minVersionCode: 4,
                latestVersionCode: 5,
                latestVersionName: '1.0.3',
                downloadUrl: _download,
            ),
            links: links,
            onBehindTapped: () => behindTaps++,
        );

        expect(find.byKey(const Key('update-required')), findsOneWidget);
        expect(find.text('Update required'), findsOneWidget);
        expect(find.text('New version: 1.0.3'), findsOneWidget);
        // No way past it: no "Later", and the screen behind takes no taps.
        expect(find.byKey(const Key('update-later')), findsNothing);
        await tester.tap(find.byKey(const Key('behind')), warnIfMissed: false);
        expect(behindTaps, 0);

        await tester.tap(find.byKey(const Key('update-required-download')));
        await tester.pumpAndSettle();
        expect(links.opened, [_download]);
    });

    testWidgets('when no browser opens it, the wall shows the link to copy',
        (tester) async {
        await pumpGate(
            tester,
            config: AppConfig(minVersionCode: 4, downloadUrl: _download),
            links: _RecordingLinkOpener(succeeds: false),
        );

        await tester.tap(find.byKey(const Key('update-required-download')));
        await tester.pumpAndSettle();
        expect(find.text(_download.toString()), findsOneWidget);
    });

    testWidgets('a newer build is a strip with Download and Later, and Later sticks',
        (tester) async {
        final links = _RecordingLinkOpener();
        final dismissals = InMemoryUpdateDismissalStore();
        var behindTaps = 0;
        await pumpGate(
            tester,
            config: AppConfig(
                latestVersionCode: 5,
                latestVersionName: '1.0.3',
                downloadUrl: _download,
            ),
            links: links,
            dismissals: dismissals,
            onBehindTapped: () => behindTaps++,
        );

        expect(find.text('LifeLink 1.0.3 is available.'), findsOneWidget);
        expect(find.byKey(const Key('update-required')), findsNothing);
        await tester.tap(find.byKey(const Key('behind')));
        expect(behindTaps, 1);

        await tester.tap(find.byKey(const Key('update-download')));
        expect(links.opened, [_download]);

        await tester.tap(find.byKey(const Key('update-later')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('update-available')), findsNothing);
        expect(dismissals.dismissedVersionCode(), 5);
    });

    testWidgets('an up-to-date build shows nothing', (tester) async {
        await pumpGate(
            tester,
            config: AppConfig(minVersionCode: 2, latestVersionCode: 3, downloadUrl: _download),
            links: _RecordingLinkOpener(),
        );
        expect(find.byKey(const Key('update-available')), findsNothing);
        expect(find.byKey(const Key('update-required')), findsNothing);
    });

    group('Me tab privacy link', () {
        late FakePushTokenSource pushTokens;

        setUp(() => pushTokens = FakePushTokenSource());
        tearDown(() => pushTokens.refreshes.close());

        Future<void> openMeTab(WidgetTester tester, AppConfig config, LinkOpener links) async {
            await tester.pumpWidget(
                ProviderScope(
                    overrides: [
                        localeStoreProvider
                            .overrideWithValue(InMemoryLocaleStore(const Locale('en'))),
                        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                        sessionStoreProvider
                            .overrideWithValue(FakeSessionStore(testSession())),
                        googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
                        facebookCredentialsProvider
                            .overrideWithValue(FakeFacebookCredentials()),
                        fcmTokenRepositoryProvider.overrideWithValue(FakeFcmTokenRepository()),
                        pushTokenSourceProvider.overrideWithValue(pushTokens),
                        ..._updateOverrides(config: config, links: links),
                    ],
                    child: const LifeLinkApp(),
                ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('dashboard-tab-me')));
            await tester.pumpAndSettle();
        }

        testWidgets('opens the policy in the browser when the config names one',
            (tester) async {
            final links = _RecordingLinkOpener();
            await openMeTab(tester, AppConfig(privacyUrl: _privacy), links);

            final row = find.byKey(const Key('me-privacy-policy'));
            await tester.scrollUntilVisible(
                row,
                200,
                scrollable: find
                    .descendant(of: find.byType(MeTab), matching: find.byType(Scrollable))
                    .first,
            );
            await tester.tap(row);
            expect(links.opened, [_privacy]);
        });

        testWidgets('is absent without a privacyUrl', (tester) async {
            await openMeTab(tester, AppConfig.none, _RecordingLinkOpener());
            expect(find.byKey(const Key('me-privacy-policy')), findsNothing);
        });
    });
}
