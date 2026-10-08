import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass.dart';
import '../discover/discover_screen.dart';
import 'widgets/glass_nav_bar.dart';

/// The signed-in app: tabs behind a floating glass navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = [
    GlassNavItem(icon: Icons.explore_outlined, label: 'Discover'),
    GlassNavItem(icon: Icons.map_outlined, label: 'Map'),
    GlassNavItem(icon: Icons.favorite_border_rounded, label: 'Saved'),
    GlassNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlayStyle,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AmbientBackground(),
            IndexedStack(
              index: _tab,
              children: const [
                DiscoverScreen(),
                _ComingSoonTab(icon: Icons.map_outlined, title: 'Map'),
                _ComingSoonTab(
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved places',
                ),
                _ProfileTab(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: GlassNavBar(
          items: _tabs,
          index: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Glass(
        opacity: 0.6,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xxxl,
          vertical: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colors.brand),
            const SizedBox(height: AppSpace.md),
            Text(title, style: context.text.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text('Coming soon', style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser!;
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          AppSpace.xxl,
          AppSpace.xxl,
          120,
        ),
        child: Glass(
          opacity: 0.6,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppPalette.teal700,
                child: Text(
                  user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(user.name, style: context.text.titleLarge),
              const SizedBox(height: 2),
              Text(user.email, style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 28),
              const _AppearanceSelector(),
              const SizedBox(height: AppSpace.xxl),
              FilledButton.icon(
                onPressed: auth.signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// System / Light / Dark choice for the whole app.
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: context.text.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        SegmentedButton<ThemeMode>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {controller.value},
          onSelectionChanged: (selection) => controller.value = selection.first,
        ),
      ],
    );
  }
}
