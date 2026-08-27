import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this directory (Flutter's own convention for this
/// filename). The test sandbox has no network — without this, any widget test that
/// builds `AppTheme` tries to fetch Inter/Kantumruy Pro from fonts.gstatic.com,
/// fails, and falls back to the platform font with a console warning on every run.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await testMain();
}
