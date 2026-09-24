// Renders the native launch-screen art from the real `BrandBadge`, so the OS splash and
// the first Flutter frame are the same mark. Run from `mobile/`, then regenerate:
//
//   flutter test tool/render_splash_art.dart
//   dart run flutter_native_splash:create
//
// Lives under tool/, not test/, so `flutter test` in CI never rewrites committed art.
// It prints the two surface colours as well — `flutter_native_splash.color` and
// `color_dark` in pubspec.yaml must match them, or the hand-off shows a seam.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/theme/app_theme.dart';
import 'package:lifelink_kh/src/core/widgets/brand_badge.dart';

/// flutter_native_splash treats its source image as 4x (xxxhdpi / iOS @4x) and scales
/// down from there, so 4 logical px per dp keeps the badge at `BrandBadge.size` dp.
const double _pixelRatio = 4;

/// Room for the glow: `blurRadius: 32` is a sigma of ~19, which fades out ~3 sigma
/// past the edge. Clipping it would draw a hard square around the badge.
const double _canvas = BrandBadge.size + 2 * 64;

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Future<void> _render(WidgetTester tester, ThemeData theme, String out) async {
    final key = GlobalKey();
    await tester.pumpWidget(
        MaterialApp(
            theme: theme,
            home: Center(
                child: RepaintBoundary(
                    key: key,
                    child: SizedBox.square(
                        dimension: _canvas,
                        child: Center(child: BrandBadge(color: theme.colorScheme.primary)),
                    ),
                ),
            ),
        ),
    );
    await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('$out  surface=${_hex(theme.colorScheme.surface)}  primary=${_hex(theme.colorScheme.primary)}');
}

/// `flutter test` draws every glyph with the Ahem test font (a filled square) and
/// flattens shadows unless told otherwise — both would bake into the art.
Future<void> _loadMaterialIcons() async {
    final sdk = Platform.environment['FLUTTER_ROOT']!;
    final font = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
    await loader.load();
}

void main() {
    testWidgets('render native splash art', (tester) async {
        await tester.runAsync(_loadMaterialIcons);
        debugDisableShadows = false;
        await _render(tester, AppTheme.light, 'assets/branding/splash.png');
        await _render(tester, AppTheme.dark, 'assets/branding/splash-dark.png');
        // Restored inside the body: the harness asserts it is back to true before any
        // tearDown runs.
        debugDisableShadows = true;
    });
}
