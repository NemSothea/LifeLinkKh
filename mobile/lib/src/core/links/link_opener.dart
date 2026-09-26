import 'package:url_launcher/url_launcher.dart';

/// Opens a web page outside the app.
///
/// An interface so a widget test can tap "Download" or "Privacy policy" and see what
/// would have opened, without a platform channel.
abstract interface class LinkOpener {
    /// `false` when nothing on the phone could open it.
    Future<bool> open(Uri uri);
}

/// `url_launcher`, always in the external browser.
///
/// External rather than an in-app web view for both links this app has. The download
/// page hands back an APK, and only the browser's own download and install flow can
/// pass it to the package installer; an in-app view would just stop there. The privacy
/// policy is a page the user may want to keep, share or come back to.
final class UrlLauncherLinkOpener implements LinkOpener {
    const UrlLauncherLinkOpener();

    @override
    Future<bool> open(Uri uri) async {
        try {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on Object catch (_) {
            // A `PlatformException` for a URI no app claims. Reported as "could not open",
            // which the caller already handles; nothing about it is worth crashing on.
            return false;
        }
    }
}
