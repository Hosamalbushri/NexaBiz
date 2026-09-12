import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';

class MockSessionContext implements SessionContextPort {
  MockSessionContext({
    this.currentCompanyId,
    this.activeCompanyId,
    this.companies = const [],
    this.isAuthenticated = true,
    this.userId = 'usr_123',
    this.deviceId = 'dev_123',
    this.isStandalone = false,
  });

  @override
  final String? currentCompanyId;

  @override
  final String? activeCompanyId;

  @override
  final List<CompanyInfo> companies;

  @override
  final bool isAuthenticated;

  @override
  final String? userId;

  @override
  final String? deviceId;

  @override
  final bool isStandalone;

  @override
  ScopeContext get scope {
    final String activeId = activeCompanyId?.trim() ?? currentCompanyId?.trim() ?? '';
    if (activeId.isNotEmpty) {
      return CompanyScope(activeId);
    }
    if (companies.length == 1) {
      return CompanyScope(companies.first.id.trim());
    }
    if (isStandalone && companies.isEmpty) {
      return const CompanyScope(kLegacyLocalCompanyId);
    }
    return const SystemScope();
  }
}

void main() {
  group('TenantContext & SessionContextPort Architectural Unit Tests', () {
    test('1. Unauthenticated session returns TenantContext.empty', () {
      final container = ProviderContainer(
        overrides: [
          sessionContextPortProvider.overrideWithValue(
            MockSessionContext(isAuthenticated: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext, equals(TenantContext.empty));
      expect(tenantContext.companyId, equals(''));
      expect(container.read(currentCompanyIdProvider), equals(''));
    });

    test('2. Authenticated session uses currentCompanyId when present', () {
      final container = ProviderContainer(
        overrides: [
          sessionContextPortProvider.overrideWithValue(
            MockSessionContext(
              currentCompanyId: 'comp_alpha',
              companies: [
                const CompanyInfo(id: 'comp_alpha', name: 'Alpha'),
                const CompanyInfo(id: 'comp_beta', name: 'Beta'),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext.companyId, equals('comp_alpha'));
      expect(container.read(currentCompanyIdProvider), equals('comp_alpha'));
      expect(tenantContext.hasActiveCompany, isTrue);
    });

    test('3. Single company context auto-selects single company (Fallback)', () {
      final container = ProviderContainer(
        overrides: [
          sessionContextPortProvider.overrideWithValue(
            MockSessionContext(
              currentCompanyId: null,
              activeCompanyId: null,
              companies: [const CompanyInfo(id: 'comp_solo', name: 'Solo Corp')],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext.companyId, equals('comp_solo'));
    });

    test('4. System scope with multiple companies resolves to empty company ID', () {
      final container = ProviderContainer(
        overrides: [
          sessionContextPortProvider.overrideWithValue(
            MockSessionContext(
              currentCompanyId: null,
              activeCompanyId: null,
              isStandalone: true,
              companies: [
                const CompanyInfo(id: 'comp_1', name: 'Comp 1'),
                const CompanyInfo(id: 'comp_2', name: 'Comp 2'),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tenantContext = container.read(tenantContextProvider);
      expect(tenantContext.companyId, equals(''));
      expect(tenantContext.isStandalone, isTrue);
    });
  });
}
