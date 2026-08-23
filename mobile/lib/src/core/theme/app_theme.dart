import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Khmer text is taller and longer than English. Nothing in this theme sets a fixed
/// height on a text-bearing widget — a fixed height is a defect waiting for M6.
class AppTheme {
    AppTheme._();

    /// Blood red, the one place in this app where the colour is the subject. One seed
    /// for both variants, so light and dark cannot drift apart.
    static const Color _seed = Color(0xFFC62828);

    static ThemeData get light => _themeFor(Brightness.light);

    /// Week 2 requires both variants. It is not a nicety here: an urgent blood request
    /// is most likely read at night, on a phone that has been in dark mode all day.
    static ThemeData get dark => _themeFor(Brightness.dark);

    static ThemeData _themeFor(Brightness brightness) {
        final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
        final base = ThemeData(brightness: brightness, useMaterial3: true);

        return base.copyWith(
            colorScheme: scheme,
            textTheme: _textTheme(base.textTheme),
            pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                    TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
                    TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
                },
            ),
            cardTheme: const CardThemeData(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
            ),
            navigationBarTheme: NavigationBarThemeData(
                height: 68,
                labelTextStyle: WidgetStatePropertyAll(
                    GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
            ),
        );
    }

    /// Manrope for Latin — a warmer, more characterful geometric sans than the Material
    /// default — falling back to Noto Sans Khmer for the script Manrope has no glyphs
    /// for. The two are both humanist sans designs at a similar x-height, so a string
    /// mixing scripts (the app title does, on purpose) does not visibly clash.
    static TextTheme _textTheme(TextTheme base) {
        final khmerFallback = [GoogleFonts.notoSansKhmer().fontFamily!];
        final manrope = GoogleFonts.manropeTextTheme(base);

        TextStyle? withFallback(TextStyle? style) =>
            style?.copyWith(fontFamilyFallback: khmerFallback);

        return manrope.copyWith(
            displayLarge: withFallback(manrope.displayLarge),
            displayMedium: withFallback(manrope.displayMedium),
            displaySmall: withFallback(manrope.displaySmall),
            headlineLarge: withFallback(manrope.headlineLarge),
            headlineMedium: withFallback(manrope.headlineMedium),
            headlineSmall: withFallback(manrope.headlineSmall),
            titleLarge: withFallback(manrope.titleLarge),
            titleMedium: withFallback(manrope.titleMedium),
            titleSmall: withFallback(manrope.titleSmall),
            bodyLarge: withFallback(manrope.bodyLarge),
            bodyMedium: withFallback(manrope.bodyMedium),
            bodySmall: withFallback(manrope.bodySmall),
            labelLarge: withFallback(manrope.labelLarge),
            labelMedium: withFallback(manrope.labelMedium),
            labelSmall: withFallback(manrope.labelSmall),
        );
    }
}
