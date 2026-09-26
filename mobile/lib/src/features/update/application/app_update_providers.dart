import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../data/package_info_installed_version.dart';
import '../domain/app_config.dart';
import '../domain/app_config_repository.dart';
import '../domain/app_update.dart';
import '../domain/installed_version.dart';
import '../domain/update_dismissal_store.dart';

part 'app_update_providers.g.dart';

/// Overridden in `main.dart` with `FirestoreAppConfigRepository`. The default knows
/// nothing, so every widget test that boots `LifeLinkApp` gets no update notice and no
/// Firestore read without having to ask for either.
@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(AppConfigRepositoryRef ref) =>
    const UnconfiguredAppConfigRepository();

/// The real one by default: it is only asked once the config actually carries version
/// codes, which the default repository above never does.
@Riverpod(keepAlive: true)
InstalledVersion installedVersion(InstalledVersionRef ref) =>
    const PackageInfoInstalledVersion();

/// Overridden in `main.dart` with the `SharedPreferences` store.
@Riverpod(keepAlive: true)
UpdateDismissalStore updateDismissalStore(UpdateDismissalStoreRef ref) =>
    InMemoryUpdateDismissalStore();

/// `config/app`, read once per launch and shared by the update check and the Me tab's
/// privacy link — one document read per app start, whatever the user opens.
///
/// `keepAlive` so switching tabs never reads it again. Never an error: offline, a
/// refused read or a missing document all become [AppConfig.none], because nothing in
/// this document is worth a failure card.
@Riverpod(keepAlive: true)
Future<AppConfig> appConfig(AppConfigRef ref) async {
    try {
        return switch (await ref.watch(appConfigRepositoryProvider).fetch()) {
            Success(value: final config) => config,
            Failed() => AppConfig.none,
        };
    } on Object catch (_) {
        // A plugin that throws something other than a `FirebaseException`. Same answer.
        return AppConfig.none;
    }
}

/// What this launch shows about updates — see `UpdateGate`.
@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
    @override
    Future<AppUpdate> build() async {
        final config = await ref.watch(appConfigProvider.future);
        // Nothing to compare against — skip the platform call entirely.
        if (config.minVersionCode == null && config.latestVersionCode == null) {
            return const UpToDate();
        }
        final int? installed;
        try {
            installed = await ref.read(installedVersionProvider).buildNumber();
        } on Object catch (_) {
            return const UpToDate();
        }
        return appUpdateFor(
            installedBuild: installed,
            config: config,
            dismissedVersionCode: ref.read(updateDismissalStoreProvider).dismissedVersionCode(),
        );
    }

    /// "Later" on the new-version notice. Remembered for that version code only, so the
    /// next release is announced again. A required update has no "Later", and this does
    /// nothing to one.
    ///
    /// State first, write second, like `OnboardingController.complete`: the notice should
    /// go the moment it is tapped, and a failed write only means one more showing.
    Future<void> dismiss() async {
        final current = state.valueOrNull;
        if (current is! UpdateAvailable) return;
        state = const AsyncData(UpToDate());
        await ref.read(updateDismissalStoreProvider).dismiss(current.versionCode);
    }
}
