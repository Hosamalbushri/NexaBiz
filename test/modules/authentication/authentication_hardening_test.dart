import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/password_validator.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  group('PasswordValidator Tests', () {
    test('calculateStrength categorizes password complexity correctly', () {
      expect(PasswordValidator.calculateStrength('short'), PasswordStrength.weak);
      expect(PasswordValidator.calculateStrength('admin1234'), PasswordStrength.medium);
      expect(PasswordValidator.calculateStrength('StrongP@ss1'), PasswordStrength.veryStrong);
      expect(PasswordValidator.calculateStrength('V3ryStr0ng!P@ssw0rd#2026'), PasswordStrength.veryStrong);
    });
  });

  group('AuthState State Machine Tests', () {
    test('AuthState reactive getters accurately reflect status', () {
      const initializingState = AuthState(status: AuthStatus.initializing);
      expect(initializingState.isAuthenticating, isTrue);
      expect(initializingState.isAuthenticated, isFalse);

      const authenticatingState = AuthState(status: AuthStatus.authenticating);
      expect(authenticatingState.isAuthenticating, isTrue);
      expect(authenticatingState.isAuthenticated, isFalse);

      const authenticatedState = AuthState(status: AuthStatus.authenticated);
      expect(authenticatedState.isAuthenticated, isTrue);
      expect(authenticatedState.isAuthenticating, isFalse);
    });
  });
}
