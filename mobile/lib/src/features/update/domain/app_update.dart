import 'app_config.dart';

/// What this launch should say about updates.
///
/// Sideloaded APKs never update themselves — there is no Play Store listing until the
/// app has 500 users — so this is the only way a donor learns that the copy on their
/// phone is out of date.
sealed class AppUpdate {
    const AppUpdate();
}

/// Nothing to say: current, dismissed, or no information to go on.
final class UpToDate extends AppUpdate {
    const UpToDate();

    @override
    bool operator ==(Object other) => other is UpToDate;

    @override
    int get hashCode => (UpToDate).hashCode;

    @override
    String toString() => 'UpToDate()';
}

/// A newer build exists. Dismissable, and a dismissal is remembered per [versionCode].
final class UpdateAvailable extends AppUpdate {
    const UpdateAvailable({
        required this.versionCode,
        required this.downloadUrl,
        this.versionName,
        this.releaseNotes,
    });

    final int versionCode;
    final String? versionName;
    final Uri downloadUrl;
    final ReleaseNotes? releaseNotes;

    @override
    bool operator ==(Object other) =>
        other is UpdateAvailable &&
        other.versionCode == versionCode &&
        other.versionName == versionName &&
        other.downloadUrl == downloadUrl &&
        other.releaseNotes == releaseNotes;

    @override
    int get hashCode => Object.hash(versionCode, versionName, downloadUrl, releaseNotes);

    @override
    String toString() => 'UpdateAvailable($versionCode "$versionName", $downloadUrl)';
}

/// This build is below `minVersionCode`: nothing else in the app is reachable until the
/// user installs a newer one. Never dismissable.
final class UpdateRequired extends AppUpdate {
    const UpdateRequired({required this.downloadUrl, this.versionName, this.releaseNotes});

    /// The newest version's name — what the user will be installing — when known.
    final String? versionName;
    final Uri downloadUrl;
    final ReleaseNotes? releaseNotes;

    @override
    bool operator ==(Object other) =>
        other is UpdateRequired &&
        other.versionName == versionName &&
        other.downloadUrl == downloadUrl &&
        other.releaseNotes == releaseNotes;

    @override
    int get hashCode => Object.hash(versionName, downloadUrl, releaseNotes);

    @override
    String toString() => 'UpdateRequired("$versionName", $downloadUrl)';
}

/// The whole decision, pure so every branch is a one-line test.
///
/// Every missing input resolves to [UpToDate]. A config without a `downloadUrl` cannot
/// offer a way out, so it cannot block either: a "you must update" screen with no
/// download button would lock a donor out of the app during an emergency for nothing.
AppUpdate appUpdateFor({
    required int? installedBuild,
    required AppConfig config,
    int? dismissedVersionCode,
}) {
    final download = config.downloadUrl;
    if (installedBuild == null || download == null) return const UpToDate();

    final min = config.minVersionCode;
    if (min != null && installedBuild < min) {
        return UpdateRequired(
            versionName: config.latestVersionName,
            downloadUrl: download,
            releaseNotes: config.releaseNotes,
        );
    }

    final latest = config.latestVersionCode;
    if (latest != null && installedBuild < latest && dismissedVersionCode != latest) {
        return UpdateAvailable(
            versionCode: latest,
            versionName: config.latestVersionName,
            downloadUrl: download,
            releaseNotes: config.releaseNotes,
        );
    }
    return const UpToDate();
}
