import '../../app/localization/app_localizations.dart';
import '../../modules/authentication/domain/models/password_change_exception.dart';

/// Password strength tier.
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong;

  double get score {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}

/// Result container for password validation operations.
class PasswordValidationResult {
  const PasswordValidationResult({
    required this.isValid,
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.generalError,
    this.strength = PasswordStrength.weak,
  });

  final bool isValid;
  final String? currentPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final String? generalError;
  final PasswordStrength strength;
}

/// Centralized password security rules & validation mechanism.
///
/// Reusable by Local Password Change, Server Password Change,
/// Admin User Creation, and Admin Password Management.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  /// Evaluates password complexity/strength rating.
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= minLength) score += 1;
    if (password.length >= 12) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    if (score <= 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// Validates a new password against security policies.
  static String? validateNewPassword(
    String? newPassword,
    AppLocalizations l10n, {
    String? currentPassword,
    String? defaultPassword,
  }) {
    if (newPassword == null || newPassword.trim().isEmpty) {
      return l10n.adminPasswordTooShort;
    }
    if (newPassword.length < minLength) {
      return l10n.adminPasswordTooShort;
    }
    if (currentPassword != null &&
        currentPassword.isNotEmpty &&
        newPassword == currentPassword) {
      return l10n.authPasswordSameAsDefault;
    }
    if (defaultPassword != null &&
        defaultPassword.isNotEmpty &&
        newPassword == defaultPassword) {
      return l10n.authPasswordSameAsDefault;
    }
    return null;
  }

  /// Validates password confirmation matching.
  static String? validateConfirmPassword(
    String? confirmPassword,
    String? newPassword,
    AppLocalizations l10n,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return l10n.authPasswordMismatch;
    }
    if (confirmPassword != newPassword) {
      return l10n.authPasswordMismatch;
    }
    return null;
  }

  /// Validates current password input.
  static String? validateCurrentPassword(
    String? currentPassword,
    AppLocalizations l10n,
  ) {
    if (currentPassword == null || currentPassword.isEmpty) {
      return l10n.authPasswordWrongCurrent;
    }
    return null;
  }

  /// Validates a complete password-change form.
  static PasswordValidationResult validateChangeForm({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required AppLocalizations l10n,
    String? defaultPassword,
  }) {
    final currentErr = validateCurrentPassword(currentPassword, l10n);
    final newErr = validateNewPassword(
      newPassword,
      l10n,
      currentPassword: currentPassword,
      defaultPassword: defaultPassword,
    );
    final confirmErr = validateConfirmPassword(
      confirmPassword,
      newPassword,
      l10n,
    );

    final isValid =
        currentErr == null && newErr == null && confirmErr == null;
    final strength = calculateStrength(newPassword);

    return PasswordValidationResult(
      isValid: isValid,
      currentPasswordError: currentErr,
      newPasswordError: newErr,
      confirmPasswordError: confirmErr,
      strength: strength,
    );
  }

  /// Maps a [PasswordChangeException] code to a localized message string.
  static String mapExceptionCode(AppLocalizations l10n, String code) {
    return switch (code) {
      PasswordChangeException.tooShort => l10n.adminPasswordTooShort,
      PasswordChangeException.wrongCurrent => l10n.authPasswordWrongCurrent,
      PasswordChangeException.sameAsDefault => l10n.authPasswordSameAsDefault,
      PasswordChangeException.mismatch => l10n.authPasswordMismatch,
      _ => l10n.authLoginGenericError,
    };
  }
}
