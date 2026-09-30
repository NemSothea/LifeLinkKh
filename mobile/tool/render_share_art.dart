// Renders the two LifeLink KH banners from real widgets, so the Khmer is shaped by the
// same engine the app uses and the avatars are the app's own. Run from `mobile/`:
//
//   flutter test tool/render_share_art.dart
//
// Writes:
//   ../frontend/src/app/opengraph-image.png   1200×630 — link previews (Facebook, Telegram)
//   assets/branding/play-feature-graphic.png  1024×500 — Play Console store listing
//
// Both come out RGBA; the Play Console wants no alpha, so flatten that one afterwards
// (see assets/branding/README.md). Lives under tool/, not test/, so CI never rewrites it.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/avatar/domain/avatar_spec.dart';
import 'package:lifelink_kh/src/features/avatar/presentation/profile_avatar.dart';

const Color _red = Color(0xFFC62828);

Future<void> _loadFonts() async {
    Future<void> load(String family, List<String> files) async {
        final loader = FontLoader(family);
        for (final file in files) {
            loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
        }
        await loader.load();
    }

    final sdk = Platform.environment['FLUTTER_ROOT']!;
    await load('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
    await load('Inter', [
        'assets/google_fonts/Inter-Regular.ttf',
        'assets/google_fonts/Inter-SemiBold.ttf',
    ]);
    await load('KantumruyPro', ['assets/google_fonts/KantumruyPro-Regular.ttf']);
}

/// Angkor's five towers along the bottom, a shade darker than the red — the same motif
/// the avatars stand in front of.
class _TowersPainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()..color = Color.lerp(_red, Colors.black, 0.16)!;
        final path = Path();
        void tower(double x, double width, double height) {
            final base = size.height;
            final top = base - height;
            final shoulder = base - height * 0.45;
            path
                ..moveTo(x - width / 2, base)
                ..lineTo(x - width / 2, shoulder)
                ..quadraticBezierTo(x - width * 0.45, top + height * 0.15, x, top)
                ..quadraticBezierTo(x + width * 0.45, top + height * 0.15, x + width / 2, shoulder)
                ..lineTo(x + width / 2, base)
                ..close();
        }

        final w = size.width;
        final h = size.height;
        tower(w * 0.58, w * 0.07, h * 0.26);
        tower(w * 0.68, w * 0.08, h * 0.36);
        tower(w * 0.78, w * 0.09, h * 0.48);
        tower(w * 0.88, w * 0.08, h * 0.36);
        tower(w * 0.98, w * 0.07, h * 0.26);
        path.addRect(Rect.fromLTRB(w * 0.52, h * 0.94, w, h));
        canvas.drawPath(path, paint);
    }

    @override
    bool shouldRepaint(_TowersPainter oldDelegate) => false;
}

class _Banner extends StatelessWidget {
    const _Banner({required this.size});

    final Size size;

    @override
    Widget build(BuildContext context) {
        // Everything is sized off the height, so the 1024×500 and 1200×630 banners are
        // one layout.
        final u = size.height / 630;
        TextStyle style(double px, {FontWeight weight = FontWeight.w400, double alpha = 1}) =>
            TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: const ['KantumruyPro'],
                fontSize: px * u,
                fontWeight: weight,
                color: Colors.white.withValues(alpha: alpha),
                height: 1.35,
            );

        Widget avatar(AvatarSpec spec, double radius) => Container(
            padding: EdgeInsets.all(6 * u),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ProfileAvatar(spec: spec, radius: radius * u),
        );

        return SizedBox.fromSize(
            size: size,
            child: ColoredBox(
                color: _red,
                child: Stack(
                    children: [
                        Positioned.fill(child: CustomPaint(painter: _TowersPainter())),
                        // Three donors — a woman with a rumdul in her bun, a man in a krama,
                        // a woman in a sbai — standing in front of the towers.
                        Positioned(
                            right: size.width * 0.05,
                            top: size.height * 0.16,
                            child: SizedBox(
                                width: 430 * u,
                                height: 340 * u,
                                child: Stack(
                                    children: [
                                        Positioned(
                                            left: 0,
                                            top: 110 * u,
                                            child: avatar(
                                                AvatarSpec(
                                                    gender: AvatarGender.female,
                                                    seed: stableHash('s13'),
                                                ),
                                                80,
                                            ),
                                        ),
                                        Positioned(
                                            right: 0,
                                            top: 110 * u,
                                            child: avatar(
                                                AvatarSpec(
                                                    gender: AvatarGender.male,
                                                    seed: stableHash('s02'),
                                                ),
                                                80,
                                            ),
                                        ),
                                        Positioned(
                                            left: 110 * u,
                                            top: 0,
                                            child: avatar(
                                                AvatarSpec(
                                                    gender: AvatarGender.female,
                                                    seed: stableHash('s00'),
                                                ),
                                                98,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ),
                        Positioned(
                            left: 72 * u,
                            top: 0,
                            bottom: 0,
                            width: size.width * 0.52,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Container(
                                        width: 96 * u,
                                        height: 96 * u,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24 * u),
                                        ),
                                        child: Icon(Icons.bloodtype, color: _red, size: 60 * u),
                                    ),
                                    SizedBox(height: 28 * u),
                                    Text('LifeLink KH', style: style(76, weight: FontWeight.w600)),
                                    Text('ជីវិត', style: style(40, alpha: 0.85)),
                                    SizedBox(height: 18 * u),
                                    Text(
                                        // Broken by hand: Khmer has no spaces between words, so a soft wrap
                                        // lands mid-word.
                                        'ភ្ជាប់អ្នកបរិច្ចាគឈាមស្ម័គ្រចិត្ត\nជាមួយគ្រួសារដែលត្រូវការឈាមជាបន្ទាន់',
                                        style: style(27),
                                    ),
                                    SizedBox(height: 8 * u),
                                    Text(
                                        'Connecting voluntary blood donors with families who urgently need blood.',
                                        style: style(22, alpha: 0.85),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

Future<void> _render(WidgetTester tester, Size size, String out) async {
    final key = GlobalKey();
    tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
    await tester.pumpWidget(
        Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
                child: RepaintBoundary(key: key, child: _Banner(size: size)),
            ),
        ),
    );
    await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('$out  ${size.width.toInt()}×${size.height.toInt()}');
}

void main() {
    testWidgets('render share art', (tester) async {
        await tester.runAsync(_loadFonts);
        await _render(tester, const Size(1200, 630), '../frontend/src/app/opengraph-image.png');
        await _render(tester, const Size(1024, 500), 'assets/branding/play-feature-graphic.png');
        tester.view.reset();
    });
}
