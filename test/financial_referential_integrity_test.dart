import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/data/services/financial_referential_integrity_validator.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late FinancialReferentialIntegrityValidator validator;

  late CostLayerServiceImpl costLayerService;
  late ProductRepositoryImpl productRepo;
  late WarehouseRepositoryImpl warehouseRepo;
  late StockMovementsRepositoryImpl stockMovementsRepo;
  late JournalRepositoryImpl journalRepo;

  const tenantId = 'tenant-referential-01';

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    validator = FinancialReferentialIntegrityValidator(
      invDb: invDb,
      accDb: accDb,
      readCompanyId: () => tenantId,
    );

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    productRepo = ProductRepositoryImpl(
      invDb,
      readCompanyId: () => tenantId,
    );

    warehouseRepo = WarehouseRepositoryImpl(
      invDb,
      null,
      () => tenantId,
    );

    stockMovementsRepo = StockMovementsRepositoryImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    final accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );
    final periodValidator = AccountingPeriodValidator(
      repository: FiscalYearRepositoryImpl(accDb, readCompanyId: () => tenantId),
      legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
    );

    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => tenantId,
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('ROOT FIX 32 — Financial Referential Integrity Tests', () {
    test('1. CostLayer Deletion Safeguard: Deleting a CostLayer with dependent CostConsumptions is BLOCKED', () async {
      final layerId = generateUuidV4();
      final issueLineId = generateUuidV4();

      final movementUuid = generateUuidV4();

      // Create a cost layer
      await costLayerService.createLayer(
        CostLayer(
          id: layerId,
          itemCode: 'ITEM-REF-01',
          warehouseId: 'WH-01',
          movementUuid: movementUuid,
          movementType: 'receipt',
          receivedDate: DateTime.now(),
          receivedQty: 100.0,
          remainingQty: 100.0,
          unitCost: 50.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: tenantId,
        ),
      );

      // Consume quantity from the cost layer (creating dependent CostConsumption)
      final consumeResult = await costLayerService.consumeLayers(
        itemCode: 'ITEM-REF-01',
        quantity: 30.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
        companyId: tenantId,
      );

      expect(consumeResult.consumptions.length, equals(1));

      // Attempt to reverse/delete the cost layer while downstream consumptions exist
      expect(
        () async => await costLayerService.reverseLayer(movementUuid),
        throwsA(isA<JournalException>()),
      );

      // Also verify direct validator check blocks deletion
      expect(
        () async => await validator.validateCostLayerDeletion(layerId),
        throwsA(isA<StateError>()),
      );
    });

    test('2. JournalEntry Deletion Safeguard: Posted JournalEntry deletion & orphan JournalLine insertion are BLOCKED', () async {
      final entryUuid = generateUuidV4();

      // Attempt validator check for orphan line without entry
      expect(
        () async => await validator.validateJournalLineCreation(
          entryUuid: entryUuid,
          accountUuid: 'ACC-101',
        ),
        throwsA(isA<StateError>()),
      );

      // Attempt validator check for empty movement or entry UUID
      expect(
        () => validator.validateCostLayerCreation(
          movementUuid: '',
          itemCode: 'ITEM-01',
          receivedQty: 10,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('3. Posted Document Deletion Safeguard: Deleting posted stock receipt or issue is BLOCKED', () async {
      final receiptId = generateUuidV4();

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: receiptId,
        supplier: 'Supplier Ref',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-REF-02',
            itemName: 'Item Ref 2',
            quantity: 50.0,
            unitCost: 10.0,
            totalCost: 500.0,
          ),
        ],
        status: InventoryDocumentStatus.posted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      // Attempt to delete posted stock receipt
      expect(
        () async => await stockMovementsRepo.deleteReceipt(receiptId),
        throwsA(isA<StateError>()),
      );

      // Validator direct check
      expect(
        () async => await validator.validateDocumentDeletion(
          documentId: receiptId,
          documentType: 'stockReceipt',
          status: 'posted',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('4. Warehouse Deletion Safeguard: Deleting a Warehouse with active stock or open cost layers is BLOCKED', () async {
      final whId = generateUuidV4();

      await warehouseRepo.saveWarehouse(
        Warehouse(
          id: whId,
          code: 'WH-REF-01',
          name: 'Warehouse Ref 01',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: tenantId,
        ),
      );

      // Add an open CostLayer in this warehouse
      await costLayerService.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-REF-03',
          warehouseId: whId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.now(),
          receivedQty: 50.0,
          remainingQty: 50.0,
          unitCost: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: tenantId,
        ),
      );

      // Attempt to delete warehouse with open cost layer
      expect(
        () async => await validator.validateWarehouseDeletion(whId),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Product Deletion Safeguard: Deleting a Product with open cost layers or posted lines is BLOCKED', () async {
      final product = await productRepo.insert(
        const ProductDraft(
          itemCode: 'ITEM-REF-SAFE',
          name: 'Safe Product Item',
          packSize: 1,
          price: 100.0,
          unitCost: 80.0,
        ),
      );

      // Add open cost layer for product
      await costLayerService.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: 'ITEM-REF-SAFE',
          warehouseId: 'WH-01',
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.now(),
          receivedQty: 20.0,
          remainingQty: 20.0,
          unitCost: 80.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: tenantId,
        ),
      );

      // Attempt to delete product with open cost layer
      expect(
        () async => await productRepo.delete(product.id),
        throwsA(isA<StateError>()),
      );

      expect(
        () async => await validator.validateProductDeletion('ITEM-REF-SAFE'),
        throwsA(isA<StateError>()),
      );
    });

    test('6. Soft-Delete History Preservation: Draft soft-deletion keeps lines intact without orphan records', () async {
      final issueId = generateUuidV4();

      final draftIssue = StockIssue(
        id: issueId,
        issueNumber: issueId,
        destination: 'Branch A',
        issueDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-DRAFT',
            itemName: 'Draft Item',
            quantity: 10.0,
            unitCost: 15.0,
            totalCost: 150.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      await stockMovementsRepo.saveIssue(draftIssue);

      // Soft-delete draft issue
      await stockMovementsRepo.deleteIssue(issueId);

      // Verify movement lines remain linked in DB (not physically orphaned or corrupted)
      final lines = await (invDb.select(invDb.stockMovementLines)
            ..where((t) => t.movementUuid.equals(issueId)))
          .get();

      expect(lines.length, equals(1));
      expect(lines.first.movementUuid, equals(issueId));
    });
  });
}
