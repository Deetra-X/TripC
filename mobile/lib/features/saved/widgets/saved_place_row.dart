import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';
import '../../map/widgets/category_badge.dart';
import 'save_button.dart';

/// A saved or recently viewed place: what and where it is, its rating and,
/// with [note], e.g. the lists it's in. Tapping opens it on the map.
class SavedPlaceRow extends StatelessWidget {
  const SavedPlaceRow({
    super.key,
    required this.place,
    required this.onTap,
    this.note,
  });

  final Attraction place;
  final VoidCallback onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = place.rating;
    final onMap = place.location != null;
    final facts = [
      if (place.hiddenGem) 'Hidden gem',
      if (!onMap) 'Not on the map yet',
    ];

    return InkWell(
      onTap: onMap ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        child: Row(
          children: [
            CategoryBadge(category: place.category, size: 60),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      place.district,
                      place.category.label,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  if (rating != null || facts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (rating != null) ...[
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: colors.accent,
                              ),
                            ),
                            TextSpan(text: ' ${rating.toStringAsFixed(1)}'),
                            if (facts.isNotEmpty) const TextSpan(text: ' · '),
                          ],
                          TextSpan(text: facts.join(' · ')),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (note case final note?) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.brand,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SaveButton(place: place),
          ],
        ),
      ),
    );
  }
}
