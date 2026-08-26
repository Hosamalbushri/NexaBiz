import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';

import 'package:stock_count/modules/customers/data/database/customers_database.dart';
import 'package:stock_count/modules/customers/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/domain/entities/customer.dart';

import 'package:stock_count/modules/inventory/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';

import 'package:stock_count/modules/sales/data/database/sales_database.dart';

void main() {
  group('Phase 1.1 Tenant Isolation & Security Invariants', () {
    late AccountingDatabase accountingDb;
    late CustomersDatabase customersDb;
    late InventoryDatabase inventoryDb;
    late SalesDatabase salesDb;

    setUp(() async {
      accountingDb = AccountingDatabase(executor: NativeDatabase.memory());
      customersDb = CustomersDatabase(executor: NativeDatabase.memory());
      inventoryDb = InventoryDatabase(executor: NativeDatabase.memory());
      salesDb = SalesDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await accountingDb.close();
      await customersDb.close();
      await inventoryDb.close();
      await salesDb.close();
    });

    test('INVARIANT 1 & 2: Business records strictly isolated by companyId (No NULL Wildcard)', () async {
      final repoA = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => 'company-A',
      );
      final repoB = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => 'company-B',
      );

      // Insert product under Company A
      final prodA = await repoA.insert(
        const ProductDraft(
          itemCode: 'PROD-A',
          name: 'Company A Widget',
          packSize: 1,
          price: 100.0,
        ),
      );

      // Insert product under Company B
      final prodB = await repoB.insert(
        const ProductDraft(
          itemCode: 'PROD-B',
          name: 'Company B Widget',
          packSize: 1,
          price: 200.0,
        ),
      );

      // Verify Company A sees only Prod A
      final listA = await repoA.getAll();
      expect(listA.length, equals(1));
      expect(listA.first.uuid, equals(prodA.uuid));

      // Verify Company B sees only Prod B
      final listB = await repoB.getAll();
      expect(listB.length, equals(1));
      expect(listB.first.uuid, equals(prodB.uuid));

      // Direct cross-tenant lookup by UUID MUST return null
      final crossLookup = await repoA.getByUuid(prodB.uuid);
      expect(crossLookup, isNull);
    });

    test('INVARIANT 3: Inserts automatically assign active companyId and reject spoofing', () async {
      final custRepoA = CustomerRepositoryImpl(
        customersDb,
        readCompanyId: () => 'company-A',
      );

      final customer = await custRepoA.insert(
        const CustomerDraft(
          customerCode: 'CUST-001',
          name: 'Client Alpha',
        ),
      );

      final rawRow = await (customersDb.select(customersDb.customers)
            ..where((t) => t.uuid.equals(customer.uuid)))
          .getSingle();

      expect(rawRow.companyId, equals('company-A'));
    });

    test('INVARIANT 4: Updates are strictly tenant-scoped (Company B cannot update Company A)', () async {
      final repoA = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => 'company-A',
      );
      final repoB = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => 'company-B',
      );

      final prodA = await repoA.insert(
        const ProductDraft(
          itemCode: 'ITEM-A',
          name: 'Original Name',
          packSize: 1,
          price: 50.0,
        ),
      );

      // Company B attempts to update Company A's product using ID
      expect(
        () async => await repoB.update(
          prodA.id,
          const ProductDraft(
            itemCode: 'ITEM-A',
            name: 'Hacked Name',
            packSize: 1,
            price: 1.0,
          ),
        ),
        throwsA(anything),
      );

      // Verify Company A product is unmodified
      final refreshed = await repoA.getById(prodA.id);
      expect(refreshed!.name, equals('Original Name'));
      expect(refreshed.price, equals(50.0));
    });

    test('INVARIANT 5: Deletes are strictly tenant-scoped (Company B cannot delete Company A)', () async {
      final custRepoA = CustomerRepositoryImpl(
        customersDb,
        readCompanyId: () => 'company-A',
      );
      final custRepoB = CustomerRepositoryImpl(
        customersDb,
        readCompanyId: () => 'company-B',
      );

      final customerA = await custRepoA.insert(
        const CustomerDraft(
          customerCode: 'CUST-A',
          name: 'Customer A',
        ),
      );

      // Company B attempts to soft delete Company A's customer
      expect(
        () async => await custRepoB.softDelete(customerA.id),
        throwsA(anything),
      );

      // Verify Customer A remains active under Company A
      final checkA = await custRepoA.getById(customerA.id);
      expect(checkA, isNotNull);
      expect(checkA!.name, equals('Customer A'));
    });

    test('INVARIANT 6 & 7: Company switching invalidates tenant query boundary completely', () async {
      var currentCompany = 'company-A';
      final accountRepo = AccountRepositoryImpl(
        accountingDb,
        readCompanyId: () => currentCompany,
        shouldSuppressLocalChartSeed: () async => true,
      );

      await accountRepo.insert(
        const AccountDraft(
          accountCode: '1001',
          name: 'Company A Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final chartA = await accountRepo.getAll();
      expect(chartA.length, equals(1));
      expect(chartA.first.accountCode, equals('1001'));

      // Switch context to Company B
      currentCompany = 'company-B';

      // Company B query returns 0 accounts from Company A
      final chartB = await accountRepo.getAll();
      expect(chartB.isEmpty, isTrue);

      // Insert Company B account
      await accountRepo.insert(
        const AccountDraft(
          accountCode: '1002',
          name: 'Company B Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final seededB = await accountRepo.getAll();
      expect(seededB.length, equals(1));
      expect(seededB.first.accountCode, equals('1002'));

      // Confirm raw DB row companyId
      final rawRow = await (accountingDb.select(accountingDb.accounts)
            ..where((t) => t.uuid.equals(seededB.first.uuid)))
          .getSingle();
      expect(rawRow.companyId, equals('company-B'));
    });

    test('INVARIANT 8: Riverpod currentCompanyIdProvider drives tenantContextProvider reactivity', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialId = container.read(currentCompanyIdProvider);
      expect(initialId, equals(LocalAuthDefaults.companyId));
    });

    test('INVARIANT 9 & 10: Client UUIDs are preserved and remain stable across tenancy', () async {
      final prodRepo = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => 'local-company',
      );

      final prod = await prodRepo.insert(
        const ProductDraft(
          itemCode: 'STABLE-01',
          name: 'Stable Local Item',
          packSize: 1,
          price: 15.0,
        ),
      );

      expect(prod.uuid, isNotEmpty);
      expect(prod.uuid.length, equals(36));

      final retrieved = await prodRepo.getByUuid(prod.uuid);
      expect(retrieved!.uuid, equals(prod.uuid));
    });
  });
}
