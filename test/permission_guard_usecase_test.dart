import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/domain/usecases/account_usecases.dart';
import 'package:stock_count/modules/accounting/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/permissions/accounting_permissions.dart';
import 'package:stock_count/modules/sales/domain/usecases/sale_usecases.dart';
import 'package:stock_count/modules/sales/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/domain/services/sale_number_allocator_port.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';

class _DenyGuard implements PermissionGuard {
  @override
  void requireAny(Iterable<String> codes) {
    throw PermissionDeniedException(codes.toList());
  }
}

class _UnusedSaleRepo implements SaleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAccountRepo implements AccountRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAllocator implements SaleNumberAllocatorPort {
  @override
  Future<String> allocateNext() async => 'S-1';
}

void main() {
  group('PermissionGuard', () {
    test('CallbackPermissionGuard denies missing codes', () {
      final guard = CallbackPermissionGuard((codes) => false);
      expect(
        () => guard.requireAny(['sales.create']),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('CallbackPermissionGuard allows when predicate matches', () {
      final guard = CallbackPermissionGuard(
        (codes) => codes.contains('sales.create'),
      );
      guard.requireAny(['sales.create', 'sales.documents.create']);
    });

    test('AllowAllPermissionGuard never throws', () {
      const AllowAllPermissionGuard().requireAny(['anything']);
    });
  });

  group('Use case domain authorization', () {
    test('CreateSale denies without sales create permission', () async {
      final useCase = CreateSale(
        repository: _UnusedSaleRepo(),
        numberAllocator: _UnusedAllocator(),
        permissionGuard: _DenyGuard(),
      );
      await expectLater(
        useCase(
          SaleDraft(
            saleDate: DateTime.utc(2026, 8, 1),
            settlementType: SaleSettlementType.cash,
            currencyCode: 'YER',
            baseCurrencyCode: 'YER',
            exchangeRate: 1,
            items: const [],
          ),
        ),
        throwsA(
          isA<PermissionDeniedException>().having(
            (e) => e.requiredAny,
            'requiredAny',
            SalesPermissions.create,
          ),
        ),
      );
    });

    test('SoftDeleteAccount denies without accounts.delete', () {
      final useCase = SoftDeleteAccount(_UnusedAccountRepo(), _DenyGuard());
      expect(
        () => useCase(1),
        throwsA(
          isA<PermissionDeniedException>().having(
            (e) => e.requiredAny,
            'requiredAny',
            AccountingPermissions.accountsDelete,
          ),
        ),
      );
    });
  });
}
