import 'package:flutter/material.dart';

import '../data/attraction.dart';

/// A category's icon on its colour, used in list rows and the destination
/// panel.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 44});

  final AttractionCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color,
            Color.lerp(category.color, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Icon(category.icon, color: Colors.white, size: size * 0.5),
    );
  }
}
