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
        this.releaseNotes,
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

    /// What changed in the latest build, as the admin wrote it on the portal. `null` when
    /// neither language was filled in.
    final ReleaseNotes? releaseNotes;

    @override
    bool operator ==(Object other) =>
        other is AppConfig &&
        other.minVersionCode == minVersionCode &&
        other.latestVersionCode == latestVersionCode &&
        other.latestVersionName == latestVersionName &&
        other.downloadUrl == downloadUrl &&
        other.privacyUrl == privacyUrl &&
        other.releaseNotes == releaseNotes;

    @override
    int get hashCode => Object.hash(minVersionCode, latestVersionCode, latestVersionName,
        downloadUrl, privacyUrl, releaseNotes);

    @override
    String toString() =>
        'AppConfig(min: $minVersionCode, latest: $latestVersionCode '
        '"$latestVersionName", download: $downloadUrl, privacy: $privacyUrl, '
        'notes: $releaseNotes)';
}

/// "What's new" in English and Khmer. The admin may fill in only one, so each language
/// falls back to the other rather than showing nothing.
final class ReleaseNotes {
    const ReleaseNotes({this.en, this.km});

    final String? en;
    final String? km;

    /// `null` when both are blank — the notice then has nothing extra to show.
    static ReleaseNotes? of({String? en, String? km}) {
        final english = _clean(en);
        final khmer = _clean(km);
        if (english == null && khmer == null) return null;
        return ReleaseNotes(en: english, km: khmer);
    }

    static String? _clean(String? raw) {
        final trimmed = raw?.trim();
        return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    /// The notes for the app's language, or the other language's when this one is empty.
    String forLanguage(String languageCode) =>
        (languageCode == 'km' ? (km ?? en) : (en ?? km))!;

    @override
    bool operator ==(Object other) => other is ReleaseNotes && other.en == en && other.km == km;

    @override
    int get hashCode => Object.hash(en, km);

    @override
    String toString() => 'ReleaseNotes(en: "$en", km: "$km")';
}

/// `raw` as a link the app is willing to hand to a browser, or `null`.
///
/// Only `https` with a host. The document is written by an operator script, but it is
/// still data from the network, and an `intent:` or `file:` URI passed to `launchUrl`
/// would do something other than open a page. `http` only when [allowHttp] — the data
/// layer passes `kDebugMode`, for the local demo whose portal is a laptop without TLS
/// (SEC-REVIEW-003 F-15). A release build never opens a download link in clear text,
/// where anyone on the network could swap the APK.
Uri? webLinkFrom(Object? raw, {bool allowHttp = false}) {
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) return null;
    return uri.isScheme('https') || (allowHttp && uri.isScheme('http')) ? uri : null;
}
