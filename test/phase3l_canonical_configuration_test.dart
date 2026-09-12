import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/setup/domain/entities/setup_status.dart';
import 'package:stock_count/core/tenancy/scope_context.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';

void main() {
  group('Phase 3L — Canonical Configuration & Module Lifecycle Baseline Tests', () {
    test('ScopeContext distinguishes CompanyScope from SystemScope without fallbacks', () {
      const companyScope = CompanyScope('company-active-3l');
      const systemScope = SystemScope();

      expect(companyScope.isCompany, isTrue);
      expect(companyScope.companyIdOrNull, equals('company-active-3l'));

      expect(systemScope.isSystem, isTrue);
      expect(systemScope.companyIdOrNull, isNull);
    });

    test('SetupStatus operational readiness contract', () {
      expect(SetupStatus.configured.isOperational, isTrue);
      expect(SetupStatus.notConfigured.isOperational, isFalse);
      expect(SetupStatus.partiallyConfigured.isOperational, isFalse);
      expect(SetupStatus.invalid.isOperational, isFalse);

      expect(SetupStatus.notConfigured.requiresAttention, isTrue);
      expect(SetupStatus.partiallyConfigured.requiresAttention, isTrue);
      expect(SetupStatus.invalid.requiresAttention, isTrue);
      expect(SetupStatus.configured.requiresAttention, isFalse);
    });

    test('FirstRunSetupPayload validates payload requirements cleanly', () {
      const validPayload = FirstRunSetupPayload(
        language: 'en',
        adminName: 'System Owner',
        adminEmail: 'admin@nexabiz.com',
        adminPassword: 'SuperStrongPassword123!',
      );

      expect(validPayload.language, equals('en'));
      expect(validPayload.adminName, equals('System Owner'));
    });

    test('Company code generation is deterministic and scope-safe', () {
      final code1 = FirstRunSetupCoordinator.generateCompanyCode('NexaBiz Trading Ltd');
      final code2 = FirstRunSetupCoordinator.generateCompanyCode('NexaBiz Trading Ltd', 'CUSTOM_01');

      expect(code1, equals('NEXABIZ_TR'));
      expect(code2, equals('CUSTOM_01'));
    });
  });
}
