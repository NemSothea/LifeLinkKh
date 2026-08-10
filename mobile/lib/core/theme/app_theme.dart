import 'package:flutter/material.dart';

/// Khmer text is taller and longer than English. Nothing in this theme sets a fixed
/// height on a text-bearing widget — a fixed height is a defect waiting for M6.
class AppTheme {
    AppTheme._();

    static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
            // Blood red, the one place in this app where the colour is the subject.
            seedColor: const Color(0xFFC62828),
        ),
        useMaterial3: true,
    );
}
