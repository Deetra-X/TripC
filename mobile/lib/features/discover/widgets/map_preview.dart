import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/glass.dart';
import '../discover_data.dart';

// The map is an illustration that looks the same in light and dark, so the
// controls drawn on it use fixed palette colours rather than theme roles.

/// Where the user is on the preview map, as fractions of its size.
const _userPosition = Offset(0.42, 0.64);

/// Stylised map of the places around the user, with numbered pins.
class MapPreview extends StatefulWidget {
  const MapPreview({super.key, required this.places, required this.onOpenMap});

  final List<NearbyPlace> places;
  final VoidCallback onOpenMap;

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.places;
    return AspectRatio(
      aspectRatio: 1.85,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            Offset at(Offset fraction) =>
                Offset(fraction.dx * size.width, fraction.dy * size.height);

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      routeTo: places.isEmpty ? null : places.first.mapPosition,
                    ),
                  ),
                ),
                for (var i = 0; i < places.length; i++)
                  Positioned(
                    left: at(places[i].mapPosition).dx - 15,
                    top: at(places[i].mapPosition).dy - 36,
                    child: _Pin(number: i + 1, color: places[i].pinColor),
                  ),
                Positioned(
                  left: at(_userPosition).dx - 30,
                  top: at(_userPosition).dy - 30,
                  child: _UserDot(pulse: _pulse),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Glass(
                    borderRadius: BorderRadius.circular(999),
                    tint: AppPalette.paper,
                    opacity: 0.85,
                    blur: 10,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You · ${places.length} places nearby',
                          style: const TextStyle(
                            color: AppPalette.ink900,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Material(
                    color: AppPalette.ink900,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: widget.onOpenMap,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 17,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Open map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Teardrop map pin with its number.
class _Pin extends StatelessWidget {
  const _Pin({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's location: a blue dot with an expanding halo.
class _UserDot extends StatelessWidget {
  const _UserDot({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 60,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22 + 38 * t,
                height: 22 + 38 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6)
                      .withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x553B82F6), blurRadius: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({this.routeTo});

  /// The pin the dashed walking route leads to.
  final Offset? routeTo;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDDECD8),
    );

    final park = Paint()..color = const Color(0xFFCBE3C3);
    canvas.drawCircle(p(0.8, 0.22), h * 0.32, park);
    canvas.drawCircle(p(0.12, 0.2), h * 0.24, park);
    canvas.drawCircle(p(0.2, 0.92), h * 0.22, park);

    canvas.drawOval(
      Rect.fromCenter(center: p(0.56, 0.62), width: w * 0.2, height: h * 0.14),
      Paint()..color = const Color(0xFFA8D5E4),
    );

    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, 0)
        ..quadraticBezierTo(w * 0.4, h * 0.5, w * 0.22, h),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, 0)
        ..quadraticBezierTo(w * 0.58, h * 0.4, w, h * 0.34),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.55, h)
        ..quadraticBezierTo(w * 0.62, h * 0.7, w * 0.7, h * 0.5),
      road..strokeWidth = 5,
    );

    final mainRoad = Path()
      ..moveTo(0, h * 0.76)
      ..quadraticBezierTo(w * 0.5, h * 0.6, w, h * 0.7);
    canvas.drawPath(mainRoad, road..strokeWidth = 11);
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = const Color(0xFFF4D98B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    if (routeTo != null) {
      final start = p(_userPosition.dx, _userPosition.dy);
      final end = p(routeTo!.dx, routeTo!.dy);
      final dash = Paint()
        ..color = AppPalette.teal900
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      const segments = 7;
      for (var i = 0; i < segments; i++) {
        final a = Offset.lerp(start, end, i / segments)!;
        final b = Offset.lerp(start, end, (i + 0.5) / segments)!;
        canvas.drawLine(a, b, dash);
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => oldDelegate.routeTo != routeTo;
}
