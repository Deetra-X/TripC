import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';
import '../discover_data.dart';
import 'place_art.dart';

/// A stack of recommendation cards. The front card shows one pick and the
/// next two peek out behind it; swipe or tap "Next pick" to move through.
class RecommendationDeck extends StatefulWidget {
  const RecommendationDeck({
    super.key,
    required this.items,
    required this.onView,
  });

  final List<Recommendation> items;
  final ValueChanged<Recommendation> onView;

  @override
  State<RecommendationDeck> createState() => _RecommendationDeckState();
}

class _RecommendationDeckState extends State<RecommendationDeck> {
  final _saved = <String>{};
  int _index = 0;

  void _step(int delta) {
    final count = widget.items.length;
    if (count < 2) return;
    setState(() => _index = (_index + delta) % count);
  }

  void _toggleSaved(String name) {
    setState(
      () => _saved.contains(name) ? _saved.remove(name) : _saved.add(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Glass(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No picks in this category yet.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }

    final current = items[_index];
    return Column(
      children: [
        SizedBox(
          height: 380,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200) _step(1);
                if (velocity > 200) _step(-1);
              },
              child: Stack(
                children: [
                  for (final depth in const [2, 1])
                    if (depth < items.length)
                      Positioned(
                        top: depth * 16.0,
                        bottom: depth * 16.0,
                        left: 48,
                        right: 28 - depth * 14.0,
                        child: _BackCard(
                          art: items[(_index + depth) % items.length].art,
                          depth: depth,
                        ),
                      ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: items.length > 1 ? 28 : 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.94,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: _FrontCard(
                        key: ValueKey(current.name),
                        item: current,
                        saved: _saved.contains(current.name),
                        onToggleSaved: () => _toggleSaved(current.name),
                        onView: () => widget.onView(current),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _Dots(count: items.length, index: _index),
              const Spacer(),
              if (items.length > 1) _NextPickButton(onPressed: () => _step(1)),
            ],
          ),
        ),
      ],
    );
  }
}

const _cardRadius = BorderRadius.all(Radius.circular(32));

class _FrontCard extends StatelessWidget {
  const _FrontCard({
    super.key,
    required this.item,
    required this.saved,
    required this.onToggleSaved,
    required this.onView,
  });

  final Recommendation item;
  final bool saved;
  final VoidCallback onToggleSaved;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _cardRadius,
        boxShadow: [
          ...AppShadows.raised(colors),
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _cardRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlaceArt(style: item.art),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1],
                  colors: [Colors.transparent, Color(0x40111314)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GlassChip(
                    icon: Icons.star_rounded,
                    iconColor: colors.accent,
                    label: item.rating.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GlassChip(
                        icon: Icons.auto_awesome,
                        iconColor: AppPalette.champagne200,
                        label: '${item.match}% match',
                        onImage: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Glass(
                    borderRadius: BorderRadius.circular(22),
                    opacity: 0.7,
                    child: SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        tooltip: saved ? 'Remove from saved' : 'Save',
                        onPressed: onToggleSaved,
                        icon: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: colors.danger,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Glass(
                borderRadius: BorderRadius.circular(24),
                tint: AppPalette.charcoal900,
                opacity: 0.5,
                blur: 18,
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppPalette.champagne200,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.champagne200,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${item.region} · ${item.travelTime}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _PillButton(
                          label: 'View',
                          icon: Icons.north_east_rounded,
                          onPressed: onView,
                          background: AppPalette.paper,
                          foreground: AppPalette.ink900,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  border: Border.all(color: colors.glassBorder, width: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A washed-out card peeking from behind the front card.
class _BackCard extends StatelessWidget {
  const _BackCard({required this.art, required this.depth});

  final ArtStyle art;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _cardRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlaceArt(style: art),
          ColoredBox(
            color: context.colors.background.withValues(
              alpha: 0.25 + depth * 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: AppMotion.standard,
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 26 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? colors.textPrimary
                  : colors.textPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (i == index)
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NextPickButton extends StatelessWidget {
  const _NextPickButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.hairline),
        boxShadow: AppShadows.soft(colors),
      ),
      child: _PillButton(
        label: 'Next pick',
        icon: Icons.arrow_forward_rounded,
        onPressed: onPressed,
        background: colors.surfaceRaised.withValues(alpha: 0.9),
        foreground: colors.textPrimary,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
