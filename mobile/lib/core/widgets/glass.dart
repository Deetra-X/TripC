import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/theme_context.dart';

/// Frosted-glass surface: blurs whatever is behind it, tints it and adds a
/// hairline highlight around the edge. Without a [tint] it uses the theme's
/// glass colour, so it adapts to light and dark.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tint,
    this.opacity = 0.55,
    this.blur = 16,
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color? tint;
  final double opacity;
  final double blur;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = tint ?? colors.glassTint;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: opacity),
                base.withValues(alpha: opacity * 0.6),
              ],
            ),
            border: Border.all(
              color: tint == null
                  ? colors.glassBorder
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Small glass pill with an optional leading icon, e.g. a rating or status.
/// [onImage] gives a dark chip with light text for use over photos, the same
/// in both themes.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.onImage = false,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final foreground = onImage ? Colors.white : context.colors.textPrimary;
    return Glass(
      borderRadius: BorderRadius.circular(999),
      tint: onImage ? AppPalette.charcoal900 : null,
      opacity: onImage ? 0.45 : 0.65,
      blur: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      // One Text (icon inlined) so the label can truncate when space is tight,
      // whether or not the parent bounds the width.
      child: Text.rich(
        TextSpan(
          children: [
            if (icon != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(icon, size: 15, color: iconColor ?? foreground),
                ),
              ),
            TextSpan(text: label),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
