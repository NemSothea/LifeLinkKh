import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/avatar_spec.dart';

/// A generated face in a circle, drawn from an [AvatarSpec] — no image assets and no
/// network, so it paints offline and on the first frame.
///
/// Khmer on purpose, not a generic cartoon: Angkor's towers behind the shoulders, a
/// checked krama round a man's neck, a silk sbai over a woman's shoulder with a rumdul
/// in her hair. The people who open this app should recognise themselves in it.
class ProfileAvatar extends StatelessWidget {
    const ProfileAvatar({super.key, required this.spec, this.radius = 28, this.semanticLabel});

    final AvatarSpec spec;
    final double radius;
    final String? semanticLabel;

    @override
    Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        image: true,
        child: SizedBox.square(
            dimension: radius * 2,
            child: ClipOval(child: CustomPaint(painter: AvatarPainter(spec))),
        ),
    );
}

/// Paints in a unit square scaled to the canvas, so every coordinate below reads as a
/// fraction of the avatar's width. Back to front: sky, towers, hair behind the head,
/// body and clothes, neck, head, hair on top, face, jewellery.
class AvatarPainter extends CustomPainter {
    AvatarPainter(this.spec) : _look = _Look.from(spec.seed);

    final AvatarSpec spec;
    final _Look _look;

    static const Color _ink = Color(0xFF2B1B17);
    static const Color _mouth = Color(0xFF7A3B2E);
    static const Color _blush = Color(0x40E57373);
    static const Color _gold = Color(0xFFD4A017);
    static const Color _cream = Color(0xFFFFF8E7);

    bool get _female => spec.gender == AvatarGender.female;

