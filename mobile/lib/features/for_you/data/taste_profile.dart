import 'package:flutter/widgets.dart';

import '../../map/data/attraction.dart';

/// What the user likes and what they've looked at, used to personalise
/// For You. Kept in memory for now; it moves to Supabase with the rest of
/// the user's data.
class TasteProfile extends ChangeNotifier {
  Set<InterestTag> _interests = {};
  final List<String> _recentlyViewed = [];

  static const _recentLimit = 10;

  Set<InterestTag> get interests => Set.unmodifiable(_interests);
  bool get hasInterests => _interests.isNotEmpty;

  /// Place ids, most recent first.
  List<String> get recentlyViewed => List.unmodifiable(_recentlyViewed);

  void setInterests(Set<InterestTag> interests) {
    _interests = {...interests};
    notifyListeners();
  }

  void viewed(String placeId) {
    _recentlyViewed
      ..remove(placeId)
      ..insert(0, placeId);
    if (_recentlyViewed.length > _recentLimit) _recentlyViewed.removeLast();
    notifyListeners();
  }

  void clearRecentlyViewed() {
    if (_recentlyViewed.isEmpty) return;
    _recentlyViewed.clear();
    notifyListeners();
  }
}

class TasteScope extends InheritedNotifier<TasteProfile> {
  const TasteScope({
    super.key,
    required TasteProfile profile,
    required super.child,
  }) : super(notifier: profile);

  /// The profile, rebuilding the caller when it changes.
  static TasteProfile of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TasteScope>()!.notifier!;

  /// The profile without rebuilding the caller, e.g. to record a view.
  static TasteProfile? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TasteScope>()?.notifier;
}
