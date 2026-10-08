import 'package:flutter/widgets.dart';

import 'profile_avatar.dart';

class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    required this.joined,
    this.home = '',
    this.about = '',
    this.avatar = ProfileAvatar.initial,
  });

  final String name;
  final String email;
  final DateTime joined;

  /// Where the user is from, e.g. "Colombo, Sri Lanka". Empty if not given.
  final String home;

  /// A line about the user. Empty if not given.
  final String about;
  final ProfileAvatar avatar;

  AuthUser copyWith({
    String? name,
    String? email,
    String? home,
    String? about,
    ProfileAvatar? avatar,
  }) {
    return AuthUser(
      name: name ?? this.name,
      email: email ?? this.email,
      joined: joined,
      home: home ?? this.home,
      about: about ?? this.about,
      avatar: avatar ?? this.avatar,
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _Account {
  _Account(this.user, this.password);

  AuthUser user;
  String password;
}

/// Tracks who is signed in, and lets them change their profile and account.
///
/// Accounts are kept in memory only, so they are lost when the app restarts.
/// This stands in for a real auth backend until one is connected.
class AuthService extends ChangeNotifier {
  AuthService({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 600),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// How long each call takes, as if it went to a server.
  final Duration latency;

  /// By email, in lower case.
  final _accounts = <String, _Account>{};
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> signIn({required String email, required String password}) async {
    await _simulateNetwork();
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email or password.');
    }
    _currentUser = account.user;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _simulateNetwork();
    final key = _key(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException('An account with this email already exists.');
    }
    final user = AuthUser(name: name.trim(), email: key, joined: _clock());
    _accounts[key] = _Account(user, password);
    _currentUser = user;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String home,
    required String about,
    required ProfileAvatar avatar,
  }) async {
    await _simulateNetwork();
    final account = _signedInAccount();
    _save(
      account,
      account.user.copyWith(
        name: name.trim(),
        home: home.trim(),
        about: about.trim(),
        avatar: avatar,
      ),
    );
  }

  /// Moves the account to [email], once the user confirms their password.
  Future<void> changeEmail({
    required String email,
    required String password,
  }) async {
    await _simulateNetwork();
    final account = _signedInAccount();
    _checkPassword(account, password);
    final key = _key(email);
    if (key == account.user.email) {
      throw const AuthException('That is already your email.');
    }
    if (_accounts.containsKey(key)) {
      throw const AuthException('An account with this email already exists.');
    }
    _accounts
      ..remove(account.user.email)
      ..[key] = account;
    _save(account, account.user.copyWith(email: key));
  }

  Future<void> changePassword({
    required String current,
    required String newPassword,
  }) async {
    await _simulateNetwork();
    final account = _signedInAccount();
    _checkPassword(account, current);
    if (newPassword == current) {
      throw const AuthException(
        'Use a password different from your current one.',
      );
    }
    account.password = newPassword;
  }

  /// Deletes the signed-in user's account and signs them out.
  Future<void> deleteAccount({required String password}) async {
    await _simulateNetwork();
    final account = _signedInAccount();
    _checkPassword(account, password);
    _accounts.remove(account.user.email);
    signOut();
  }

  static String _key(String email) => email.trim().toLowerCase();

  _Account _signedInAccount() {
    final user = _currentUser;
    final account = user == null ? null : _accounts[user.email];
    if (account == null) throw const AuthException('Please log in again.');
    return account;
  }

  static void _checkPassword(_Account account, String password) {
    if (account.password != password) {
      throw const AuthException('Incorrect password.');
    }
  }

  void _save(_Account account, AuthUser user) {
    account.user = user;
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _simulateNetwork() => Future.delayed(latency);
}

/// Makes the [AuthService] available to the widget tree and rebuilds
/// dependents when the signed-in user changes.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService auth, required super.child})
    : super(notifier: auth);

  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;

  /// The service without rebuilding the caller, e.g. in a tap handler.
  static AuthService read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