    @override
    void paint(Canvas canvas, Size size) {
        canvas.save();
        canvas.scale(size.width, size.height);
        final fill = Paint()..isAntiAlias = true;

        canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), fill..color = _look.background);
        _towers(canvas, fill);

        if (_female) _hairBehind(canvas, fill);

        final body = Rect.fromCenter(center: const Offset(0.5, 1.02), width: 0.80, height: 0.52);
        canvas.drawOval(body, fill..color = _look.top);
        canvas.drawRRect(
            RRect.fromLTRBR(0.43, 0.56, 0.57, 0.80, const Radius.circular(0.05)),
            fill..color = Color.lerp(_look.skin, Colors.black, 0.10)!,
        );
        if (_female) {
            _sbai(canvas, body);
        } else {
            _krama(canvas);
        }

        fill.color = _look.skin;
        canvas.drawCircle(const Offset(0.29, 0.45), 0.05, fill);
        canvas.drawCircle(const Offset(0.71, 0.45), 0.05, fill);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(0.5, 0.43), width: 0.42, height: 0.46),
            fill,
        );

        canvas.drawPath(_topHair(), fill..color = _look.hair);
        _face(canvas, fill);

        if (_female) {
            if (_look.earrings) {
                fill.color = _gold;
                canvas.drawCircle(const Offset(0.285, 0.515), 0.018, fill);
                canvas.drawCircle(const Offset(0.715, 0.515), 0.018, fill);
            }
            if (_look.accessory) _rumdul(canvas, _flowerSpot());
        } else if (_look.accessory) {
            _glasses(canvas);
        }
        canvas.restore();
    }

    /// Angkor's towers, a shade darker than the sky, standing either side of the
    /// shoulders. The centre tower would sit behind the head, so only the four flanking
    /// ones are drawn.
    void _towers(Canvas canvas, Paint fill) {
        fill.color = Color.lerp(_look.background, Colors.black, 0.16)!;
        final path = Path();
        void tower(double x, double width, double height) {
            final top = 1.0 - height;
            final shoulder = 1.0 - height * 0.45;
            path
                ..moveTo(x - width / 2, 1.0)
                ..lineTo(x - width / 2, shoulder)
                ..quadraticBezierTo(x - width * 0.45, top + height * 0.15, x, top)
                ..quadraticBezierTo(x + width * 0.45, top + height * 0.15, x + width / 2, shoulder)
                ..lineTo(x + width / 2, 1.0)
                ..close();
        }

        tower(0.08, 0.11, 0.36);
        tower(0.21, 0.13, 0.48);
        tower(0.79, 0.13, 0.48);
        tower(0.92, 0.11, 0.36);
        // The terrace the towers stand on.
        path.addRect(const Rect.fromLTRB(0, 0.90, 1, 1));
        canvas.drawPath(path, fill);
    }

    void _hairBehind(Canvas canvas, Paint fill) {
        fill.color = _look.hair;
        switch (_look.style) {
            case 0: // long, loose
                canvas.drawRRect(
                    RRect.fromLTRBR(0.22, 0.22, 0.78, 0.82, const Radius.circular(0.26)),
                    fill,
                );
            case 1: // high bun, the way dancers wear it
                canvas.drawCircle(const Offset(0.5, 0.13), 0.10, fill);
            default: // low bun at the side
                canvas.drawOval(
                    Rect.fromCenter(center: const Offset(0.74, 0.50), width: 0.18, height: 0.20),
                    fill,
                );
        }
    }

    /// The krama: cream cloth checked in one colour, knotted at the throat with one end
    /// hanging down the chest. Gingham is two sets of translucent bands crossing, which
    /// gives the darker squares where they meet for free.
    void _krama(Canvas canvas) {
        final scarf = Path()
            ..addRRect(RRect.fromLTRBR(0.31, 0.70, 0.69, 0.83, const Radius.circular(0.06)))
            ..addRRect(RRect.fromLTRBR(0.52, 0.76, 0.63, 1.02, const Radius.circular(0.02)));
        canvas.save();
        canvas.clipPath(scarf);
        canvas.drawRect(const Rect.fromLTRB(0.3, 0.68, 0.7, 1.02), Paint()..color = _cream);
        final band = Paint()..color = _look.accent.withValues(alpha: 0.55);
        const step = 0.045;
        for (var x = 0.30; x < 0.70; x += step * 2) {
            canvas.drawRect(Rect.fromLTWH(x, 0.68, step, 0.36), band);
        }
        for (var y = 0.68; y < 1.02; y += step * 2) {
            canvas.drawRect(Rect.fromLTWH(0.30, y, 0.40, step), band);
        }
        canvas.restore();
    }

    /// The sbai: a silk sash from the left shoulder across the body, edged in gold.
    void _sbai(Canvas canvas, Rect body) {
        final sash = Path()
            ..moveTo(0.22, 0.86)
            ..lineTo(0.38, 0.76)
            ..lineTo(0.84, 1.02)
            ..lineTo(0.60, 1.02)
            ..close();
        canvas.save();
        canvas.clipPath(Path()..addOval(body));
        canvas.drawPath(sash, Paint()..isAntiAlias = true..color = _look.accent);
        canvas.drawPath(
            sash,
            Paint()
                ..isAntiAlias = true
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.014
                ..color = _gold,
        );
        canvas.restore();
    }

    /// The hair over the forehead: a crown arc closed by a fringe that differs per style.
    Path _topHair() {
        final crown = _female
            ? const Rect.fromLTRB(0.26, 0.16, 0.74, 0.56)
            : const Rect.fromLTRB(0.27, 0.17, 0.73, 0.55);
        final path = Path()..arcTo(crown, math.pi, math.pi, true);
        final right = crown.right;
        final left = crown.left;
        switch ((_female, _look.style)) {
            case (false, 0): // short, straight fringe
                path
                    ..lineTo(right - 0.01, 0.40)
                    ..quadraticBezierTo(0.56, 0.27, left + 0.03, 0.38)
                    ..lineTo(left, 0.40);
            case (false, 1): // side part with a lift at the front
                path
                    ..lineTo(right - 0.01, 0.42)
                    ..quadraticBezierTo(0.62, 0.31, 0.46, 0.28)
                    ..quadraticBezierTo(0.36, 0.33, left + 0.02, 0.42);
                path.addOval(
                    Rect.fromCenter(center: const Offset(0.43, 0.19), width: 0.22, height: 0.10),
                );
            case (false, _): // textured, spiked fringe
                path.lineTo(right - 0.01, 0.40);
                for (var i = 0; i < 5; i++) {
                    final x = right - 0.02 - i * 0.085;
                    path
                        ..lineTo(x - 0.04, 0.29)
                        ..lineTo(x - 0.085, 0.35);
                }
                path.lineTo(left, 0.40);
            case (true, 0): // centre part, framing the face
                path
                    ..lineTo(right - 0.01, 0.52)
                    ..quadraticBezierTo(0.66, 0.30, 0.50, 0.29)
                    ..quadraticBezierTo(0.36, 0.30, left + 0.01, 0.52);
            case (true, 1): // pulled back tight under the high bun
                path
                    ..lineTo(right - 0.01, 0.40)
                    ..quadraticBezierTo(0.50, 0.24, left + 0.01, 0.40);
            case (true, _): // swept to one side
                path
                    ..lineTo(right - 0.01, 0.50)
                    ..quadraticBezierTo(0.60, 0.26, 0.36, 0.34)
                    ..quadraticBezierTo(0.30, 0.40, left + 0.01, 0.50);
        }
        return path..close();
    }

    void _face(Canvas canvas, Paint fill) {
        final stroke = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

        // Brows: thicker and flatter on a man, a thin arch on a woman.
        stroke
            ..color = _look.hair
            ..strokeWidth = _female ? 0.012 : 0.02;
        for (final x in [0.42, 0.58]) {
            canvas.drawPath(
                Path()
                    ..moveTo(x - 0.035, 0.415)
                    ..quadraticBezierTo(x, _female ? 0.395 : 0.405, x + 0.035, 0.415),
                stroke,
            );
        }

        fill.color = _ink;
        canvas.drawCircle(const Offset(0.42, 0.46), 0.022, fill);
        canvas.drawCircle(const Offset(0.58, 0.46), 0.022, fill);
        if (_female) {
            fill.color = _blush;
            canvas.drawCircle(const Offset(0.37, 0.53), 0.032, fill);
            canvas.drawCircle(const Offset(0.63, 0.53), 0.032, fill);
        }

        stroke
            ..color = _mouth
            ..strokeWidth = 0.018;
        final (half, depth) = switch (_look.smile) {
            0 => (0.06, 0.05),
            1 => (0.045, 0.035),
            _ => (0.07, 0.07),
        };
        canvas.drawPath(
            Path()
                ..moveTo(0.5 - half, 0.54)
                ..quadraticBezierTo(0.5, 0.54 + depth, 0.5 + half, 0.54),
            stroke,
        );
    }

    Offset _flowerSpot() => switch (_look.style) {
        0 => const Offset(0.69, 0.30),
        1 => const Offset(0.59, 0.10),
        _ => const Offset(0.76, 0.43),
    };

    /// A rumdul, Cambodia's national flower: five pale petals round a golden heart.
    void _rumdul(Canvas canvas, Offset center) {
        final petal = Paint()..isAntiAlias = true..color = const Color(0xFFFFF3C4);
        const r = 0.022;
        for (var i = 0; i < 5; i++) {
            final angle = -math.pi / 2 + i * 2 * math.pi / 5;
            canvas.drawCircle(
                center + Offset(math.cos(angle), math.sin(angle)) * r,
                r,
                petal,
            );
        }
        canvas.drawCircle(center, r * 0.7, Paint()..isAntiAlias = true..color = _gold);
    }

    void _glasses(Canvas canvas) {
        final frame = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.012
            ..color = _ink;
        canvas.drawCircle(const Offset(0.42, 0.46), 0.05, frame);
        canvas.drawCircle(const Offset(0.58, 0.46), 0.05, frame);
        canvas.drawLine(const Offset(0.47, 0.455), const Offset(0.53, 0.455), frame);
    }

    @override
    bool shouldRepaint(AvatarPainter oldDelegate) => oldDelegate.spec != spec;
}

