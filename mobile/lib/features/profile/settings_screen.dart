import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/user_avatar.dart';
import '../for_you/context/weather_service.dart';
import '../for_you/data/taste_profile.dart';
import '../for_you/widgets/interest_picker.dart';
import '../login/widgets/password_field.dart';
import '../map/data/attraction.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'widgets/day_night_switch.dart';
import 'widgets/settings_group.dart';

/// Day or night, the user's profile and interests, their account, and
/// where TripC's data comes from.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// The user as last shown, so the page still has them while it closes
  /// after they log out or delete their account.
  AuthUser? _user;

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _chooseInterests(
    BuildContext context,
    TasteProfile taste,
  ) async {
    final chosen = await showInterestPicker(context, taste.interests);
    if (chosen != null) taste.setInterests(chosen);
  }

  /// Closes the app's pages first, so nothing is left showing a signed-out
  /// user.
  static void _logOut(BuildContext context) {
    final auth = AuthScope.read(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    auth.signOut();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = AuthScope.read(context);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(auth: auth),
    );
    if (deleted == true && context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user = AuthScope.of(context).currentUser ?? _user;
    if (user == null) return const Scaffold();
    final taste = TasteScope.of(context);
    final theme = ThemeScope.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text('Settings', style: context.text.titleLarge)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          AppSpace.sm,
          20,
          AppSpace.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _ProfileCard(
            user: user,
            onTap: () => _open(context, const EditProfileScreen()),
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: DayNightSwitch(
                  night: night,
                  onChanged: (night) =>
                      theme.value = night ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
              SettingsTile(
                icon: Icons.brightness_auto_outlined,
                title: 'Match my phone',
                subtitle: 'Switch between day and night with your device',
                onTap: () => theme.value = theme.value == ThemeMode.system
                    ? (night ? ThemeMode.dark : ThemeMode.light)
                    : ThemeMode.system,
                trailing: Switch(
                  value: theme.value == ThemeMode.system,
                  onChanged: (on) => theme.value = on
                      ? ThemeMode.system
                      : (night ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            title: 'Profile',
            children: [
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit profile',
                subtitle: "Picture, name, where you're from and about you",
                onTap: () => _open(context, const EditProfileScreen()),
              ),
              SettingsTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Travel interests',
                subtitle: taste.hasInterests
                    ? InterestTag.values
                          .where(taste.interests.contains)
                          .map((tag) => tag.label)
                          .join(' · ')
                    : 'Choose what you love, for better picks',
                onTap: () => _chooseInterests(context, taste),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            title: 'Account',
            children: [
              SettingsTile(
                icon: Icons.alternate_email_rounded,
                title: 'Email',
                subtitle: user.email,
                onTap: () => _open(context, const ChangeEmailScreen()),
              ),
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Password',
                subtitle: 'Change your password',
                onTap: () => _open(context, const ChangePasswordScreen()),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Data sources & licences',
                subtitle: 'OpenStreetMap, OSRM, Open-Meteo and more',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'TripC',
                  applicationLegalese:
                      'Map data © OpenStreetMap contributors. Routes by '
                      'OSRM. ${OpenMeteoWeatherService.attribution} '
                      '(CC BY 4.0).',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xxxl),
          OutlinedButton.icon(
            onPressed: () => _logOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            onPressed: () => _deleteAccount(context),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onTap});

  final AuthUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              UserAvatar(name: user.name, avatar: user.avatar, size: 56),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deletes the account once the user enters their password. Returns true
/// once it's deleted, or null if the user cancels.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.auth});

  final AuthService auth;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_checking || !_form.currentState!.validate()) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.auth.deleteAccount(password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = _error;
    return AlertDialog(
      backgroundColor: colors.surfaceRaised,
      title: const Text('Delete your account?'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This deletes your account and logs you out. Enter your '
              'password to confirm.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpace.lg),
            PasswordField(
              controller: _password,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirm(),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Enter your password.'
                  : null,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpace.md),
              Text(error, style: TextStyle(color: colors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.danger),
          onPressed: _checking ? null : _confirm,
          child: _checking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
