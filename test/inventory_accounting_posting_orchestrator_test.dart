import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase inventoryDb;
  late NexabizDatabase accountingDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late PostingCoordinatorImpl postingCoordinator;
  late DocumentPostingOrchestrator orchestrator;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orch_test_');
    Hive.init(tempDir.path);

    inventoryDb = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();

    await inventoryDb.into(inventoryDb.warehouses).insert(
      WarehousesCompanion.insert(
        id: const Value('00000000-0000-4000-8000-000000000001'),
        code: '00000000-0000-4000-8000-000000000001',
        name: 'Main Warehouse',
        companyId: 'COMP-TEST',
      ),
    );

    accountRepo = AccountRepositoryImpl(
      accountingDb,
      readCompanyId: () => 'COMP-TEST',
    );
    await accountRepo.seedDefaultChart();
    await accountRepo.ensureDefaultChartSeeded();

    final validator = legacyPeriodValidator();

    journalRepo = JournalRepositoryImpl(
      accountingDb,
      accounts: accountRepo,
      periodValidator: validator,
      readCompanyId: () => 'COMP-TEST',
    );

    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: validator,
    );

    final validationService = StockValidationServiceImpl(inventoryDb, () => 'COMP-TEST');
    final dependencyDetector = InventoryDependencyDetectorImpl(inventoryDb, () => 'COMP-TEST');
    final costLayerService = CostLayerServiceImpl(
      db: inventoryDb,
      readCompanyId: () => 'COMP-TEST',
    );
    final postingEngine = PostingEngineImpl(
      inventoryDb,
      costLayerService,
      null,
      () => 'COMP-TEST',
    );

    final rateRepo = CurrencyRateRepositoryImpl(
      accountingDb,
      readCompanyId: () => 'COMP-TEST',
    );
    final journalBuilder = JournalBuilderImpl(
      accountRepository: accountRepo,
      currencyRateRepository: rateRepo,
      readCompanyId: () => 'COMP-TEST',
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: inventoryDb,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: InventoryAccountingPosterAdapter(
        journalPostingService,
        journalBuilder: journalBuilder,
        readCompanyId: () => 'COMP-TEST',
      ),
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => 'COMP-TEST',
    );

    final accValidationService = AccountValidationServiceImpl(accountRepo);
    final mappingResolver = AccountMappingResolverImpl(
      accountRepository: accountRepo,
      validationService: accValidationService,
    );

    final entryBuilder = AccountingEntryBuilder(
      mappingResolver: mappingResolver,
      validationService: accValidationService,
    );

    orchestrator = DocumentPostingOrchestrator(
      postingCoordinator: postingCoordinator,
      journalPostingService: journalPostingService,
      entryBuilder: entryBuilder,
    );
  });

  tearDown(() async {
    await inventoryDb.close();
    await accountingDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Unified Posting Engine & Direct Unpost Journal Deletion', () {
    test(
      'posting receipt creates 1 journal entry and updates inventory status',
      () async {
        final receiptId = generateUuidV4();
        final lineId = generateUuidV4();
        final now = DateTime.now().millisecondsSinceEpoch;

        final receipt = StockReceipt(
          id: receiptId,
          receiptNumber: 'REC-1001',
          receiptDate: DateTime.utc(2026, 8, 28),
          warehouse: '00000000-0000-4000-8000-000000000001',
          supplier: null,
          lines: [
            StockMovementLine(
              id: lineId,
              movementUuid: receiptId,
              movementType: 'receipt',
              itemCode: 'ITEM-A',
              itemName: 'Item A',
              quantity: 10,
              unitCost: 100,
              totalCost: 1000,
            ),
          ],
        );

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(lineId),
                receiptId: Value(receiptId),
                movementType: 'receipt',
                itemCode: 'ITEM-A',
                itemName: 'Item A',
                quantity: const Value(10.0),
                unitCost: const Value(100.0),
                totalCost: const Value(1000.0),
                companyId: 'COMP-TEST',
              ),
            );

        await inventoryDb
            .into(inventoryDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(receiptId),
                receiptNumber: 'REC-1001',
                receiptDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
                warehouse: const Value('00000000-0000-4000-8000-000000000001'),
                currencyCode: 'SAR',
                status: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: const Value('COMP-TEST'),
              ),
            );

        final result = await orchestrator.postStockReceiptData(
          data: receipt.toPostingData(),
        );
        if (result is OrchestrationFailure) {
          fail('postStockReceiptData failed: ${result.reason}');
        }
        expect(result, isA<OrchestrationSuccess>());

        final journalEntry = await journalRepo.findBySource(
          sourceType: 'stock_receipt',
          sourceId: receiptId,
        );
        expect(journalEntry, isNotNull);
        expect(journalEntry!.voucherNumber, 'REC-1001');
        expect(journalEntry.isPosted, isTrue);

        final allEntries = await journalRepo.listHeaders();
        expect(allEntries.length, 1);
      },
    );

    test(
      'unposting receipt deletes journal entry directly instead of reversal entry',
      () async {
        final receiptId = generateUuidV4();
        final lineId = generateUuidV4();
        final now = DateTime.now().millisecondsSinceEpoch;

        final receipt = StockReceipt(
          id: receiptId,
          receiptNumber: 'REC-1002',
          receiptDate: DateTime.utc(2026, 8, 28),
          warehouse: '00000000-0000-4000-8000-000000000001',
          supplier: null,
          lines: [
            StockMovementLine(
              id: lineId,
              movementUuid: receiptId,
              movementType: 'receipt',
              itemCode: 'ITEM-B',
              itemName: 'Item B',
              quantity: 5,
              unitCost: 200,
              totalCost: 1000,
            ),
          ],
        );

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(lineId),
                receiptId: Value(receiptId),
                movementType: 'receipt',
                itemCode: 'ITEM-B',
                itemName: 'Item B',
                quantity: const Value(5.0),
                unitCost: const Value(200.0),
                totalCost: const Value(1000.0),
                companyId: 'COMP-TEST',
              ),
            );

        await inventoryDb
            .into(inventoryDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(receiptId),
                receiptNumber: 'REC-1002',
                receiptDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
                warehouse: const Value('00000000-0000-4000-8000-000000000001'),
                currencyCode: 'SAR',
                status: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: const Value('COMP-TEST'),
              ),
            );

        // 1. Post
        await orchestrator.postStockReceiptData(data: receipt.toPostingData());

        final postedEntry = await journalRepo.findBySource(
          sourceType: 'stock_receipt',
          sourceId: receiptId,
        );
        expect(postedEntry, isNotNull);

        // 2. Unpost
        final unpostResult = await orchestrator.unpostStockDocumentRef(
          docRef: receipt.toPostingData().toDocumentRef(),
        );
        if (unpostResult is OrchestrationFailure) {
          fail('unpostStockDocumentRef failed: ${unpostResult.reason}');
        }
        expect(unpostResult, isA<OrchestrationSuccess>());

        // 3. Verify original entry is no longer returned as active source entry
        final activeEntry = await journalRepo.findBySource(
          sourceType: 'stock_receipt',
          sourceId: receiptId,
        );
        expect(activeEntry, isNull);

        // Verify reversal entry exists in audit trail
        final reversalEntry = await journalRepo.findBySource(
          sourceType: JournalPostingService.reverseSourceType,
          sourceId: postedEntry!.uuid,
        );
        expect(reversalEntry, isNotNull);
      },
    );

    test('unposting stock issue deletes journal entry directly', () async {
      final receiptId = generateUuidV4();
      final issueId = generateUuidV4();
      final rLineId = generateUuidV4();
      final iLineId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed cost layer via receipt first
      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: 'REC-2001',
        receiptDate: DateTime.utc(2026, 8, 28),
        warehouse: '00000000-0000-4000-8000-000000000001',
        supplier: null,
        lines: [
          StockMovementLine(
            id: rLineId,
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-C',
            itemName: 'Item C',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
      );

      await inventoryDb
          .into(inventoryDb.stockMovementLines)
          .insert(
            StockMovementLinesCompanion.insert(
              id: Value(rLineId),
              receiptId: Value(receiptId),
              movementType: 'receipt',
              itemCode: 'ITEM-C',
              itemName: 'Item C',
              quantity: const Value(10.0),
              unitCost: const Value(50.0),
              totalCost: const Value(500.0),
              companyId: 'COMP-TEST',
            ),
          );

      await inventoryDb
          .into(inventoryDb.stockReceipts)
          .insert(
            StockReceiptsCompanion.insert(
              id: Value(receiptId),
              receiptNumber: 'REC-2001',
              receiptDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
              warehouse: const Value('00000000-0000-4000-8000-000000000001'),
              currencyCode: 'SAR',
              status: const Value('draft'),
              createdAt: now,
              updatedAt: now,
              companyId: const Value('COMP-TEST'),
            ),
          );

      await orchestrator.postStockReceiptData(data: receipt.toPostingData());

      // Issue stock
      final issue = StockIssue(
        id: issueId,
        issueNumber: 'ISS-1001',
        issueDate: DateTime.utc(2026, 8, 28),
        warehouse: '00000000-0000-4000-8000-000000000001',
        lines: [
          StockMovementLine(
            id: iLineId,
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: 'ITEM-C',
            itemName: 'Item C',
            quantity: 3,
            unitCost: 50,
            totalCost: 150,
          ),
        ],
      );

      await inventoryDb
          .into(inventoryDb.stockMovementLines)
          .insert(
            StockMovementLinesCompanion.insert(
              id: Value(iLineId),
              issueId: Value(issueId),
              movementType: 'issue',
              itemCode: 'ITEM-C',
              itemName: 'Item C',
              quantity: const Value(3.0),
              unitCost: const Value(50.0),
              totalCost: const Value(150.0),
              companyId: 'COMP-TEST',
            ),
          );

      await inventoryDb
          .into(inventoryDb.stockIssues)
          .insert(
            StockIssuesCompanion.insert(
              id: Value(issueId),
              issueNumber: 'ISS-1001',
              issueDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
              warehouse: const Value('00000000-0000-4000-8000-000000000001'),
              currencyCode: 'SAR',
              status: const Value('draft'),
              createdAt: now,
              updatedAt: now,
              companyId: const Value('COMP-TEST'),
            ),
          );

      // Post Issue
      final postIssueResult = await orchestrator.postStockIssueData(
        data: issue.toPostingData(),
      );
      expect(postIssueResult, isA<OrchestrationSuccess>());

      final issueJournal = await journalRepo.findBySource(
        sourceType: 'stock_issue',
        sourceId: issueId,
      );
      expect(issueJournal, isNotNull);

      // Unpost Issue
      final unpostIssueResult = await orchestrator.unpostStockDocumentRef(
        docRef: issue.toPostingData().toDocumentRef(),
      );
      expect(unpostIssueResult, isA<OrchestrationSuccess>());

      final activeIssueJournal = await journalRepo.findBySource(
        sourceType: 'stock_issue',
        sourceId: issueId,
      );
      expect(activeIssueJournal, isNull);

      final reversalIssueJournal = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: issueJournal!.uuid,
      );
      expect(reversalIssueJournal, isNotNull);
    });

    test(
      'draft journal entry with isPosted = false is NOT saved into database',
      () async {
        final invAcc = await accountRepo.getByAccountCode('1230');
        final apAcc = await accountRepo.getByAccountCode('2110');

        final draft = JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 28),
          voucherNumber: 'DRAFT-001',
          voucherType: 'قيد مسودة',
          currencyCode: 'SAR',
          description: 'تجربة قيد مسودة',
          isPosted: false,
          sourceType: 'test_draft',
          sourceId: 'draft-123',
          lines: [
            JournalLineDraft(
              accountUuid: invAcc!.id,
              debit: 100,
              credit: 0,
              currencyCode: 'SAR',
            ),
            JournalLineDraft(
              accountUuid: apAcc!.id,
              debit: 0,
              credit: 100,
              currencyCode: 'SAR',
            ),
          ],
        );

        final resultEntry = await journalRepo.post(draft);
        expect(resultEntry.isPosted, isFalse);

        final dbEntry = await journalRepo.findBySource(
          sourceType: 'test_draft',
          sourceId: 'draft-123',
        );
        expect(dbEntry, isNull);

        final headers = await journalRepo.listHeaders(isPosted: true);
        expect(headers.isEmpty, isTrue);
      },
    );

    test(
      'posting receipt with custom currency propagates currencyCode to journal entry',
      () async {
        final receiptId = generateUuidV4();
        final lineId = generateUuidV4();
        final now = DateTime.now().millisecondsSinceEpoch;

        final receipt = StockReceipt(
          id: receiptId,
          receiptNumber: 'REC-USD-1001',
          receiptDate: DateTime.utc(2026, 8, 28),
          warehouse: '00000000-0000-4000-8000-000000000001',
          currencyCode: 'USD',
          exchangeRate: 3.75,
          lines: [
            StockMovementLine(
              id: lineId,
              movementUuid: receiptId,
              movementType: 'receipt',
              itemCode: 'ITEM-USD',
              itemName: 'Item USD',
              quantity: 10,
              unitCost: 20,
              totalCost: 200,
            ),
          ],
        );

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(lineId),
                receiptId: Value(receiptId),
                movementType: 'receipt',
                itemCode: 'ITEM-USD',
                itemName: 'Item USD',
                quantity: const Value(10.0),
                unitCost: const Value(20.0),
                totalCost: const Value(200.0),
                companyId: 'COMP-TEST',
              ),
            );

        await inventoryDb
            .into(inventoryDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(receiptId),
                receiptNumber: 'REC-USD-1001',
                receiptDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
                warehouse: const Value('00000000-0000-4000-8000-000000000001'),
                currencyCode: 'USD',
                exchangeRate: const Value(3.75),
                status: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: const Value('COMP-TEST'),
              ),
            );

        final result = await orchestrator.postStockReceiptData(
          data: receipt.toPostingData(),
        );
        if (result is OrchestrationFailure) {
          fail('Orchestration failed with reason: ${result.reason}');
        }
        expect(result, isA<OrchestrationSuccess>());

        final entry = await journalRepo.findBySource(
          sourceType: 'stock_receipt',
          sourceId: receiptId,
        );

        expect(entry, isNotNull);
        expect(entry!.currencyCode, equals('USD'));
        expect(entry.lines.length, equals(2));
        expect(entry.lines.any((l) => l.currencyCode == 'USD'), isTrue);

        // Verify CostLayer is created in Base Currency (20 USD * 3.75 = 75 SAR/YER)
        final layers = await inventoryDb
            .select(inventoryDb.inventoryCostLayers)
            .get();
        expect(layers.length, equals(1));
        expect(layers.first.unitCost, equals(75.0)); // 20 * 3.75
        expect(layers.first.totalCost, equals(750.0)); // 10 * 75
      },
    );

    test(
      'posting sale invoice creates COGS journal entry in Base Currency',
      () async {
        final saleId = generateUuidV4();

        final sale = Sale(
          id: saleId,
          companyId: 'COMP-TEST',
          saleNumber: 'INV-USD-999',
          saleDate: DateTime.utc(2026, 8, 28),
          customerAccountId: null,
          settlementType: SaleSettlementType.cash,
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          exchangeRate: 530.0,
          subtotal: 100.0,
          itemDiscountTotal: 0.0,
          discountType: DiscountType.fixed,
          discountValue: 0.0,
          discountAmount: 0.0,
          taxRate: 0.0,
          taxAmount: 0.0,
          total: 100.0,
          paidAmount: 100.0,
          remainingAmount: 0.0,
          paymentStatus: PaymentStatus.paid,
          paymentMethod: PaymentMethod.cash,
          saleStatus: SaleStatus.posted,
          dataSource: SaleDataSource.local,
          createdAt: DateTime.utc(2026, 8, 28),
          updatedAt: DateTime.utc(2026, 8, 28),
          items: [],
          payments: [],
        );

        final postingData = SaleInvoicePostingData(
          uuid: sale.uuid,
          saleNumber: sale.saleNumber,
          saleDate: sale.saleDate,
          total: sale.total,
          itemDiscountTotal: sale.itemDiscountTotal,
          discountAmount: sale.discountAmount,
          settlementType: PostingSettlementType.cash,
          currencyCode: sale.currencyCode,
          baseCurrencyCode: sale.baseCurrencyCode,
          exchangeRate: sale.exchangeRate,
          customerAccountId: sale.customerAccountId,
          cashAccountId: '1211',
        );

        final entryBuilder = AccountingEntryBuilder(
          mappingResolver: AccountMappingResolverImpl(
            accountRepository: accountRepo,
            validationService: AccountValidationServiceImpl(accountRepo),
          ),
          validationService: AccountValidationServiceImpl(accountRepo),
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: postingData,
          calculatedCogsCost: 45000.0, // COGS calculated in YER
          isPosted: true,
        );

        expect(drafts.length, equals(2)); // Revenue entry + COGS entry
        final cogsDraft = drafts.firstWhere((d) => d.sourceType == 'sale_cogs');
        expect(cogsDraft.currencyCode, equals('YER'));
        expect(cogsDraft.baseCurrencyCode, equals('YER'));
        expect(cogsDraft.lines.every((l) => l.currencyCode == 'YER'), isTrue);
        expect(
          cogsDraft.lines.every((l) => l.exchangeRateToBase == 1.0),
          isTrue,
        );
        expect(cogsDraft.lines.first.debit, equals(45000.0));
      },
    );

    test(
      'postIssue calculates layer cost in Base Currency and posts journal in Base Currency',
      () async {
        final receiptId = generateUuidV4();
        final issueId = generateUuidV4();
        final rLineId = generateUuidV4();
        final iLineId = generateUuidV4();
        final now = DateTime.now().millisecondsSinceEpoch;

        // 1. Seed USD receipt (10 items @ 10 USD, rate 530 => 5,300 YER unit cost)
        final receipt = StockReceipt(
          id: receiptId,
          receiptNumber: 'REC-FX-10',
          receiptDate: DateTime.utc(2026, 8, 28),
          warehouse: '00000000-0000-4000-8000-000000000001',
          currencyCode: 'USD',
          exchangeRate: 530.0,
          lines: [
            StockMovementLine(
              id: rLineId,
              movementUuid: receiptId,
              movementType: 'receipt',
              itemCode: 'ITEM-FX-1',
              itemName: 'Item FX 1',
              quantity: 10,
              unitCost: 10,
              totalCost: 100,
            ),
          ],
        );

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(rLineId),
                receiptId: Value(receiptId),
                movementType: 'receipt',
                itemCode: 'ITEM-FX-1',
                itemName: 'Item FX 1',
                quantity: const Value(10.0),
                unitCost: const Value(10.0),
                totalCost: const Value(100.0),
                companyId: 'COMP-TEST',
              ),
            );

        await inventoryDb
            .into(inventoryDb.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                id: Value(receiptId),
                receiptNumber: 'REC-FX-10',
                receiptDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
                warehouse: const Value('00000000-0000-4000-8000-000000000001'),
                currencyCode: 'USD',
                exchangeRate: const Value(530.0),
                status: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: const Value('COMP-TEST'),
              ),
            );

        final recRes = await orchestrator.postStockReceiptData(data: receipt.toPostingData());
        if (recRes is OrchestrationFailure) {
          fail('postStockReceiptData failed: ${recRes.reason}');
        }

        // 2. Issue 2 items via Stock Issue (issue document in USD, rate 530)
        final issue = StockIssue(
          id: issueId,
          issueNumber: 'ISS-FX-20',
          issueDate: DateTime.utc(2026, 8, 28),
          warehouse: '00000000-0000-4000-8000-000000000001',
          currencyCode: 'USD',
          exchangeRate: 530.0,
          lines: [
            StockMovementLine(
              id: iLineId,
              movementUuid: issueId,
              movementType: 'issue',
              itemCode: 'ITEM-FX-1',
              itemName: 'Item FX 1',
              quantity: 2,
              unitCost: 10,
              totalCost: 20,
            ),
          ],
        );

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(iLineId),
                issueId: Value(issueId),
                movementType: 'issue',
                itemCode: 'ITEM-FX-1',
                itemName: 'Item FX 1',
                quantity: const Value(2.0),
                unitCost: const Value(10.0),
                totalCost: const Value(20.0),
                companyId: 'COMP-TEST',
              ),
            );

        await inventoryDb
            .into(inventoryDb.stockIssues)
            .insert(
              StockIssuesCompanion.insert(
                id: Value(issueId),
                issueNumber: 'ISS-FX-20',
                issueDate: DateTime.utc(2026, 8, 28).millisecondsSinceEpoch,
                warehouse: const Value('00000000-0000-4000-8000-000000000001'),
                currencyCode: 'USD',
                exchangeRate: const Value(530.0),
                status: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: const Value('COMP-TEST'),
              ),
            );

        final issueResult = await orchestrator.postStockIssueData(
          data: issue.toPostingData(),
        );
        if (issueResult is OrchestrationFailure) {
          fail('postStockIssueData failed: ${issueResult.reason}');
        }
        expect(issueResult, isA<OrchestrationSuccess>());

        // 3. Verify Stock Issue journal entry is created in Base Currency (YER) with amount = 2 * 5,300 = 10,600 YER
        final issueJournal = await journalRepo.findBySource(
          sourceType: 'stock_issue',
          sourceId: issueId,
        );

        expect(issueJournal, isNotNull);
        expect(issueJournal!.currencyCode, equals('YER'));
        expect(issueJournal.lines.length, equals(2));
        expect(issueJournal.lines.first.debit, equals(10600.0));
        expect(issueJournal.lines.first.currencyCode, equals('YER'));
        expect(issueJournal.lines.first.exchangeRateToBase, equals(1.0));
      },
    );

    test('saveReceipt and saveIssue reject zero-cost lines', () async {
      final zeroReceipt = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-ZERO',
        receiptDate: DateTime.now(),
        warehouse: '00000000-0000-4000-8000-000000000001',
        lines: [
          StockMovementLine(
            movementUuid: generateUuidV4(),
            movementType: 'receipt',
            itemCode: 'ITEM-0',
            itemName: 'Zero Item',
            quantity: 5,
            unitCost: 0,
            totalCost: 0,
          ),
        ],
      );

      final repo = StockMovementsRepositoryImpl(
        db: inventoryDb,
        readCompanyId: () => 'COMP-TEST',
      );
      expect(
        () => repo.saveReceipt(zeroReceipt),
        throwsA(isA<ArgumentError>()),
      );

      final zeroIssue = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-ZERO',
        issueDate: DateTime.now(),
        warehouse: '00000000-0000-4000-8000-000000000001',
        lines: [
          StockMovementLine(
            movementUuid: generateUuidV4(),
            movementType: 'issue',
            itemCode: 'ITEM-0',
            itemName: 'Zero Item',
            quantity: 5,
            unitCost: 0,
            totalCost: 0,
          ),
        ],
      );

      expect(() => repo.saveIssue(zeroIssue), throwsA(isA<ArgumentError>()));
    });

    test(
      'getItemCostValuation calculates cost from layers and falls back to non-zero price/unitCost',
      () async {
        final costLayerService = CostLayerServiceImpl(
          db: inventoryDb,
          readCompanyId: () => 'COMP-TEST',
        );

        // Create a layer of 10 units @ 450 YER
        await costLayerService.createLayer(
          CostLayer(
            id: generateUuidV4(),
            itemCode: 'VALU-ITEM-1',
            movementUuid: generateUuidV4(),
            movementType: 'receipt',
            receivedDate: DateTime.now(),
            receivedQty: 10,
            remainingQty: 10,
            unitCost: 450,
            totalCost: 4500,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final resolvedLayerCost = await costLayerService.getItemCostValuation(
          itemCode: 'VALU-ITEM-1',
        );
        expect(resolvedLayerCost, equals(450.0));

        // Test fallback for item with no layers but has product unitCost/price
        final productRepo = ProductRepositoryImpl(
          inventoryDb,
          readCompanyId: () => 'COMP-TEST',
        );
        await productRepo.insert(
          const ProductDraft(
            itemCode: 'VALU-ITEM-2',
            name: 'Fallback Item',
            packSize: 1,
            price: 300,
            unitCost: 250,
          ),
        );

        final fallbackCost = await costLayerService.getItemCostValuation(
          itemCode: 'VALU-ITEM-2',
        );
        expect(fallbackCost, equals(250.0));

        // Test item with price > 0 but unitCost == 0 returns 0.0 (selling price is never used as cost)
        await productRepo.insert(
          const ProductDraft(
            itemCode: 'VALU-ITEM-3',
            name: 'Price Only Item',
            packSize: 1,
            price: 500,
            unitCost: 0,
          ),
        );

        final zeroCost = await costLayerService.getItemCostValuation(
          itemCode: 'VALU-ITEM-3',
        );
        expect(zeroCost, equals(0.0));
      },
    );

    test(
      'PostingCoordinatorImpl blocks posting if document lines have zero cost',
      () async {
        final zeroReceiptId = generateUuidV4();
        final zeroReceipt = StockReceipt(
          id: zeroReceiptId,
          receiptNumber: 'REC-ZERO-POST',
          receiptDate: DateTime.now(),
          warehouse: '00000000-0000-4000-8000-000000000001',
          lines: [
            StockMovementLine(
              movementUuid: zeroReceiptId,
              movementType: 'receipt',
              itemCode: 'ZERO-ITEM-POST',
              itemName: 'Zero Post Item',
              quantity: 10,
              unitCost: 0,
              totalCost: 0,
            ),
          ],
        );
        expect(zeroReceipt.id, equals(zeroReceiptId));

        await inventoryDb
            .into(inventoryDb.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                id: Value(generateUuidV4()),
                receiptId: Value(zeroReceiptId),
                movementType: 'receipt',
                itemCode: 'ZERO-ITEM-POST',
                itemName: 'Zero Post Item',
                quantity: const Value(10.0),
                unitCost: const Value(0.0),
                totalCost: const Value(0.0),
                companyId: 'COMP-TEST',
              ),
            );

        final postingCoordinator = PostingCoordinatorImpl(
          db: inventoryDb,
          stockValidationService: StockValidationServiceImpl(inventoryDb, () => 'COMP-TEST'),
          dependencyDetector: InventoryDependencyDetectorImpl(inventoryDb, () => 'COMP-TEST'),
          postingEngine: PostingEngineImpl(
            inventoryDb,
            CostLayerServiceImpl(db: inventoryDb, readCompanyId: () => 'COMP-TEST'),
            null,
            () => 'COMP-TEST',
          ),
          accountingPoster: const NoOpInventoryAccountingPoster(),
          permissionGuard: const AllowAllPermissionGuard(),
          readCompanyId: () => 'COMP-TEST',
        );

        final postResult = await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: zeroReceiptId,
            documentNumber: 'REC-ZERO-POST',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: '00000000-0000-4000-8000-000000000001',
          ),
        );

        expect(postResult, isA<PostInvalidStatus>());
        final invalidStatus = postResult as PostInvalidStatus;
        expect(invalidStatus.reason, contains('بتكلفة صفرية'));
      },
    );

    test(
      'PostingCoordinatorImpl blocks unpost when downstream movements exist',
      () async {
        final repo = StockMovementsRepositoryImpl(
          db: inventoryDb,
          readCompanyId: () => 'COMP-TEST',
        );
        final receiptDate = DateTime.now().subtract(const Duration(days: 2));
        final issueDate = DateTime.now().subtract(const Duration(days: 1));

        // 1. Create & Post Stock Receipt A
        final recId = generateUuidV4();
        final rec = StockReceipt(
          id: recId,
          receiptNumber: 'REC-DEP-1',
          receiptDate: receiptDate,
          warehouse: '00000000-0000-4000-8000-000000000001',
          lines: [
            StockMovementLine(
              movementUuid: recId,
              movementType: 'receipt',
              itemCode: 'DEP-ITEM-1',
              itemName: 'Dependent Test Item',
              quantity: 100,
              unitCost: 50,
              totalCost: 5000,
            ),
          ],
        );
        await repo.saveReceipt(rec);

        final postingCoordinator = PostingCoordinatorImpl(
          db: inventoryDb,
          stockValidationService: StockValidationServiceImpl(inventoryDb, () => 'COMP-TEST'),
          dependencyDetector: InventoryDependencyDetectorImpl(inventoryDb, () => 'COMP-TEST'),
          postingEngine: PostingEngineImpl(
            inventoryDb,
            CostLayerServiceImpl(db: inventoryDb, readCompanyId: () => 'COMP-TEST'),
            null,
            () => 'COMP-TEST',
          ),
          accountingPoster: const NoOpInventoryAccountingPoster(),
          permissionGuard: const AllowAllPermissionGuard(),
          readCompanyId: () => 'COMP-TEST',
        );

        await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: recId,
            documentNumber: 'REC-DEP-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: receiptDate,
            warehouseId: '00000000-0000-4000-8000-000000000001',
          ),
        );

        // 2. Create & Post Stock Issue B on the same item after Receipt A
        final issId = generateUuidV4();
        final issue = StockIssue(
          id: issId,
          issueNumber: 'ISS-DEP-1',
          issueDate: issueDate,
          warehouse: '00000000-0000-4000-8000-000000000001',
          lines: [
            StockMovementLine(
              movementUuid: issId,
              movementType: 'issue',
              itemCode: 'DEP-ITEM-1',
              itemName: 'Dependent Test Item',
              quantity: 20,
              unitCost: 50,
              totalCost: 1000,
            ),
          ],
        );
        await repo.saveIssue(issue);

        await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: issId,
            documentNumber: 'ISS-DEP-1',
            documentType: InventoryDocumentType.stockIssue,
            documentDate: issueDate,
            warehouseId: '00000000-0000-4000-8000-000000000001',
          ),
        );

        // 3. Attempt to unpost Receipt A
        final unpostResult = await postingCoordinator.unpost(
          document: InventoryDocumentRef(
            documentId: recId,
            documentNumber: 'REC-DEP-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: receiptDate,
            warehouseId: '00000000-0000-4000-8000-000000000001',
          ),
        );

        // 4. Expect unpost to be BLOCKED by downstream issue B
        expect(unpostResult, isA<UnpostBlockedByDependencies>());
        final blockedResult = unpostResult as UnpostBlockedByDependencies;
        expect(blockedResult.dependentDocuments, isNotEmpty);
        expect(
          blockedResult.dependentDocuments.first.documentNumber,
          equals('ISS-DEP-1'),
        );
      },
    );
  });
}
