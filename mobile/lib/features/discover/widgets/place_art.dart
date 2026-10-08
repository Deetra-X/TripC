import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ArtFeature { none, rock, water }

/// Colours for a placeholder scene, shown until real photos are added.
class ArtStyle {
  const ArtStyle({
    required this.sky,
    required this.farHill,
    required this.nearHill,
    this.sun = const Color(0xFFFFF3D1),
    this.feature = ArtFeature.none,
  });

  final List<Color> sky;
  final Color farHill;
  final Color nearHill;
  final Color sun;
  final ArtFeature feature;

  static const highlands = ArtStyle(
    sky: [Color(0xFFBFE2D3), Color(0xFFEFF7F1)],
    farHill: Color(0xFF9FCDB6),
    nearHill: Color(0xFF4F9478),
  );
  static const sigiriya = ArtStyle(
    sky: [Color(0xFFBFE2D3), Color(0xFFEFF7F1)],
    farHill: Color(0xFFA3CFB9),
    nearHill: Color(0xFF3F8A68),
    feature: ArtFeature.rock,
  );
  static const coast = ArtStyle(
    sky: [Color(0xFFB6DCEF), Color(0xFFF6F2E3)],
    farHill: Color(0xFFA8D4C4),
    nearHill: Color(0xFF6AA78E),
    feature: ArtFeature.water,
  );
  static const sunset = ArtStyle(
    sky: [Color(0xFFF4C7A6), Color(0xFFFCEBDD)],
    farHill: Color(0xFFD8AE90),
    nearHill: Color(0xFF8F7458),
    sun: Color(0xFFFFE2BF),
  );
  static const forest = ArtStyle(
    sky: [Color(0xFFCDE6C2), Color(0xFFF2F8EC)],
    farHill: Color(0xFF8CBF89),
    nearHill: Color(0xFF3B7A5A),
  );
  static const dusk = ArtStyle(
    sky: [Color(0xFFBAC7EA), Color(0xFFEFEAF4)],
    farHill: Color(0xFF9EAAD0),
    nearHill: Color(0xFF5D6D9D),
  );
}

/// Flat landscape illustration that fills its box.
class PlaceArt extends StatelessWidget {
  const PlaceArt({super.key, required this.style});

  final ArtStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScenePainter(style),
      child: const SizedBox.expand(),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.style);

  final ArtStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style.sky,
        ).createShader(bounds),
    );

    final sun = Offset(w * 0.76, h * 0.26);
    final r = math.min(w, h) * 0.12;
    canvas.drawCircle(
      sun,
      r * 2.2,
      Paint()
        ..color = style.sun.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
    );
    canvas.drawCircle(sun, r, Paint()..color = style.sun);

    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.25, h * 0.46, w * 0.5, h * 0.58)
        ..quadraticBezierTo(w * 0.75, h * 0.7, w, h * 0.52)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = style.farHill,
    );

    if (style.feature == ArtFeature.rock) _paintRock(canvas, w, h);

    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.8)
        ..quadraticBezierTo(w * 0.35, h * 0.68, w * 0.62, h * 0.8)
        ..quadraticBezierTo(w * 0.85, h * 0.9, w, h * 0.78)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = style.nearHill,
    );

    if (style.feature == ArtFeature.water) _paintWater(canvas, w, h);
  }

  /// Sigiriya-style rock with a green summit and terraces.
  void _paintRock(Canvas canvas, double w, double h) {
    final rock = Path()
      ..moveTo(w * 0.24, h * 0.8)
      ..lineTo(w * 0.33, h * 0.36)
      ..quadraticBezierTo(w * 0.35, h * 0.3, w * 0.42, h * 0.29)
      ..lineTo(w * 0.62, h * 0.29)
      ..quadraticBezierTo(w * 0.68, h * 0.3, w * 0.69, h * 0.36)
      ..lineTo(w * 0.78, h * 0.8)
      ..close();
    canvas.drawPath(rock, Paint()..color = const Color(0xFF9A6A4C));

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(w * 0.56, 0, w, h));
    canvas.drawPath(rock, Paint()..color = const Color(0xFF7E5339));
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, h * 0.335));
    canvas.drawPath(rock, Paint()..color = const Color(0xFF3F8A68));
    canvas.restore();

    final ledge = Paint()
      ..color = const Color(0xFF6E4630)
      ..strokeWidth = math.max(1, h * 0.006);
    canvas.drawLine(
      Offset(w * 0.36, h * 0.47),
      Offset(w * 0.66, h * 0.47),
      ledge,
    );
    canvas.drawLine(
      Offset(w * 0.34, h * 0.56),
      Offset(w * 0.68, h * 0.56),
      ledge,
    );
  }

  void _paintWater(Canvas canvas, double w, double h) {
    final water = Rect.fromLTRB(0, h * 0.84, w, h);
    canvas.drawRect(
      water,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF86C9DB), Color(0xFF4E9DB8)],
        ).createShader(water),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = math.max(1, h * 0.008)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.18, h * 0.9),
      Offset(w * 0.34, h * 0.9),
      shine,
    );
    canvas.drawLine(
      Offset(w * 0.56, h * 0.94),
      Offset(w * 0.8, h * 0.94),
      shine,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => oldDelegate.style != style;
}
