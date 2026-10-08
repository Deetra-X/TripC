import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Page backdrop with soft colour glows, so glass surfaces placed on top of
/// it have something to frost. Warm on ivory, faint teal on charcoal.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.background,
      child: Stack(
        children: [
          _Glow(
            alignment: const Alignment(-1.3, -1.05),
            size: 340,
            color: colors.glowPrimary,
          ),
          _Glow(
            alignment: const Alignment(1.4, -0.4),
            size: 280,
            color: colors.glowSecondary,
          ),
          _Glow(
            alignment: const Alignment(-1.2, 0.6),
            size: 300,
            color: colors.glowPrimary.withValues(
              alpha: colors.glowPrimary.a * 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
