import 'package:package_info_plus/package_info_plus.dart';

import '../domain/installed_version.dart';

/// `PackageInfo.buildNumber` — on Android the manifest's `versionCode`, which Flutter
/// takes from the `+N` in pubspec's `version:`.
final class PackageInfoInstalledVersion implements InstalledVersion {
    const PackageInfoInstalledVersion();

    @override
    Future<int?> buildNumber() async =>
        int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
}
