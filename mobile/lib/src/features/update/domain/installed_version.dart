/// The build number of the app running on this phone — pubspec's `+N`, Android's
/// `versionCode`.
abstract interface class InstalledVersion {
    /// `null` when the platform does not report one as an integer, which `appUpdateFor`
    /// treats as "nothing to say".
    Future<int?> buildNumber();
}
