import 'package:flutter/material.dart';

/// The soft red wash behind the two screens a new install sees first — the intro and
/// sign-in. A tint of the brand red that fades into the plain surface by the lower
/// half, so the top of the screen reads as "LifeLink" and the bottom stays the flat
/// surface Material 3 controls expect.
///
/// Painted edge to edge, under the status bar: the caller puts its `SafeArea` inside.
class BrandBackdrop extends StatelessWidget {
    const BrandBackdrop({required this.child, super.key});

    final Widget child;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        // Stronger in dark mode: a 16% tint on a near-black surface is invisible.
        final alpha = theme.brightness == Brightness.dark ? 0.30 : 0.16;

        return DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.62],
                    colors: [
                        Color.alphaBlend(scheme.primary.withValues(alpha: alpha), scheme.surface),
                        scheme.surface,
                    ],
                ),
            ),
            child: child,
        );
    }
}
