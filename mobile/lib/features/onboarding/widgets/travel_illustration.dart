import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

enum Landmark { bridge, stupa, rock }

const _shadow = [
  BoxShadow(color: Color(0x1F113B3A), blurRadius: 12, offset: Offset(0, 4)),
];

/// Flat-style Sri Lankan scene: a landmark framed in a circle, with a place
/// card, category thumbnails and clouds floating around it.
class TravelIllustration extends StatelessWidget {
  const TravelIllustration({
    super.key,
    required this.landmark,
    required this.place,
    required this.rating,
  });

  final Landmark landmark;
  final String place;
  final String rating;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _ScenePainter(landmark)),
              ),
              _at(s, 0.14, 0.13, _Cloud(size: s * 0.17)),
              _at(s, 0.36, 0.2, _Cloud(size: s * 0.11)),
              _at(s, 0.22, 0.83, _Cloud(size: s * 0.19)),
              _at(
                s,
                0.56,
                0.06,
                _Dot(size: s * 0.016, color: AppPalette.teal900),
              ),
              _at(
                s,
                0.08,
                0.6,
                _Dot(size: s * 0.022, color: AppPalette.teal400),
              ),
              _at(
                s,
                0.94,
                0.56,
                _Dot(size: s * 0.014, color: AppPalette.teal600),
              ),
              _at(s, 0.2, 0.36, _PlaceCard(place: place, rating: rating)),
              _at(
                s,
                0.86,
                0.3,
                _Thumbnail(size: s * 0.15, icon: Icons.beach_access),
              ),
              _at(
                s,
                0.79,
                0.79,
                _Thumbnail(size: s * 0.12, icon: Icons.forest),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Centres [child] on the point ([x], [y]), given as fractions of [s].
  static Widget _at(double s, double x, double y, Widget child) {
    return Positioned(
      left: x * s,
      top: y * s,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.cloud,
      size: size,
      color: Colors.white,
      shadows: const [
        Shadow(color: Color(0x1F113B3A), blurRadius: 10, offset: Offset(0, 3)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.rating});

  final String place;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: AppPalette.teal100,
            child: Icon(Icons.place, size: 16, color: AppPalette.teal700),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place,
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.ink900,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppPalette.teal600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating,
                    style: text.labelSmall?.copyWith(color: AppPalette.ink600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.teal400, AppPalette.teal700],
        ),
        boxShadow: _shadow,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.45),
    );
  }
}

