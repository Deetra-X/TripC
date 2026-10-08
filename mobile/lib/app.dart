import 'package:flutter/material.dart';

import 'core/auth/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/onboarding/onboarding_screen.dart';

class TripCApp extends StatelessWidget {
  const TripCApp({super.key, required this.auth, required this.themeMode});

  final AuthService auth;
  final ThemeController themeMode;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: ThemeScope(
        controller: themeMode,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) => MaterialApp(
            title: 'TripC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );
  }
}
