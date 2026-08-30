import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/products/domain/usecases/product_usecases.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/usecases/inventory_usecases.dart';
import 'package:stock_count/modules/customers/directory/domain/usecases/customer_usecases.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/usecases/account_usecases.dart';
import 'package:stock_count/modules/accounting/journals/domain/usecases/journal_usecases.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/period_closing_service.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/entities/inventory_item.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/inventory/products/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/repositories/inventory_repository.dart';
import 'package:stock_count/modules/customers/directory/domain/repositories/customer_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/repositories/fiscal_year_repository.dart';

class DummyDenyingPermissionGuard implements PermissionGuard {
  const DummyDenyingPermissionGuard();

  @override
  void requireAny(Object codeOrCodes) {
    throw const PermissionDeniedException(['denied_permission']);
  }
}

class DummyAllowingPermissionGuard implements PermissionGuard {
  const DummyAllowingPermissionGuard();

  @override
  void requireAny(Object codeOrCodes) {}
}

class MockProductRepository implements ProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockInventoryRepository implements InventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCustomerRepository implements CustomerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAccountRepository implements AccountRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockJournalPostingService implements JournalPostingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFiscalYearRepository implements FiscalYearRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Security Fix 03: RBAC Mandatory PermissionGuard Tests', () {
    const denyingGuard = DummyDenyingPermissionGuard();
    const allowingGuard = DummyAllowingPermissionGuard();

    test('CreateProduct rejects unauthorized invocation before repo access', () async {
      final usecase = CreateProduct(
        MockProductRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(const ProductDraft(itemCode: 'P01', name: 'Test', packSize: 1, price: 10)),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('UpdateProduct rejects unauthorized invocation', () async {
      final usecase = UpdateProduct(
        MockProductRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(1, const ProductDraft(itemCode: 'P01', name: 'Test', packSize: 1, price: 10)),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('DeleteProduct rejects unauthorized invocation', () async {
      final usecase = DeleteProduct(
        MockProductRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(1),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('SaveInventoryCount rejects unauthorized invocation', () async {
      final usecase = SaveInventoryCount(
        MockInventoryRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(InventoryItem(itemCode: 'I01', itemName: 'Item 1', systemQuantity: 0)),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('CreateCustomer rejects unauthorized invocation', () async {
      final usecase = CreateCustomer(
        MockCustomerRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(const CustomerDraft(customerCode: 'C01', name: 'Cust')),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('SoftDeleteAccount rejects unauthorized invocation', () async {
      final usecase = SoftDeleteAccount(
        MockAccountRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(1),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('PostJournalEntry rejects unauthorized invocation', () async {
      final usecase = PostJournalEntry(
        MockJournalPostingService(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(JournalEntryDraft(
          entryDate: DateTime(2026, 8, 30),
          voucherNumber: 'JV-01',
          voucherType: 'JV',
          currencyCode: 'USD',
          lines: [],
        )),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('OpenAccountingPeriod rejects unauthorized invocation', () async {
      final usecase = OpenAccountingPeriod(
        MockFiscalYearRepository(),
        permissionGuard: denyingGuard,
      );

      expect(
        () => usecase.call(periodUuid: 'period-1', openedBy: 'user-1'),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Allowing guard permits execution path to reach repository', () async {
      final usecase = OpenAccountingPeriod(
        MockFiscalYearRepository(),
        permissionGuard: allowingGuard,
      );

      expect(
        () => usecase.call(periodUuid: 'period-1', openedBy: 'user-1'),
        throwsA(isA<NoSuchMethodError>()),
      );
    });
  });
}
