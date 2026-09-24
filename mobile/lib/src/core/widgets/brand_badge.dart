import 'package:flutter/material.dart';

/// The app's one signature mark — blood is the subject, so the badge is a soft radial
/// glow behind a solid droplet, not a flat icon sitting on blank space.
///
/// Shared, not private to the sign-in screen, because three things must draw the same
/// mark: the sign-in screen, the cold-start splash inside Flutter, and the *native*
/// launch screen shown before Flutter has drawn anything. The last one is a bitmap, and
/// `tool/render_splash_art.dart` renders it from this widget — so the hand-off from the
/// OS splash to the first Flutter frame is the same pixels, not two drawings that drift.
class BrandBadge extends StatelessWidget {
    const BrandBadge({required this.color, super.key});

    /// Logical size of the circle. The native splash art is rendered around this.
    static const double size = 104;

    final Color color;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                ),
                boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 32,
                        spreadRadius: 2,
                    ),
                ],
            ),
            child: const Icon(Icons.bloodtype, size: 52, color: Colors.white),
        );
    }
}
