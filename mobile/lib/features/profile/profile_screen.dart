import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/user_avatar.dart';
import '../discover/widgets/section_header.dart';
import '../for_you/data/taste_profile.dart';
import '../for_you/widgets/interest_picker.dart';
import '../map/data/attraction.dart';
import '../saved/data/saved_places.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The user's profile: who they are, what they've saved and the travel
/// style that shapes their picks. Settings opens from the gear.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onOpenSaved});

  /// Goes to the Saved tab.
  final VoidCallback onOpenSaved;

  void _openSettings(BuildContext context) {
    final taste = TasteScope.maybeOf(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Settings sits above the tabs, so it gets the interests again.
        builder: (_) =>
            TasteScope(profile: taste, child: const SettingsScreen()),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
  }

  Future<void> _chooseInterests(
    BuildContext context,
    TasteProfile taste,
  ) async {
    final chosen = await showInterestPicker(context, taste.interests);
    if (chosen != null) taste.setInterests(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).currentUser!;
    final taste = TasteScope.of(context);
    final saved = SavedScope.of(context);
    final lists = saved.customLists().length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpace.lg, bottom: 120),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: _SettingsButton(onPressed: () => _openSettings(context)),
            ),
          ),
          _Identity(user: user, onEdit: () => _editProfile(context)),
          const SizedBox(height: AppSpace.xxl),
          _Stats(
            stats: [
              (saved.placeIds.length, 'Saved', onOpenSaved),
              (lists, lists == 1 ? 'List' : 'Lists', onOpenSaved),
              (
                taste.interests.length,
                'Interests',
                () => _chooseInterests(context, taste),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const _Divider(),
          _LinkRow(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () => _editProfile(context),
          ),
          const _Divider(),
          _LinkRow(
            icon: Icons.favorite_border_rounded,
            title: 'Saved places & lists',
            onTap: onOpenSaved,
          ),
          const _Divider(),
          const SizedBox(height: AppSpace.xxxl),
          SectionHeader(
            title: 'Travel style',
            subtitle: 'What your For You picks are ranked by',
            trailing: taste.hasInterests
                ? TextButton(
                    onPressed: () => _chooseInterests(context, taste),
                    child: const Text('Edit'),
                  )
                : null,
          ),
          const SizedBox(height: AppSpace.lg),
          _TravelStyle(
            interests: taste.interests,
            onChoose: () => _chooseInterests(context, taste),
          ),
        ],
      ),
    );
  }
}

/// The gear, which turns as it opens Settings.
class _SettingsButton extends StatefulWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      tooltip: 'Settings',
      style: IconButton.styleFrom(
        fixedSize: const Size.square(48),
        backgroundColor: colors.surfaceRaised,
        side: BorderSide(color: colors.hairline),
      ),
      onPressed: () {
        setState(() => _turns += 0.25);
        widget.onPressed();
      },
      icon: AnimatedRotation(
        turns: _turns,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.slow,
        curve: AppMotion.emphasized,
        child: Icon(Icons.settings_outlined, color: colors.textPrimary),
      ),
    );
  }
}

/// Picture, name, where they're from, since when, and about them.
class _Identity extends StatelessWidget {
  const _Identity({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final joined = user.joined;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: user.name,
            avatar: user.avatar,
            size: 96,
            border: Border.all(color: colors.hairline),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(user.name, style: context.text.displaySmall),
          const SizedBox(height: AppSpace.sm),
          if (user.home.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    user.home,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: onEdit,
              child: Text(
                "+ Add where you're from",
                style: context.text.labelLarge?.copyWith(color: colors.brand),
              ),
            ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Member since ${_months[joined.month - 1]} ${joined.year}',
            style: context.text.bodySmall,
          ),
          if (user.about.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(user.about, style: context.text.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Counts with a divider between, each opening where it counts.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final List<(int, String, VoidCallback)> stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: AppSpace.xl,
                  indent: AppSpace.sm,
                  endIndent: AppSpace.sm,
                  color: colors.hairline,
                ),
              // Each may shrink, so long labels or large text truncate.
              Flexible(
                child: Semantics(
                  button: true,
                  label: '${stats[i].$1} ${stats[i].$2}',
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('stat-${stats[i].$2}'),
                    onTap: stats[i].$3,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats[i].$1}',
                            maxLines: 1,
                            style: context.text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            stats[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 20,
    endIndent: 20,
    color: context.colors.hairline,
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: colors.textPrimary),
            const SizedBox(width: AppSpace.lg),
            Expanded(child: Text(title, style: context.text.titleMedium)),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// The user's interests as chips, or a prompt to choose some.
class _TravelStyle extends StatelessWidget {
  const _TravelStyle({required this.interests, required this.onChoose});

  final Set<InterestTag> interests;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (interests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Glass(
          opacity: 0.7,
          borderRadius: BorderRadius.circular(AppRadius.md),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: colors.accent),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      'Tell us what you love and your picks will follow.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              OutlinedButton(
                onPressed: onChoose,
                child: const Text('Choose interests'),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final tag in InterestTag.values.where(interests.contains))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tag.icon, size: 17, color: colors.brand),
                  const SizedBox(width: 6),
                  Text(
                    tag.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
