import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';

class TestSessionContextAdapter implements SessionContextPort {
  TestSessionContextAdapter({
    this.currentCompanyId,
    this.activeCompanyId,
    this.companies = const [],
    this.isAuthenticated = true,
    this.userId = 'usr-001',
    this.deviceId = 'dev-001',
    this.isStandalone = false,
    ScopeContext? scope,
  }) : overrideScope = scope;

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

  final ScopeContext? overrideScope;

  @override
  ScopeContext get scope {
    if (overrideScope != null) return overrideScope!;
    final activeId = activeCompanyId?.trim() ?? currentCompanyId?.trim() ?? '';
    if (activeId.isNotEmpty) return CompanyScope(activeId);
    if (isStandalone) return const SystemScope();
    return const SystemScope();
  }
}

void main() {
  group('Phase 1: Session Authority & Tenant Scope Contract Tests', () {
    const activeCompanyId = 'company-alpha-123';
    const targetCompanyId = 'company-alpha-123';
    const foreignCompanyId = 'company-beta-999';

    test('SessionContextPort exposes active company scope correctly', () {
      final adapter = TestSessionContextAdapter(
        activeCompanyId: activeCompanyId,
        currentCompanyId: activeCompanyId,
      );

      expect(adapter.isAuthenticated, isTrue);
      expect(adapter.activeCompanyId, equals(activeCompanyId));
      expect(adapter.scope, equals(const CompanyScope(activeCompanyId)));
      expect(adapter.scope.isCompany, isTrue);
      expect(adapter.scope.isSystem, isFalse);
    });

    test('TenantContext derives CompanyScope when companyId is present', () {
      final context = TenantContext(
        companyId: activeCompanyId,
        userId: 'usr-1',
      );

      expect(context.hasActiveCompany, isTrue);
      expect(context.isCompanyScope, isTrue);
      expect(context.scope, equals(const CompanyScope(activeCompanyId)));
    });

    test('TenantContext empty resolves to SystemScope', () {
      const context = TenantContext.empty;

      expect(context.hasActiveCompany, isFalse);
      expect(context.isSystemScope, isTrue);
      expect(context.scope, equals(const SystemScope()));
    });

    test('MultiTenantRepositoryGuard permits valid matching companyId', () {
      final result = MultiTenantRepositoryGuard.enforceCompanyContext(
        companyId: targetCompanyId,
        activeCompanyId: activeCompanyId,
      );

      expect(result, equals(activeCompanyId));
    });

    test(
        'MultiTenantRepositoryGuard throws MissingCompanyContextException when target companyId is empty',
        () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: '',
          activeCompanyId: activeCompanyId,
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test(
        'MultiTenantRepositoryGuard throws MissingCompanyContextException when activeCompanyId is null',
        () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: targetCompanyId,
          activeCompanyId: null,
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test(
        'MultiTenantRepositoryGuard throws CompanyContextMismatchException when target company differs',
        () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: foreignCompanyId,
          activeCompanyId: activeCompanyId,
        ),
        throwsA(
          isA<CompanyContextMismatchException>().having(
            (e) => e.expectedCompanyId,
            'expectedCompanyId',
            activeCompanyId,
          ),
        ),
      );
    });

    test('MultiTenantRepositoryGuard.enforceScopeContext handles SystemScope',
        () {
      final context = TenantContext(companyId: activeCompanyId);
      final result = MultiTenantRepositoryGuard.enforceScopeContext(
        tenantContext: context,
        targetScope: const SystemScope(),
      );

      expect(result, null);
    });

    test(
        'MultiTenantRepositoryGuard.enforceScopeContext handles CompanyScope matching',
        () {
      final context = TenantContext(companyId: activeCompanyId);
      final result = MultiTenantRepositoryGuard.enforceScopeContext(
        tenantContext: context,
        targetScope: const CompanyScope(activeCompanyId),
      );

      expect(result, equals(activeCompanyId));
    });

    test(
        'MultiTenantRepositoryGuard.enforceScopeContext rejects CompanyScope mismatch',
        () {
      final context = TenantContext(companyId: activeCompanyId);

      expect(
        () => MultiTenantRepositoryGuard.enforceScopeContext(
          tenantContext: context,
          targetScope: const CompanyScope(foreignCompanyId),
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });
  });
}
