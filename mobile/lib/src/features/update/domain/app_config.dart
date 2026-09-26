/// The public `config/app` document: what the operator's release script says about the
/// app, read once per launch.
///
/// Every field is nullable, and that is the point of the type rather than a gap in it.
/// The document may not exist yet, or may predate a field, and a missing value means
/// "no information" — never "block the app". Anything that decides what to show reads
/// these through `appUpdateFor`, which treats each `null` as the harmless answer.
final class AppConfig {
    const AppConfig({
        this.minVersionCode,
        this.latestVersionCode,
        this.latestVersionName,
        this.downloadUrl,
        this.privacyUrl,
    });

    /// No document, a failed read, or a phone that was offline at launch.
    static const AppConfig none = AppConfig();

    /// Builds below this must update before they can be used.
    final int? minVersionCode;

    /// The newest build the download page offers.
    final int? latestVersionCode;

    /// e.g. `1.0.3` — the only version the user ever sees; version codes are for machines.
    final String? latestVersionName;

    /// The portal's download page, or a direct APK link. Already checked to be a web
    /// link by the data layer — see `webLinkFrom`.
    final Uri? downloadUrl;

    /// The portal's privacy policy page. `null` hides the Me tab's link.
    final Uri? privacyUrl;

    @override
    bool operator ==(Object other) =>
        other is AppConfig &&
        other.minVersionCode == minVersionCode &&
        other.latestVersionCode == latestVersionCode &&
        other.latestVersionName == latestVersionName &&
        other.downloadUrl == downloadUrl &&
        other.privacyUrl == privacyUrl;

    @override
    int get hashCode => Object.hash(
        minVersionCode, latestVersionCode, latestVersionName, downloadUrl, privacyUrl);

    @override
    String toString() =>
        'AppConfig(min: $minVersionCode, latest: $latestVersionCode '
        '"$latestVersionName", download: $downloadUrl, privacy: $privacyUrl)';
}

/// `raw` as a link the app is willing to hand to a browser, or `null`.
///
/// Only `http`/`https` with a host. The document is written by an operator script, but
/// it is still data from the network, and an `intent:` or `file:` URI passed to
/// `launchUrl` would do something other than open a page. `http` stays allowed for the
/// local demo, where the portal is served from a laptop without TLS.
Uri? webLinkFrom(Object? raw) {
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) return null;
    return uri.isScheme('https') || uri.isScheme('http') ? uri : null;
}
