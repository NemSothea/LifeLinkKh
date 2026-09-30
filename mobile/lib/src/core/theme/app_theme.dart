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
        var scheme = rawScheme.copyWith(
            primary: brightness == Brightness.light ? _primaryLight : _primaryDark,
            onPrimary: Colors.white,
        );
        if (brightness == Brightness.dark) scheme = _neutralDarkSurfaces(scheme);
        final base = ThemeData(brightness: brightness, useMaterial3: true);

        return base.copyWith(
            colorScheme: scheme,
            scaffoldBackgroundColor: scheme.surface,
            extensions: [AppTokens.fromScheme(scheme, brightness)],
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
                // The Kantumruy Pro fallback is not optional here. This style is built
                // directly rather than through _textTheme, so it was the one piece of text
                // in the app with no Khmer fallback — and Inter has no Khmer glyphs, so in
                // Khmer the three tab labels rendered as empty boxes while every other
                // string on the same screen was fine.
                labelTextStyle: WidgetStatePropertyAll(
                    GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                    ).copyWith(fontFamilyFallback: [GoogleFonts.kantumruyPro().fontFamily!]),
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

    /// Dark surface. `fromSeed` tints every dark surface with the seed's hue, and on a red
    /// seed that is a brown-maroon (`#1A1110`) under every screen — muddy, and it eats the
    /// contrast of the red that is meant to be the one loud thing. A near-neutral charcoal
    /// instead, with a trace of warmth so it does not read as cold blue-grey. Also the
    /// native splash's `color_dark` in `pubspec.yaml` — change both together.
    static const Color darkSurface = Color(0xFF141213);

    /// The whole surface ladder, not only `surface`: cards, sheets and the navigation bar
    /// sit on the container steps, and leaving those seed-tinted would put maroon cards on
    /// a charcoal page. Each step is a small, even lift so elevation still reads.
    static ColorScheme _neutralDarkSurfaces(ColorScheme scheme) => scheme.copyWith(
        surface: darkSurface,
        surfaceDim: darkSurface,
        surfaceBright: const Color(0xFF3A3738),
        surfaceContainerLowest: const Color(0xFF0F0D0E),
        surfaceContainerLow: const Color(0xFF1C1A1B),
        surfaceContainer: const Color(0xFF211F20),
        surfaceContainerHigh: const Color(0xFF2B292A),
        surfaceContainerHighest: const Color(0xFF363334),
        onSurface: const Color(0xFFECE7E7),
        onSurfaceVariant: const Color(0xFFC8C2C2),
        outline: const Color(0xFF928B8B),
        outlineVariant: const Color(0xFF484344),
        inverseSurface: const Color(0xFFECE7E7),
        onInverseSurface: const Color(0xFF2B292A),
    );

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

/// Design tokens the Material 3 [ColorScheme] has no slot for: a spacing scale, the
/// app's semantic colours (eligibility, urgency, offline, success), and the line height
/// Khmer needs.
///
/// Read through [AppTokens.of], never `Theme.of(context).extension<AppTokens>()!`
/// directly: a widget test that pumps a bare `MaterialApp` has no extension installed,
/// and [of] derives the same values from whatever scheme is there instead of throwing.
///
/// Every colour is derived from the scheme or pinned per brightness here, once, so a
/// badge on Home and the same badge on the request detail cannot drift apart.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
    const AppTokens({
        required this.eligible,
        required this.onEligible,
        required this.cooldown,
        required this.onCooldown,
        required this.urgencyLow,
        required this.onUrgencyLow,
        required this.urgencyMedium,
        required this.onUrgencyMedium,
        required this.urgencyHigh,
        required this.onUrgencyHigh,
        required this.offline,
        required this.onOffline,
        required this.success,
        required this.onSuccess,
        required this.khmerLineHeight,
    });

    /// Spacing scale, in logical pixels. Named by step, not by use, so a screen picks
    /// the step that looks right rather than inventing a 14 or a 20.
    static const double space4 = 4;
    static const double space8 = 8;
    static const double space12 = 12;
    static const double space16 = 16;
    static const double space24 = 24;
    static const double space32 = 32;

    /// "You can donate now" — good news, painted with the app's own red.
    final Color eligible;
    final Color onEligible;

    /// The 56-day countdown. Calm and neutral: a countdown is not an alert.
    final Color cooldown;
    final Color onCooldown;

    /// `Urgency.routine`.
    final Color urgencyLow;
    final Color onUrgencyLow;

    /// `Urgency.urgent`. Material 3 has no warning role, so this amber is hand-picked
    /// per brightness rather than one pair that washes out or glows.
    final Color urgencyMedium;
    final Color onUrgencyMedium;

    /// `Urgency.critical`.
    final Color urgencyHigh;
    final Color onUrgencyHigh;

    /// The offline strip.
    final Color offline;
    final Color onOffline;

    /// A finished, good outcome — a fulfilled request, an accepted match.
    final Color success;
    final Color onSuccess;

    /// Khmer stacks subscripts and vowels above and below the baseline; Latin line
    /// heights clip them. Applied to Khmer text only.
    final double khmerLineHeight;

    factory AppTokens.fromScheme(ColorScheme scheme, Brightness brightness) {
        final isDark = brightness == Brightness.dark;
        return AppTokens(
            eligible: scheme.primary,
            onEligible: scheme.onPrimary,
            cooldown: scheme.surfaceContainerHighest,
            onCooldown: scheme.onSurfaceVariant,
            urgencyLow: scheme.surfaceContainerHighest,
            onUrgencyLow: scheme.onSurfaceVariant,
            urgencyMedium: isDark ? const Color(0xFF4A3600) : const Color(0xFFFFF1C4),
            onUrgencyMedium: isDark ? const Color(0xFFFFD989) : const Color(0xFF7A5900),
            urgencyHigh: scheme.errorContainer,
            onUrgencyHigh: scheme.onErrorContainer,
            offline: scheme.errorContainer,
            onOffline: scheme.onErrorContainer,
            success: isDark ? const Color(0xFF1B4332) : const Color(0xFFDCF5E7),
            onSuccess: isDark ? const Color(0xFF8FD9B6) : const Color(0xFF1B6E43),
            khmerLineHeight: 1.6,
        );
    }

    static AppTokens of(BuildContext context) {
        final theme = Theme.of(context);
        return theme.extension<AppTokens>() ??
            AppTokens.fromScheme(theme.colorScheme, theme.brightness);
    }

    @override
    AppTokens copyWith({
        Color? eligible,
        Color? onEligible,
        Color? cooldown,
        Color? onCooldown,
        Color? urgencyLow,
        Color? onUrgencyLow,
        Color? urgencyMedium,
        Color? onUrgencyMedium,
        Color? urgencyHigh,
        Color? onUrgencyHigh,
        Color? offline,
        Color? onOffline,
        Color? success,
        Color? onSuccess,
        double? khmerLineHeight,
    }) {
        return AppTokens(
            eligible: eligible ?? this.eligible,
            onEligible: onEligible ?? this.onEligible,
            cooldown: cooldown ?? this.cooldown,
            onCooldown: onCooldown ?? this.onCooldown,
            urgencyLow: urgencyLow ?? this.urgencyLow,
            onUrgencyLow: onUrgencyLow ?? this.onUrgencyLow,
            urgencyMedium: urgencyMedium ?? this.urgencyMedium,
            onUrgencyMedium: onUrgencyMedium ?? this.onUrgencyMedium,
            urgencyHigh: urgencyHigh ?? this.urgencyHigh,
            onUrgencyHigh: onUrgencyHigh ?? this.onUrgencyHigh,
            offline: offline ?? this.offline,
            onOffline: onOffline ?? this.onOffline,
            success: success ?? this.success,
            onSuccess: onSuccess ?? this.onSuccess,
            khmerLineHeight: khmerLineHeight ?? this.khmerLineHeight,
        );
    }

    @override
    AppTokens lerp(AppTokens? other, double t) {
        if (other == null) return this;
        Color c(Color a, Color b) => Color.lerp(a, b, t)!;
        return AppTokens(
            eligible: c(eligible, other.eligible),
            onEligible: c(onEligible, other.onEligible),
            cooldown: c(cooldown, other.cooldown),
            onCooldown: c(onCooldown, other.onCooldown),
            urgencyLow: c(urgencyLow, other.urgencyLow),
            onUrgencyLow: c(onUrgencyLow, other.onUrgencyLow),
            urgencyMedium: c(urgencyMedium, other.urgencyMedium),
            onUrgencyMedium: c(onUrgencyMedium, other.onUrgencyMedium),
            urgencyHigh: c(urgencyHigh, other.urgencyHigh),
            onUrgencyHigh: c(onUrgencyHigh, other.onUrgencyHigh),
            offline: c(offline, other.offline),
            onOffline: c(onOffline, other.onOffline),
            success: c(success, other.success),
            onSuccess: c(onSuccess, other.onSuccess),
            khmerLineHeight: t < 0.5 ? khmerLineHeight : other.khmerLineHeight,
        );
    }
}
