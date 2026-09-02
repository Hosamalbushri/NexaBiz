import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';

void main() {
  group('Company Context Invariants & Fail-Closed Tests', () {
    const resolver = CompanyContextResolver();

    final validContext = AuthorizationContext(
      userId: 'user-1',
      companyId: 'comp-100',
      permissions: const {'read', 'write'},
      roleId: 'role-owner',
      entitlement: Entitlement.freeLocal('comp-100'),
      authenticationMode: AuthenticationMode.local,
    );

    test('CompanyContextResolver throws MissingCompanyContextException when context is null', () {
      expect(
        () => resolver.resolveActiveCompanyId(context: null),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('CompanyContextResolver throws MissingCompanyContextException when context companyId is empty', () {
      final emptyCompContext = AuthorizationContext(
        userId: 'user-1',
        companyId: '',
        permissions: const {},
        roleId: 'role-owner',
        entitlement: Entitlement.freeLocal(''),
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => resolver.resolveActiveCompanyId(context: emptyCompContext),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('CompanyContextResolver returns companyId when valid', () {
      final cid = resolver.resolveActiveCompanyId(context: validContext);
      expect(cid, equals('comp-100'));
    });

    test('CompanyContextResolver throws CompanyContextMismatchException when requested companyId differs', () {
      expect(
        () => resolver.resolveActiveCompanyId(
          context: validContext,
          requestedCompanyId: 'comp-200',
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('TenantContext validates hasActiveCompany state', () {
      expect(TenantContext.empty.hasActiveCompany, isFalse);
      const activeTenant = TenantContext(companyId: 'comp-100');
      expect(activeTenant.hasActiveCompany, isTrue);
    });

    test('MissingCompanyContextException string representation contains message', () {
      const exception = MissingCompanyContextException('No company context available.');
      expect(
        exception.toString(),
        contains('MissingCompanyContextException: No company context available.'),
      );
    });
  });
}
