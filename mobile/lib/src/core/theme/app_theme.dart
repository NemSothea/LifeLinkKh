import 'package:flutter/material.dart';

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

    static ThemeData _themeFor(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
        useMaterial3: true,
    );
}
