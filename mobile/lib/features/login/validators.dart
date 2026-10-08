final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Enter a password.';
  if (value.length < 8) return 'Use at least 8 characters.';
  return null;
}
