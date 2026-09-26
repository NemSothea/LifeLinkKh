import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/update/application/app_update_providers.dart';
import 'package:lifelink_kh/src/features/update/data/firestore_app_config_repository.dart';
import 'package:lifelink_kh/src/features/update/data/preferences_update_dismissal_store.dart';
import 'package:lifelink_kh/src/features/update/domain/app_config.dart';
import 'package:lifelink_kh/src/features/update/domain/app_config_repository.dart';
import 'package:lifelink_kh/src/features/update/domain/app_update.dart';
import 'package:lifelink_kh/src/features/update/domain/installed_version.dart';
import 'package:lifelink_kh/src/features/update/domain/update_dismissal_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sideload update check: what `config/app` says, against the installed build.
/// Every "no information" path must land on [UpToDate] — a wrong answer here either
/// nags every donor or locks them out during an emergency.
final Uri _download = Uri.parse('https://lifelink.example/km/download');

AppConfig _config({int? min, int? latest, String? name = '1.0.3', Uri? download}) =>
    AppConfig(
        minVersionCode: min,
        latestVersionCode: latest,
        latestVersionName: name,
        downloadUrl: download ?? _download,
    );

final class _FakeAppConfigRepository implements AppConfigRepository {
    _FakeAppConfigRepository(this.result);

    Result<AppConfig> result;
    int fetches = 0;

    @override
    Future<Result<AppConfig>> fetch() async {
        fetches++;
        return result;
    }
}

final class _FakeInstalledVersion implements InstalledVersion {
    _FakeInstalledVersion(this.build);

    final int? build;
    int calls = 0;

    @override
    Future<int?> buildNumber() async {
        calls++;
        return build;
    }
}

void main() {
    group('appUpdateFor', () {
        test('below minVersionCode is a required update', () {
            expect(
                appUpdateFor(installedBuild: 2, config: _config(min: 3, latest: 5)),
                UpdateRequired(versionName: '1.0.3', downloadUrl: _download),
            );
        });

        test('at min but below latest is an available update', () {
            expect(
                appUpdateFor(installedBuild: 3, config: _config(min: 3, latest: 5)),
                UpdateAvailable(versionCode: 5, versionName: '1.0.3', downloadUrl: _download),
            );
        });

        test('at latest is up to date', () {
            expect(
                appUpdateFor(installedBuild: 5, config: _config(min: 3, latest: 5)),
                const UpToDate(),
            );
        });

        test('a dismissal silences that version only', () {
            expect(
                appUpdateFor(
                    installedBuild: 3,
                    config: _config(latest: 5),
                    dismissedVersionCode: 5,
                ),
                const UpToDate(),
            );
            expect(
                appUpdateFor(
                    installedBuild: 3,
                    config: _config(latest: 6),
                    dismissedVersionCode: 5,
                ),
                isA<UpdateAvailable>().having((u) => u.versionCode, 'versionCode', 6),
            );
        });

        test('a dismissal never lifts a required update', () {
            expect(
                appUpdateFor(
                    installedBuild: 2,
                    config: _config(min: 3, latest: 5),
                    dismissedVersionCode: 5,
                ),
                isA<UpdateRequired>(),
            );
        });

        test('missing fields say nothing', () {
            expect(appUpdateFor(installedBuild: 1, config: AppConfig.none), const UpToDate());
            expect(appUpdateFor(installedBuild: null, config: _config(min: 3)), const UpToDate());
            // No download link: nothing to offer, so nothing may block.
            expect(
                appUpdateFor(
                    installedBuild: 1,
                    config: const AppConfig(minVersionCode: 3, latestVersionCode: 5),
                ),
                const UpToDate(),
            );
        });
    });

    group('appConfigFrom', () {
        test('reads a complete document', () {
            expect(
                appConfigFrom({
                    'minVersionCode': 2,
                    'latestVersionCode': 4,
                    'latestVersionName': ' 1.0.3 ',
                    'downloadUrl': 'https://lifelink.example/km/download',
                    'privacyUrl': 'https://lifelink.example/km/privacy',
                }),
                AppConfig(
                    minVersionCode: 2,
                    latestVersionCode: 4,
                    latestVersionName: '1.0.3',
                    downloadUrl: _download,
                    privacyUrl: Uri.parse('https://lifelink.example/km/privacy'),
                ),
            );
        });

        test('drops a bad field without losing the rest', () {
            final config = appConfigFrom({
                'minVersionCode': 2.0,
                'latestVersionCode': 4.5,
                'latestVersionName': 7,
                'downloadUrl': 'intent://evil#Intent;end',
                'privacyUrl': 'file:///sdcard/x',
            });
            expect(config.minVersionCode, 2);
            expect(config.latestVersionCode, isNull);
            expect(config.latestVersionName, isNull);
            expect(config.downloadUrl, isNull);
            expect(config.privacyUrl, isNull);
        });

        test('an empty document is no information', () {
            expect(appConfigFrom({}), AppConfig.none);
        });
    });

    group('AppUpdateController', () {
        ProviderContainer container({
            required _FakeAppConfigRepository repository,
            required _FakeInstalledVersion installed,
            UpdateDismissalStore? dismissals,
        }) {
            final c = ProviderContainer(
                overrides: [
                    appConfigRepositoryProvider.overrideWithValue(repository),
                    installedVersionProvider.overrideWithValue(installed),
                    updateDismissalStoreProvider
                        .overrideWithValue(dismissals ?? InMemoryUpdateDismissalStore()),
                ],
            );
            addTearDown(c.dispose);
            return c;
        }

        test('a failed read is up to date, and never asks the platform', () async {
            final installed = _FakeInstalledVersion(1);
            final c = container(
                repository: _FakeAppConfigRepository(
                    const Failed(NetworkFailure()),
                ),
                installed: installed,
            );
            expect(await c.read(appUpdateControllerProvider.future), const UpToDate());
            expect(installed.calls, 0);
        });

        test('"Later" hides the notice and remembers that version', () async {
            final dismissals = InMemoryUpdateDismissalStore();
            final c = container(
                repository: _FakeAppConfigRepository(Success(_config(latest: 5))),
                installed: _FakeInstalledVersion(3),
                dismissals: dismissals,
            );
            expect(await c.read(appUpdateControllerProvider.future), isA<UpdateAvailable>());

            await c.read(appUpdateControllerProvider.notifier).dismiss();

            expect(c.read(appUpdateControllerProvider).valueOrNull, const UpToDate());
            expect(dismissals.dismissedVersionCode(), 5);
        });

        test('the config is read once, however many readers', () async {
            final repository = _FakeAppConfigRepository(Success(_config(latest: 5)));
            final c = container(repository: repository, installed: _FakeInstalledVersion(5));
            await c.read(appUpdateControllerProvider.future);
            await c.read(appConfigProvider.future);
            expect(repository.fetches, 1);
        });
    });

    test('PreferencesUpdateDismissalStore survives a restart', () async {
        SharedPreferences.setMockInitialValues({});
        await PreferencesUpdateDismissalStore(await SharedPreferences.getInstance())
            .dismiss(7);
        expect(
            PreferencesUpdateDismissalStore(await SharedPreferences.getInstance())
                .dismissedVersionCode(),
            7,
        );
    });
}
