import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this directory (Flutter's own convention for this
/// filename). The test sandbox has no network — without this, any widget test that
/// builds `AppTheme` tries to fetch Inter/Kantumruy Pro from fonts.gstatic.com,
/// fails, and falls back to the platform font with a console warning on every run.
///
/// The fonts themselves now ship in `assets/google_fonts/`, so `google_fonts` finds them
/// in the bundle and the text in a golden is the text a donor sees, not the test
/// harness's box glyphs. Material icons need loading by hand: nothing in the widget tree
/// asks for them by asset path, so the harness never pulls them in and every icon in a
/// golden renders as an empty square.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await testMain();
}
