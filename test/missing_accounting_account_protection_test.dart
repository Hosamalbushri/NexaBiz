import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/missing_account_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late InventoryAccountingPosterImpl poster;
  late PostingCoordinatorImpl coordinator;
  late AccountMappingResolverImpl resolver;
  late AccountRepositoryImpl accountRepo;
  late Directory tempDir;

  const tenantId = 'tenant-account-protection-01';
  late String whId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('missing_acc_test_');
    Hive.init(tempDir.path);

    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();
    whId = generateUuidV4();

    poster = InventoryAccountingPosterImpl(
      accDb,
      readCompanyId: () => tenantId,
    );

    final costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    final postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => tenantId,
    );

    final stockValidationService = StockValidationServiceImpl(
      invDb,
      () => tenantId,
    );

    final dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => tenantId,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      postingEngine: postingEngine,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      accountingPoster: poster,
      readCompanyId: () => tenantId,
    );

    accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );

    resolver = AccountMappingResolverImpl(
      accountRepository: accountRepo,
      validationService: AccountValidationServiceImpl(accountRepo),
    );

    final warehouseRepo = WarehouseRepositoryImpl(
      invDb,
      null,
      () => tenantId,
    );

    await warehouseRepo.saveWarehouse(
      Warehouse(
        id: whId,
        code: 'WH-MAIN',
        name: 'Main Warehouse',
        companyId: tenantId,
      ),
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 35 — Missing Accounting Account Protection Tests', () {
    test('1. Missing inventoryAccount (1230) causes Stock Receipt posting failure without stock mutations', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final rcId = generateUuidV4();

      await invDb.into(invDb.products).insert(
        ProductsCompanion.insert(
          uuid: generateUuidV4(),
          itemCode: 'ITEM-NO-ACC-01',
          name: 'No Account Item 1',
          price: 100.0,
          packSize: 1,
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: rcId,
          receiptNumber: 'RC-MISSING-1230',
          receiptDate: now,
          createdAt: now,
          updatedAt: now,
          status: const drift.Value('draft'),
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: generateUuidV4(),
          movementUuid: rcId,
          movementType: 'receipt',
          itemCode: 'ITEM-NO-ACC-01',
          itemName: 'No Account Item 1',
          quantity: const drift.Value(10.0),
          unitCost: const drift.Value(50.0),
          totalCost: const drift.Value(500.0),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: rcId,
        documentNumber: 'RC-MISSING-1230',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      // Attempt posting -> Must throw MissingAccountException because 1230 (inventoryAccount) is missing
      expect(
        () => coordinator.post(document: docRef),
        throwsA(isA<MissingAccountException>()),
      );

      // Verify ZERO stock & cost layer side effects
      final receiptRow = await (invDb.select(invDb.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(rcId)))
          .getSingle();
      expect(receiptRow.status, equals('draft'));

      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers, isEmpty);

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries, isEmpty);
    });

    test('2. Missing cogsAccount (5100) causes Stock Issue posting failure without stock side effects', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Seed Account 1230 ONLY (no 5100!)
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: generateUuidV4(),
          accountCode: '1230',
          name: 'حساب المخزون',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.products).insert(
        ProductsCompanion.insert(
          uuid: generateUuidV4(),
          itemCode: 'ITEM-NO-COGS-01',
          name: 'No COGS Item',
          price: 200.0,
          packSize: 1,
          onHandQty: const drift.Value(0.0),
          createdAt: now,
          updatedAt: now,
          companyId: const drift.Value(tenantId),
        ),
      );

      // 1. Post a Stock Receipt first (succeeds because 1230 exists)
      final rcId = generateUuidV4();
      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: rcId,
          receiptNumber: 'RC-COGS-SEED',
          receiptDate: now,
          createdAt: now,
          updatedAt: now,
          status: const drift.Value('draft'),
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: generateUuidV4(),
          movementUuid: rcId,
          movementType: 'receipt',
          itemCode: 'ITEM-NO-COGS-01',
          itemName: 'No COGS Item',
          quantity: const drift.Value(10.0),
          unitCost: const drift.Value(100.0),
          totalCost: const drift.Value(1000.0),
        ),
      );

      final rcDocRef = InventoryDocumentRef(
        documentId: rcId,
        documentNumber: 'RC-COGS-SEED',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      final rcResult = await coordinator.post(document: rcDocRef);
      expect(rcResult, isA<PostSuccess>());

      // 2. Prepare Stock Issue for ITEM-NO-COGS-01
      final issueId = generateUuidV4();
      await invDb.into(invDb.stockIssues).insert(
        StockIssuesCompanion.insert(
          uuid: issueId,
          issueNumber: 'ISS-MISSING-5100',
          issueDate: now,
          warehouse: drift.Value(whId),
          createdAt: now,
          updatedAt: now,
          status: const drift.Value('draft'),
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: generateUuidV4(),
          movementUuid: issueId,
          movementType: 'issue',
          itemCode: 'ITEM-NO-COGS-01',
          itemName: 'No COGS Item',
          quantity: const drift.Value(5.0),
          unitCost: const drift.Value(100.0),
          totalCost: const drift.Value(500.0),
        ),
      );

      final issueDocRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-MISSING-5100',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      // Attempt posting -> Must throw MissingAccountException because 5100 (cogsAccount) is missing
      expect(
        () => coordinator.post(document: issueDocRef),
        throwsA(isA<MissingAccountException>()),
      );

      // Verify ZERO stock consumption side effects on failure
      final issueRow = await (invDb.select(invDb.stockIssues)
            ..where((tbl) => tbl.uuid.equals(issueId)))
          .getSingle();
      expect(issueRow.status, equals('draft'));

      final layer = await invDb.select(invDb.inventoryCostLayers).getSingle();
      expect(layer.remainingQty, equals(10.0)); // Unconsumed!

      final consumptions = await invDb.select(invDb.inventoryCostConsumptions).get();
      expect(consumptions, isEmpty);
    });

    test('3. AccountMappingResolver throws MissingAccountException when required roles are missing', () async {
      final mapping = await resolver.resolveForDocument(documentType: 'stock_receipt');

      expect(
        () => mapping.assertRequiredRoles([
          AccountRole.inventory,
          AccountRole.adjustment,
          AccountRole.fxGainLoss,
        ]),
        throwsA(isA<MissingAccountException>()),
      );
    });

    test('4. Selected account resolution fails when specified account is not found in tenant', () async {
      final nonExistentAccountUuid = generateUuidV4();

      expect(
        () => poster.postAccountingEntry(
          document: InventoryDocumentRef(
            documentId: '1',
            documentType: InventoryDocumentType.stockReceipt,
            documentNumber: 'RC-TEST-99',
            documentDate: DateTime.now(),
          ),
          totalAmount: 500.0,
          accountId: nonExistentAccountUuid,
        ),
        throwsA(isA<MissingAccountException>()),
      );

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries, isEmpty);
    });

    test('5. Complete Atomicity: Missing account prevents document posting with zero side effects', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final rcId = generateUuidV4();

      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: rcId,
          receiptNumber: 'RC-ATOMIC-01',
          receiptDate: now,
          createdAt: now,
          updatedAt: now,
          status: const drift.Value('draft'),
          companyId: const drift.Value(tenantId),
        ),
      );

      await invDb.into(invDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: generateUuidV4(),
          movementUuid: rcId,
          movementType: 'receipt',
          itemCode: 'ITEM-ATOMIC-01',
          itemName: 'Atomic Test Item',
          quantity: const drift.Value(20.0),
          unitCost: const drift.Value(15.0),
          totalCost: const drift.Value(300.0),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: rcId,
        documentNumber: 'RC-ATOMIC-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        warehouseId: whId,
      );

      try {
        await coordinator.post(document: docRef);
        fail('Expected MissingAccountException was not thrown');
      } catch (e) {
        expect(e, isA<MissingAccountException>());
      }

      // Assert complete atomicity
      final receiptRow = await (invDb.select(invDb.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(rcId)))
          .getSingle();
      expect(receiptRow.status, equals('draft'));

      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers, isEmpty);

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries, isEmpty);
    });
  });
}
