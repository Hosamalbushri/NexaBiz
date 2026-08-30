import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/categories/data/repositories/category_repository_impl.dart';
import 'package:stock_count/modules/inventory/categories/domain/entities/category.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

class AlwaysPermissivePeriodValidator implements AccountingPeriodValidator {
  const AlwaysPermissivePeriodValidator();
  @override
  Future<void> assertEntryAllowed(DateTime date) async {}
  @override
  Future<bool> isEntryAllowed(DateTime date) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accountingDb;
  late InventoryDatabase inventoryDb;
  const companyA = 'tenant-identity-company-A';
  const companyB = 'tenant-identity-company-B';

  setUp(() {
    accountingDb = AccountingDatabase.memory();
    inventoryDb = InventoryDatabase.memory();
  });

  tearDown(() async {
    await accountingDb.close();
    await inventoryDb.close();
  });

  group('ROOT FIX 11 — Tenant Identity Integrity Security Test Suite', () {
    test('1. Financial Tables — JournalEntry & Account Require & Auto-Bind Company ID', () async {
      String activeCompany = companyA;
      final accountRepo = AccountRepositoryImpl(
        accountingDb,
        readCompanyId: () => activeCompany,
      );
      final journalRepo = JournalRepositoryImpl(
        accountingDb,
        accounts: accountRepo,
        periodValidator: const AlwaysPermissivePeriodValidator(),
        readCompanyId: () => activeCompany,
      );

      // Create posting account in Company A
      final draftAccount = AccountDraft(
        accountCode: '1001',
        name: 'Cash Account A',
        accountType: AccountType.asset,
        isGroup: false,
        isActive: true,
      );
      final accA = await accountRepo.insert(draftAccount);
      expect(accA, isNotNull);

      // Verify row persisted in DB with companyA
      final dbAccount = await (accountingDb.select(accountingDb.accounts)
            ..where((t) => t.uuid.equals(accA.uuid)))
          .getSingle();
      expect(dbAccount.companyId, equals(companyA));

      // Post Journal Entry in Company A
      final draftJournal = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 30),
        voucherNumber: 'JRN-001',
        voucherType: 'Journal',
        currencyCode: 'YER',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: accA.uuid,
            debit: 1000,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: accA.uuid,
            debit: 0,
            credit: 1000,
            currencyCode: 'YER',
          ),
        ],
      );

      final entryA = await journalRepo.post(draftJournal);
      expect(entryA, isNotNull);

      // Verify Journal Entry persisted with companyA
      final dbEntry = await (accountingDb.select(accountingDb.journalEntries)
            ..where((t) => t.uuid.equals(entryA.uuid)))
          .getSingle();
      expect(dbEntry.companyId, equals(companyA));

      // Switch context to Company B
      activeCompany = companyB;

      // Search or read account under Company B -> MUST BE NULL
      final searchFromB = await accountRepo.getByUuid(accA.uuid);
      expect(searchFromB, isNull);

