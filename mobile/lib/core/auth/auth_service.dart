import 'package:flutter/widgets.dart';

class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tracks who is signed in.
///
/// Accounts are kept in memory only, so they are lost when the app restarts.
/// This stands in for a real auth backend until one is connected.
class AuthService extends ChangeNotifier {
  final _accounts = <String, ({String name, String password})>{};
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> signIn({required String email, required String password}) async {
    await _simulateNetwork();
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email or password.');
    }
    _currentUser = AuthUser(name: account.name, email: key);
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _simulateNetwork();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('An account with this email already exists.');
    }
    _accounts[key] = (name: name.trim(), password: password);
    _currentUser = AuthUser(name: name.trim(), email: key);
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _simulateNetwork() =>
      Future.delayed(const Duration(milliseconds: 600));
}

/// Makes the [AuthService] available to the widget tree and rebuilds
/// dependents when the signed-in user changes.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService auth, required super.child})
    : super(notifier: auth);

  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
