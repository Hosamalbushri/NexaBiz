import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_master_data_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late CanonicalMasterDataRepositoryImpl repo;

  const companyA = 'c1111111-1111-4111-8111-111111111111';
  const companyB = 'c2222222-2222-4222-8222-222222222222';

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    repo = CanonicalMasterDataRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3C Canonical Master Data Foundation Test Suite', () {
    test('1. Currencies — Create, read and company/global scope isolation', () async {
      await repo.createCurrency(
        CurrenciesCompanion.insert(
          currencyCode: 'SAR',
          name: 'Saudi Riyal',
          symbol: 'SR',
          isBase: const Value(true),
        ),
      );

      await repo.createCurrency(
        CurrenciesCompanion.insert(
          currencyCode: 'USD',
          name: 'US Dollar',
          symbol: '\$',
          companyId: const Value(companyA),
        ),
      );

      final globalCurrencies = await repo.getCurrencies(null);
      expect(globalCurrencies.length, equals(1));
      expect(globalCurrencies.first.currencyCode, equals('SAR'));

      final companyACurrencies = await repo.getCurrencies(companyA);
      expect(companyACurrencies.length, equals(2));

      final companyBCurrencies = await repo.getCurrencies(companyB);
      expect(companyBCurrencies.length, equals(1)); // Only global SAR visible
    });

    test('2. Product Categories — Tree hierarchy & Tenant Isolation', () async {
      final rootA = await repo.createCategory(
        ProductProductCategoriesCompanion.insert(
          code: 'CAT_ROOT_A',
          name: 'Electronics A',
          companyId: companyA,
        ),
      );

      final childA = await repo.createCategory(
        ProductProductCategoriesCompanion.insert(
          code: 'CAT_SUB_A',
          name: 'Smartphones A',
          parentUuid: Value(rootA.uuid),
          companyId: companyA,
        ),
      );

      expect(childA.parentUuid, equals(rootA.uuid));

      // Company B cannot see Company A categories
      final categoriesB = await repo.getCategories(companyB);
      expect(categoriesB, isEmpty);

      // Company B referencing Company A category as parent fails
      expect(
        () async => repo.createCategory(
          ProductProductCategoriesCompanion.insert(
            code: 'CAT_B_INVALID',
            name: 'Invalid Subcategory',
            parentUuid: Value(rootA.uuid), // Parent from Company A
            companyId: companyB,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('3. Warehouses — Creation & Tenant Isolation', () async {
      final whA = await repo.createWarehouse(
        WarehousesCompanion.insert(
          code: 'WH_MAIN_A',
          name: 'Main Warehouse A',
          companyId: companyA,
        ),
      );

      expect(whA.code, equals('WH_MAIN_A'));

      final warehousesA = await repo.getWarehouses(companyA);
      expect(warehousesA.length, equals(1));

      final warehousesB = await repo.getWarehouses(companyB);
      expect(warehousesB, isEmpty);
    });

    test('4. Accounts (CoA) — Tree hierarchy & Tenant Isolation', () async {
      final parentAccount = await repo.createAccount(
        AccountsCompanion.insert(
          accountCode: '1100',
          name: 'Cash and Cash Equivalents',
          accountType: 'asset',
          normalBalance: 'debit',
          isGroup: const Value(true),
          companyId: companyA,
        ),
      );

      final subAccount = await repo.createAccount(
        AccountsCompanion.insert(
          accountCode: '1101',
          name: 'Main Cash Box',
          accountType: 'asset',
          normalBalance: 'debit',
          parentUuid: Value(parentAccount.uuid),
          companyId: companyA,
        ),
      );

      expect(subAccount.parentUuid, equals(parentAccount.uuid));

      // Duplicate account code within company A fails
      expect(
        () async => repo.createAccount(
          AccountsCompanion.insert(
            accountCode: '1100', // Duplicate code
            name: 'Duplicate Cash Account',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: companyA,
          ),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('5. Products — Category FK relationship & Tenant Isolation', () async {
      final categoryA = await repo.createCategory(
        ProductProductCategoriesCompanion.insert(
          code: 'CAT_PROD',
          name: 'Hardware',
          companyId: companyA,
        ),
      );

      final productA = await repo.createProduct(
        ProductsCompanion.insert(
          itemCode: 'SKU_001',
          name: 'Laptop X1',
          price: const Value(1200.0),
          categoryUuid: Value(categoryA.uuid),
          companyId: companyA,
        ),
      );

      expect(productA.itemCode, equals('SKU_001'));
      expect(productA.categoryUuid, equals(categoryA.uuid));

      // Product referencing another company's category fails FK validation
      expect(
        () async => repo.createProduct(
          ProductsCompanion.insert(
            itemCode: 'SKU_B01',
            name: 'Laptop B',
            categoryUuid: Value(categoryA.uuid), // Category belongs to Company A
            companyId: companyB,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6. Customers — Account FK relationship & Tenant Isolation', () async {
      final arAccountA = await repo.createAccount(
        AccountsCompanion.insert(
          accountCode: '1200',
          name: 'Accounts Receivable A',
          accountType: 'asset',
          normalBalance: 'debit',
          companyId: companyA,
        ),
      );

      final customerA = await repo.createCustomer(
        CustomersCompanion.insert(
          customerCode: 'CUST_001',
          name: 'Global Trading Co.',
          accountId: Value(arAccountA.uuid),
          companyId: companyA,
        ),
      );

      expect(customerA.accountId, equals(arAccountA.uuid));

      // Customer referencing another company's account fails FK validation
      expect(
        () async => repo.createCustomer(
          CustomersCompanion.insert(
            customerCode: 'CUST_B01',
            name: 'Stranger Client',
            accountId: Value(arAccountA.uuid), // Account belongs to Company A
            companyId: companyB,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('7. Cash Registers & Voucher Books — Creation & Tenant Isolation', () async {
      final cashAccount = await repo.createAccount(
        AccountsCompanion.insert(
          accountCode: '1102',
          name: 'Register Cash Box',
          accountType: 'asset',
          normalBalance: 'debit',
          companyId: companyA,
        ),
      );

      final registerA = await repo.createCashRegister(
        CashRegistersCompanion.insert(
          code: 'REG_01',
          name: 'Front Counter Cashier',
          accountId: Value(cashAccount.uuid),
          companyId: companyA,
        ),
      );

      expect(registerA.code, equals('REG_01'));

      final vbA = await repo.createVoucherBook(
        VoucherBooksCompanion.insert(
          name: 'Sales Invoices 2026',
          bookType: 'sales_invoice',
          companyId: companyA,
        ),
      );

      expect(vbA.bookType, equals('sales_invoice'));

      // Company B isolated check
      expect(await repo.getCashRegisters(companyB), isEmpty);
      expect(await repo.getVoucherBooks(companyB), isEmpty);
    });

    test('8. Strict Tenancy Enforcement — Missing companyId fails explicitly', () async {
      expect(
        () async => repo.createWarehouse(
          WarehousesCompanion.insert(
            code: 'NO_COMPANY_WH',
            name: 'No Company Warehouse',
            companyId: '', // Empty string companyId
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
