import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';

/// One switch between day and night, drawn as the sky: the sun over warm
/// morning light, or the moon over a starry night. The knob slides across
/// and the sky changes with it.
class DayNightSwitch extends StatelessWidget {
  const DayNightSwitch({
    super.key,
    required this.night,
    required this.onChanged,
  });

  final bool night;
  final ValueChanged<bool> onChanged;

  static const _height = 64.0;
  static const _knob = 52.0;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.slow;
    const curve = AppMotion.emphasized;

    return Semantics(
      button: true,
      toggled: night,
      label: 'Night mode',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onChanged(!night),
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            gradient: LinearGradient(
              colors: night
                  ? const [Color(0xFF0D2130), AppPalette.teal900]
                  : const [Color(0xFFFBE6C4), Color(0xFFD3ECEE)],
            ),
            border: Border.all(
              color: night
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppPalette.ivory300,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                opacity: night ? 1 : 0,
                duration: duration,
                child: const CustomPaint(painter: _StarsPainter()),
              ),
              AnimatedOpacity(
                opacity: night ? 0 : 1,
                duration: duration,
                child: const _Clouds(),
              ),
              AnimatedAlign(
                duration: duration,
                curve: curve,
                alignment: night ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: AnimatedSwitcher(
                    duration: duration,
                    child: Text(
                      night ? 'NIGHT MODE' : 'DAY MODE',
                      key: ValueKey(night),
                      style: TextStyle(
                        color: night ? AppPalette.pearl100 : AppPalette.ink900,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: duration,
                curve: curve,
                alignment: night ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: night ? AppPalette.charcoal800 : AppPalette.paper,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: night ? 0.4 : 0.14,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                            turns: Tween<double>(
                              begin: -0.25,
                              end: 0,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: night
                          ? const _Moon(key: ValueKey('moon'))
                          : const Icon(
                              Icons.light_mode_rounded,
                              key: ValueKey('sun'),
                              size: 28,
                              color: AppPalette.champagne600,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Moon extends StatelessWidget {
  const _Moon({super.key});

  @override
  Widget build(BuildContext context) {
    // The star sits in the crescent's open side, clear of the moon.
    return const SizedBox.square(
      dimension: DayNightSwitch._knob,
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 15,
            child: Icon(
              Icons.dark_mode_rounded,
              size: 25,
              color: AppPalette.champagne300,
            ),
          ),
          Positioned(
            top: 9,
            right: 9,
            child: Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppPalette.champagne200,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two soft clouds drifting across the day sky, clear of the label.
class _Clouds extends StatelessWidget {
  const _Clouds();

  @override
  Widget build(BuildContext context) {
    final cloud = Colors.white.withValues(alpha: 0.85);
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0.18, -0.45),
          child: Icon(Icons.cloud_rounded, size: 22, color: cloud),
        ),
        Align(
          alignment: const Alignment(0.42, 0.5),
          child: Icon(Icons.cloud_rounded, size: 15, color: cloud),
        ),
      ],
    );
  }
}

/// Small stars scattered over the night sky, clear of the label.
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  // Fractions of the width and height, and a radius.
  static const _stars = [
    (0.24, 0.28, 1.4),
    (0.30, 0.70, 1.0),
    (0.37, 0.40, 0.8),
    (0.44, 0.22, 1.2),
    (0.50, 0.66, 1.5),
    (0.57, 0.36, 0.9),
    (0.70, 0.14, 0.8),
    (0.86, 0.86, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}
