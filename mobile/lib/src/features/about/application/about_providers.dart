import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/env.dart';
import '../../../core/settings/locale_controller.dart';
import '../../update/application/app_update_providers.dart';

/// What this install is: pubspec's `version:` split into its name and its `+N` build.
typedef AppVersion = ({String version, String build});

/// The version a donor reads off the sign-in footer, the Me tab and About.
///
/// Plain `FutureProvider`s in this file, not `@riverpod`: a full `build_runner` rebuild
/// is the one codegen step this repo cannot run safely, and neither provider needs
/// anything the annotation adds. `null` when the platform says nothing — a widget test
/// with no plugin, for one — which every caller renders as no version line at all.
final appVersionProvider = FutureProvider<AppVersion?>((ref) async {
    try {
        final info = await PackageInfo.fromPlatform();
        if (info.version.isEmpty) return null;
        return (version: info.version, build: info.buildNumber);
    } on Object catch (_) {
        return null;
    }
});

/// The privacy policy, in the language the app is in.
///
/// `config/app.privacyUrl` when the release script has set one; otherwise the portal's
/// own page, which exists at `/{locale}/privacy` for both of the app's languages. Never
/// null, so a privacy link can be shown before sign-in and before the config read has
/// come back — a policy the user cannot find until they have already signed in is not
/// much of a promise.
final privacyUriProvider = Provider<Uri>((ref) {
    final configured = ref.watch(appConfigProvider).valueOrNull?.privacyUrl;
    if (configured != null) return configured;
    final lang = ref.watch(localeControllerProvider).languageCode;
    return Uri.parse('${Env.portalUrl}/$lang/privacy');
});
