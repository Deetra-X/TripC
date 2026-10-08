import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/auth/profile_avatar.dart';

Future<AuthService> _signedUp() async {
  final auth = AuthService(
    clock: () => DateTime(2026, 10, 8),
    latency: Duration.zero,
  );
  await auth.signUp(
    name: ' Nimal Perera ',
    email: 'Nimal@Example.com',
    password: 'secret123',
  );
  return auth;
}

Matcher _fails(String message) =>
    throwsA(isA<AuthException>().having((e) => e.message, 'message', message));

void main() {
  test('sign up records who joined and when', () async {
    final auth = await _signedUp();
    final user = auth.currentUser!;
    expect(user.name, 'Nimal Perera');
    expect(user.email, 'nimal@example.com');
    expect(user.joined, DateTime(2026, 10, 8));
    expect(user.home, isEmpty);
    expect(user.avatar, ProfileAvatar.initial);
  });

  test('the profile can be changed and is kept for the next sign in', () async {
    final auth = await _signedUp();
    var changes = 0;
    auth.addListener(() => changes++);

    await auth.updateProfile(
      name: ' Nimal Silva ',
      home: ' Galle, Sri Lanka ',
      about: ' Always chasing waterfalls. ',
      avatar: ProfileAvatar.hiker,
    );
    expect(changes, 1);

    auth.signOut();
    await auth.signIn(email: 'nimal@example.com', password: 'secret123');
    final user = auth.currentUser!;
    expect(user.name, 'Nimal Silva');
    expect(user.home, 'Galle, Sri Lanka');
    expect(user.about, 'Always chasing waterfalls.');
    expect(user.avatar, ProfileAvatar.hiker);
    expect(user.joined, DateTime(2026, 10, 8));
  });

  group('changing the email', () {
    test('needs the password and a free, new address', () async {
      final auth = await _signedUp();
      await auth.signUp(
        name: 'Kamala',
        email: 'kamala@example.com',
        password: 'secret456',
      );
      auth.signOut();
      await auth.signIn(email: 'nimal@example.com', password: 'secret123');

      await expectLater(
        auth.changeEmail(email: 'new@example.com', password: 'wrong'),
        _fails('Incorrect password.'),
      );
      await expectLater(
        auth.changeEmail(email: ' NIMAL@example.com', password: 'secret123'),
        _fails('That is already your email.'),
      );
      await expectLater(
        auth.changeEmail(email: 'kamala@example.com', password: 'secret123'),
        _fails('An account with this email already exists.'),
      );
    });

    test('moves the account to the new address', () async {
      final auth = await _signedUp();
      await auth.changeEmail(email: 'New@Example.com', password: 'secret123');
      expect(auth.currentUser!.email, 'new@example.com');

      auth.signOut();
      await expectLater(
        auth.signIn(email: 'nimal@example.com', password: 'secret123'),
        _fails('Incorrect email or password.'),
      );
      await auth.signIn(email: 'new@example.com', password: 'secret123');
      expect(auth.currentUser!.name, 'Nimal Perera');
    });
  });

  test('changing the password checks the current one', () async {
    final auth = await _signedUp();
    await expectLater(
      auth.changePassword(current: 'wrong', newPassword: 'newsecret1'),
      _fails('Incorrect password.'),
    );
    await expectLater(
      auth.changePassword(current: 'secret123', newPassword: 'secret123'),
      _fails('Use a password different from your current one.'),
    );

    await auth.changePassword(current: 'secret123', newPassword: 'newsecret1');
    auth.signOut();
    await expectLater(
      auth.signIn(email: 'nimal@example.com', password: 'secret123'),
      _fails('Incorrect email or password.'),
    );
    await auth.signIn(email: 'nimal@example.com', password: 'newsecret1');
    expect(auth.isSignedIn, isTrue);
  });

  test('deleting the account needs the password and frees the email', () async {
    final auth = await _signedUp();
    await expectLater(
      auth.deleteAccount(password: 'wrong'),
      _fails('Incorrect password.'),
    );
    expect(auth.isSignedIn, isTrue);

    await auth.deleteAccount(password: 'secret123');
    expect(auth.isSignedIn, isFalse);
    await expectLater(
      auth.signIn(email: 'nimal@example.com', password: 'secret123'),
      _fails('Incorrect email or password.'),
    );
    await auth.signUp(
      name: 'Nimal',
      email: 'nimal@example.com',
      password: 'another1',
    );
    expect(auth.isSignedIn, isTrue);
  });

  test('account changes need someone signed in', () async {
    final auth = AuthService(latency: Duration.zero);
    await expectLater(
      auth.updateProfile(
        name: 'X',
        home: '',
        about: '',
        avatar: ProfileAvatar.initial,
      ),
      _fails('Please log in again.'),
    );
  });
}
