/// Failures when changing the local offline password.
class PasswordChangeException implements Exception {
  const PasswordChangeException(this.code);

  static const String tooShort = 'too_short';
  static const String mismatch = 'mismatch';
  static const String wrongCurrent = 'wrong_current';
  static const String sameAsDefault = 'same_as_default';
  static const String notFound = 'not_found';

  final String code;

  @override
  String toString() => 'PasswordChangeException($code)';
}