/// Everything the seed decides. A fixed LCG rather than `dart:math`'s `Random(seed)`,
/// whose sequence is not promised to stay the same across SDK releases — a stored avatar
/// has to draw the same face after an update.
final class _Look {
    const _Look({
        required this.skin,
        required this.hair,
        required this.background,
        required this.top,
        required this.accent,
        required this.style,
        required this.smile,
        required this.accessory,
        required this.earrings,
    });

    factory _Look.from(int seed) {
        var state = seed & 0x7fffffff;
        int next(int n) {
            state = (state * 1103515245 + 12345) & 0x7fffffff;
            return (state >> 8) % n;
        }

        return _Look(
            skin: _skins[next(_skins.length)],
            hair: _hairs[next(_hairs.length)],
            background: _backgrounds[next(_backgrounds.length)],
            top: _tops[next(_tops.length)],
            accent: _accents[next(_accents.length)],
            style: next(3),
            smile: next(3),
            accessory: next(3) == 0,
            earrings: next(4) != 0,
        );
    }

    final Color skin;
    final Color hair;
    final Color background;

    /// Shirt or blouse.
    final Color top;

    /// The krama's check, or the sbai's silk.
    final Color accent;

    final int style;
    final int smile;

    /// Glasses on a man, a rumdul in a woman's hair.
    final bool accessory;
    final bool earrings;

    // South-East Asian range, light tan to deep brown.
    static const List<Color> _skins = [
        Color(0xFFF1CBA5),
        Color(0xFFE2AE7E),
        Color(0xFFCF9563),
        Color(0xFFB57A4B),
        Color(0xFF8E5A35),
    ];
    // Mostly black, as it is on most heads in Phnom Penh.
    static const List<Color> _hairs = [
        Color(0xFF141010),
        Color(0xFF1E1614),
        Color(0xFF2B1B17),
        Color(0xFF3E2A20),
    ];
    // Soft enough that the red of the app bar and buttons stays the loudest thing on
    // the Me tab: saffron, lotus, jade, sky, sand, lavender.
    static const List<Color> _backgrounds = [
        Color(0xFFFFE9C2),
        Color(0xFFFFDDE4),
        Color(0xFFD8F0E0),
        Color(0xFFD9EAFB),
        Color(0xFFF1E4CF),
        Color(0xFFE7DDF6),
    ];
    static const List<Color> _tops = [
        Color(0xFFF7F4EE),
        Color(0xFF3F6FB5),
        Color(0xFF1F3A5F),
        Color(0xFF7A2E3A),
        Color(0xFF5E6B3A),
        Color(0xFF2E8B83),
    ];
    // Krama checks and sbai silks: red, royal blue, emerald, purple, saffron, magenta.
    static const List<Color> _accents = [
        Color(0xFFC62828),
        Color(0xFF1E4FA8),
        Color(0xFF1B7F4B),
        Color(0xFF6A2C91),
        Color(0xFFE08A00),
        Color(0xFFB0206A),
    ];
}