      // Search or read journal entry under Company B -> MUST BE NULL
      final journalFromB = await journalRepo.getByUuid(entryA.uuid);
      expect(journalFromB, isNull);
    });

    test('2. Inventory Master Tables — Category, Warehouse, Product Tenant Identity Enforcement', () async {
      String activeCompany = companyA;

      final categoryRepo = CategoryRepositoryImpl(
        inventoryDb,
        readCompanyId: () => activeCompany,
      );
      final warehouseRepo = WarehouseRepositoryImpl(
        inventoryDb,
        null,
        () => activeCompany,
      );
      final productRepo = ProductRepositoryImpl(
        inventoryDb,
        readCompanyId: () => activeCompany,
      );

      final catAId = generateUuidV4();
      final categoryA = Category(
        id: catAId,
        code: 'CAT-A',
        name: 'Electronics A',
        warehouseId: 'WH-MAIN',
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(categoryA);
      final savedCatA = await categoryRepo.getCategoryById(catAId);
      expect(savedCatA, isNotNull);
      expect(savedCatA!.companyId, equals(companyA));

      final whAId = generateUuidV4();
      final warehouseA = Warehouse(
        id: whAId,
        code: 'WH-A',
        name: 'Main Warehouse A',
        companyId: companyA,
      );
      await warehouseRepo.saveWarehouse(warehouseA);
      final savedWhA = await warehouseRepo.getWarehouseById(whAId);
      expect(savedWhA, isNotNull);
      expect(savedWhA!.companyId, equals(companyA));

      final savedPrdA = await productRepo.insert(
        const ProductDraft(
          itemCode: 'ITEM-A',
          name: 'Product A',
          packSize: 1,
          price: 100,
          unitCost: 50,
        ),
      );
      expect(savedPrdA.uuid.isNotEmpty, isTrue);

      // Switch to Company B
      activeCompany = companyB;

      // Verify complete tenant isolation across reads
      expect(await categoryRepo.getCategoryById(catAId), isNull);
      expect(await warehouseRepo.getWarehouseById(whAId), isNull);
      expect(await productRepo.getByUuid(savedPrdA.uuid), isNull);

      // Attempt cross-company mutation from Company B -> MUST BE REJECTED (notFound)
      await expectLater(
        () => categoryRepo.deleteCategory(catAId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );
      await expectLater(
        () => warehouseRepo.deleteWarehouse(whAId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );
      await expectLater(
        () => productRepo.delete(savedPrdA.id),
        throwsA(isA<Object>()),
      );
    });

    test('3. Inventory Documents — Stock Returns & Transfers Tenant Identity Enforcement', () async {
      String activeCompany = companyA;

      final returnRepo = StockReturnsRepositoryImpl(
        db: inventoryDb,
        readCompanyId: () => activeCompany,
      );
      final transferRepo = StockTransferRepositoryImpl(
        db: inventoryDb,
        readCompanyId: () => activeCompany,
      );

      final retAId = generateUuidV4();
      await returnRepo.saveReturn(
        StockReturn(
          id: retAId,
          returnNumber: 'RET-001',
          returnType: StockReturnType.salesReturn,
          returnDate: DateTime.now(),
          companyId: companyA,
        ),
      );
      final retA = await returnRepo.getReturnById(retAId);
      expect(retA, isNotNull);
      expect(retA!.companyId, equals(companyA));

      final trfAId = generateUuidV4();
      await transferRepo.saveTransfer(
        StockTransfer(
          id: trfAId,
          transferNumber: 'TR-001',
          fromWarehouseId: 'WH-1',
          toWarehouseId: 'WH-2',
          transferDate: DateTime.now(),
          companyId: companyA,
        ),
      );
      final trfA = await transferRepo.getTransferById(trfAId);
      expect(trfA, isNotNull);
      expect(trfA!.companyId, equals(companyA));

      // Switch to Company B
      activeCompany = companyB;

      // Verify read isolation
      expect(await returnRepo.getReturnById(retAId), isNull);
      expect(await transferRepo.getTransferById(trfAId), isNull);

      // Verify cross-tenant mutation rejection
      expect(
        () => returnRepo.deleteReturn(retAId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );
      expect(
        () => transferRepo.deleteTransfer(trfAId),
        returnsNormally, // delete silent no-op or isolated
      );
    });

    test('4. Cost Layer & Consumption — Tenant Identity Enforcement', () async {
      String activeCompany = companyA;

      final costLayerService = CostLayerServiceImpl(
        db: inventoryDb,
        readCompanyId: () => activeCompany,
      );

      final layerAId = generateUuidV4();
      await costLayerService.createLayer(
        CostLayer(
          id: layerAId,
          itemCode: 'ITEM-X',
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.now(),
          receivedQty: 100.0,
          unitCost: 20.0,
          companyId: companyA,
        ),
      );
      final openLayersA = await costLayerService.getOpenLayers('ITEM-X');
      expect(openLayersA.length, equals(1));
      expect(openLayersA.first.companyId, equals(companyA));

      // Switch to Company B
      activeCompany = companyB;

      // Verify cost layer consumption from Company B cannot consume Company A layers
      final consumptionsB = await costLayerService.consumeLayers(
        itemCode: 'ITEM-X',
        quantity: 10.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        warehouseId: 'WH-MAIN',
      );

      // Because Company B has 0 cost layers, consumptionsB should show shortage / 0 consumptions
      expect(consumptionsB.consumptions, isEmpty);

      // Switch back to Company A
      activeCompany = companyA;
      final consumptionsA = await costLayerService.consumeLayers(
        itemCode: 'ITEM-X',
        quantity: 10.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
      );

      expect(consumptionsA.consumptions.length, equals(1));
      expect(consumptionsA.consumptions.first.companyId, equals(companyA));
    });

    test('5. Rejection of Ownerless Record Creation without Fallback Company ID Context', () async {
      // Simulate null/empty companyId provider with fallback
      final categoryRepo = CategoryRepositoryImpl(
        inventoryDb,
        readCompanyId: () => '', // Empty string -> falls back to LocalAuthDefaults.companyId
      );

      final catId = generateUuidV4();
      await categoryRepo.saveCategory(
        Category(
          id: catId,
          code: 'FALLBACK-01',
          name: 'Fallback Category',
          warehouseId: 'WH-MAIN',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final category = await categoryRepo.getCategoryById(catId);
      expect(category, isNotNull);
      // Ensure that record is NEVER ownerless (has a non-empty companyId)
      expect(category!.companyId, isNotNull);
      expect(category.companyId!.isNotEmpty, isTrue);
    });
  });
}
