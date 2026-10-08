import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';

/// Greeting, location, notifications, the headline and today's context.
class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    super.key,
    required this.firstName,
    required this.onNotifications,
  });

  final String firstName;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initial: firstName.isEmpty ? '?' : firstName[0]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Kandy, Sri Lanka',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _BellButton(onPressed: onNotifications),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Where should we\ntake you today?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassChip(
                icon: Icons.wb_sunny_outlined,
                iconColor: colors.accent,
                label: 'Sunny 29°C',
              ),
              GlassChip(
                icon: Icons.auto_awesome,
                iconColor: colors.brand,
                label: 'Great day for outdoors',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.teal600, AppPalette.teal900],
        ),
        border: Border.all(color: colors.surfaceRaised, width: 2),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        Glass(
          borderRadius: BorderRadius.circular(23),
          opacity: 0.75,
          child: SizedBox.square(
            dimension: 46,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: onPressed,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        Positioned(
          top: 11,
          right: 12,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: colors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surfaceRaised, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
