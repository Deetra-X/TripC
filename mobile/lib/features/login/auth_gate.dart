import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Shows the app's features to signed-in users and the login page to
/// everyone else. Rebuilds whenever the user logs in or out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScope.of(context).isSignedIn
        ? const HomeScreen()
        : const LoginScreen();
  }
}
