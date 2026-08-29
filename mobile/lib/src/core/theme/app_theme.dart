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

    /// The vivid red every button, badge, and icon actually paints with — not the seed
    /// itself for dark mode. `ColorScheme.fromSeed`'s HCT tonal mapping runs the seed
    /// through its own algorithm rather than reproducing it: on this seed specifically,
    /// the light-mode primary it derives is `#904A44`, a muddy brick red with none of
    /// the vividness "blood red, the one place colour is the subject" was chosen for.
    /// Overriding `primary`/`onPrimary` below keeps the rest of the seed-derived
    /// palette (containers, tertiary, surfaces) but pins the one color users actually
    /// register as "the app's red" to a value chosen for how it looks, not what the
    /// algorithm outputs. Verified against WCAG AA: white-on-`_seed` is 5.6:1; the
    /// dark-mode lift is 4.5:1 against this theme's dark surface.
    static const Color _primaryLight = _seed;
    static const Color _primaryDark = Color(0xFFD15353);

    static ThemeData _themeFor(Brightness brightness) {
        final rawScheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
        final scheme = rawScheme.copyWith(
            primary: brightness == Brightness.light ? _primaryLight : _primaryDark,
            onPrimary: Colors.white,
        );
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
                    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
            ),
            // 14 to match filledButtonTheme — a field is a control you interact with
            // directly, same as a button. Without this every TextField/dropdown across
            // the app fell back to a bare square-ish OutlineInputBorder, each screen
            // re-specifying its own border by hand.
            inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            // 18 to match cardTheme — a dialog is a surface/container, same as a card.
            // Without this AlertDialog used Material 3's default 28dp radius, a third
            // value next to the 18/14 this theme already commits to everywhere else.
            dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
        );
    }

    /// Inter for Latin, falling back to Kantumruy Pro for the script Inter has no glyphs
    /// for. Both are humanist sans designs at a similar x-height, so a string mixing
    /// scripts (the app title does, on purpose) does not visibly clash.
    static TextTheme _textTheme(TextTheme base) {
        final khmerFallback = [GoogleFonts.kantumruyPro().fontFamily!];
        final inter = GoogleFonts.interTextTheme(base);

        TextStyle? withFallback(TextStyle? style) =>
            style?.copyWith(fontFamilyFallback: khmerFallback);

        return inter.copyWith(
            displayLarge: withFallback(inter.displayLarge),
            displayMedium: withFallback(inter.displayMedium),
            displaySmall: withFallback(inter.displaySmall),
            headlineLarge: withFallback(inter.headlineLarge),
            headlineMedium: withFallback(inter.headlineMedium),
            headlineSmall: withFallback(inter.headlineSmall),
            titleLarge: withFallback(inter.titleLarge),
            titleMedium: withFallback(inter.titleMedium),
            titleSmall: withFallback(inter.titleSmall),
            bodyLarge: withFallback(inter.bodyLarge),
            bodyMedium: withFallback(inter.bodyMedium),
            bodySmall: withFallback(inter.bodySmall),
            labelLarge: withFallback(inter.labelLarge),
            labelMedium: withFallback(inter.labelMedium),
            labelSmall: withFallback(inter.labelSmall),
        );
    }
}