/// Paints the circular scene on a 100 × 100 grid scaled to the circle.
class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.landmark);

  final Landmark landmark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final circle = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: s * 0.31,
    );
    final clip = Path()..addOval(circle);

    canvas.drawShadow(clip, AppPalette.teal900, 8, false);
    canvas.save();
    canvas.clipPath(clip);
    canvas.translate(circle.left, circle.top);
    canvas.scale(circle.width / 100);

    _paintBackdrop(canvas);
    switch (landmark) {
      case Landmark.bridge:
        _paintBridge(canvas);
      case Landmark.stupa:
        _paintStupa(canvas);
      case Landmark.rock:
        _paintRock(canvas);
    }
    _paintForeground(canvas);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    const sky = Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.teal100, Colors.white],
        ).createShader(sky),
    );
    canvas.drawCircle(const Offset(74, 24), 7, Paint()..color = Colors.white);

    for (final (peak, halfWidth) in const [
      (Offset(16, 36), 26.0),
      (Offset(52, 22), 30.0),
      (Offset(86, 34), 24.0),
    ]) {
      _twoTone(
        canvas,
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + halfWidth, 80)
          ..lineTo(peak.dx - halfWidth, 80)
          ..close(),
        AppPalette.teal400,
        AppPalette.teal600,
        splitX: peak.dx,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(0, 64)
        ..quadraticBezierTo(28, 56, 52, 64)
        ..quadraticBezierTo(76, 72, 100, 62)
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close(),
      Paint()..color = AppPalette.teal700,
    );
  }

  /// Nine Arch Bridge, Ella, with a train crossing.
  void _paintBridge(Canvas canvas) {
    const span = Rect.fromLTRB(-2, 57, 102, 100);
    canvas.drawRect(span, Paint()..color = AppPalette.teal700);

    final arches = Path();
    for (var i = 0; i < 5; i++) {
      final x = 10.0 + i * 20;
      arches
        ..addOval(Rect.fromCircle(center: Offset(x, 70), radius: 7))
        ..addRect(Rect.fromLTRB(x - 7, 70, x + 7, 100));
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(span), arches),
      Paint()..color = AppPalette.teal100,
    );

    final carriage = Paint()..color = AppPalette.teal900;
    final window = Paint()..color = AppPalette.teal100;
    for (var i = 0; i < 4; i++) {
      final left = 16.0 + i * 16.5;
      canvas.drawRRect(
        RRect.fromLTRBR(left, 49, left + 15, 57, const Radius.circular(2)),
        carriage,
      );
      for (var w = 0; w < 3; w++) {
        canvas.drawRect(
          Rect.fromLTWH(left + 2 + w * 4.2, 51, 2.6, 2.6),
          window,
        );
      }
    }
  }

  /// White dagoba in the style of Ruwanwelisaya, Anuradhapura.
  void _paintStupa(Canvas canvas) {
    const shade = AppPalette.teal100;
    canvas.drawRect(
      const Rect.fromLTRB(20, 72, 80, 78),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTRB(25, 67, 75, 72),
      Paint()..color = shade,
    );
    _twoTone(
      canvas,
      Path()
        ..addArc(
          Rect.fromCircle(center: const Offset(50, 67), radius: 21),
          math.pi,
          math.pi,
        )
        ..close(),
      Colors.white,
      shade,
      splitX: 50,
    );
    _twoTone(
      canvas,
      Path()..addRect(const Rect.fromLTRB(45, 40, 55, 47)),
      Colors.white,
      shade,
      splitX: 50,
    );
    _twoTone(
      canvas,
      Path()
        ..moveTo(46.5, 40)
        ..lineTo(53.5, 40)
        ..lineTo(50, 18)
        ..close(),
      Colors.white,
      shade,
      splitX: 50,
    );
  }

  /// Sigiriya rock fortress.
  void _paintRock(Canvas canvas) {
    final rock = Path()
      ..moveTo(26, 84)
      ..lineTo(31, 60)
      ..quadraticBezierTo(32, 42, 40, 38)
      ..lineTo(64, 36)
      ..quadraticBezierTo(72, 37, 72, 48)
      ..lineTo(76, 70)
      ..lineTo(80, 84)
      ..close();
    _twoTone(canvas, rock, AppPalette.teal800, AppPalette.teal900, splitX: 60);

    // Forest canopy on the flat summit.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 100, 41));
    canvas.drawPath(rock, Paint()..color = AppPalette.teal600);
    canvas.restore();
  }

  void _paintForeground(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 84)
        ..quadraticBezierTo(30, 76, 55, 85)
        ..quadraticBezierTo(80, 93, 100, 82)
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close(),
      Paint()..color = AppPalette.teal600,
    );
    _paintPine(canvas, const Offset(12, 88), 30);
    _paintPine(canvas, const Offset(25, 92), 20);
    _paintPine(canvas, const Offset(88, 86), 28);
  }

  void _paintPine(Canvas canvas, Offset base, double height) {
    final width = height * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 1, base.dy - height * 0.15, 2, height * 0.15),
      Paint()..color = AppPalette.teal900,
    );
    final tree = Path();
    for (var i = 0; i < 3; i++) {
      final top = base.dy - height + i * height * 0.25;
      final half = width / 2 * (0.6 + 0.2 * i);
      tree
        ..moveTo(base.dx, top)
        ..lineTo(base.dx + half, top + height * 0.4)
        ..lineTo(base.dx - half, top + height * 0.4)
        ..close();
    }
    _twoTone(
      canvas,
      tree,
      AppPalette.teal800,
      AppPalette.teal900,
      splitX: base.dx,
    );
  }

  /// Fills [path] with [light] left of [splitX] and [dark] to the right.
  void _twoTone(
    Canvas canvas,
    Path path,
    Color light,
    Color dark, {
    required double splitX,
  }) {
    canvas.drawPath(path, Paint()..color = light);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(splitX, 0, 100, 100));
    canvas.drawPath(path, Paint()..color = dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.landmark != landmark;
}
