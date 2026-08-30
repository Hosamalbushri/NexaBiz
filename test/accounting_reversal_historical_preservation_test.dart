import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  late InventoryDatabase invDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String compA_acc1;
  late String compA_acc2;
  late String compB_acc1;

  setUp(() async {
    companyA = 'company_A';
    companyB = 'company_B';
    activeCompanyId = companyA;

    db = AccountingDatabase(executor: NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => activeCompanyId,
    );
    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => activeCompanyId,
    );
    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => activeCompanyId,
    );
    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => activeCompanyId,
    );

    compA_acc1 = generateUuidV4();
    compA_acc2 = generateUuidV4();
    compB_acc1 = generateUuidV4();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Seed Accounts for Company A
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_acc1,
            companyId: Value(companyA),
            accountCode: '1010',
            name: 'Cash A',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_acc2,
            companyId: Value(companyA),
            accountCode: '4010',
            name: 'Sales A',
            accountType: 'revenue',
            normalBalance: 'credit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Seed Accounts for Company B
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compB_acc1,
            companyId: Value(companyB),
            accountCode: '1020',
            name: 'Cash B',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    activeCompanyId = companyA;
  });

  tearDown(() async {
    await db.close();
    await invDb.close();
  });

  group('ROOT FIX 03 — Reversal Architecture & Historical Preservation', () {
    test('1. Normal Reversal: Reversing entry created with swapped debit/credit, original entry intact', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Original sale entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 1000, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 1000, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);
      expect(original.isPosted, isTrue);

      final reversal = await postingService.reverseByUuid(original.uuid);

      // Verify Reversal Properties
      expect(reversal.uuid, isNot(equals(original.uuid)));
      expect(reversal.isPosted, isTrue);
      expect(reversal.sourceType, equals(JournalPostingService.reverseSourceType));
      expect(reversal.sourceId, equals(original.uuid));
      expect(reversal.voucherNumber, equals('JE-REV-01-R'));

      // Verify line debit/credit swap
      final line1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      final line2 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc2);
      expect(line1.debit, equals(0));
      expect(line1.credit, equals(1000));
      expect(line2.debit, equals(1000));
      expect(line2.credit, equals(0));

      // Verify Original Entry is unchanged
      final originalInDb = await journalRepo.getByUuid(original.uuid);
      expect(originalInDb, isNotNull);
      expect(originalInDb!.isPosted, isTrue);
      expect(originalInDb.deletedAt, isNull);
    });

    test('2. Reversal Twice (Idempotency): Multiple reversal calls return exact same reversal entry', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-02',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Idempotent entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);

      final rev1 = await postingService.reverseByUuid(original.uuid);
      final rev2 = await postingService.reverseByUuid(original.uuid);

      expect(rev1.uuid, equals(rev2.uuid));

      // Total entries in companyA = 2 (original + 1 reversal)
      final allEntries = await db.select(db.journalEntries).get();
      expect(allEntries.length, equals(2));
    });

    test('3. Concurrent Reversal: Simultaneous reversal calls produce single reversal entry', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-03',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Concurrent entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 750, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 750, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);

      final results = await Future.wait([
        postingService.reverseByUuid(original.uuid),
        postingService.reverseByUuid(original.uuid),
      ]);

      expect(results[0].uuid, equals(results[1].uuid));

      final allEntries = await db.select(db.journalEntries).get();
      expect(allEntries.length, equals(2));
    });

    test('4. Historical Cost Preservation: Reversal uses exact original entry amounts without recalculation', () async {
      activeCompanyId = companyA;
      const historicalAmount = 1432.75;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-04',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Historical amount entry',
        isPosted: true,
        entryDate: DateTime.now().subtract(const Duration(days: 30)),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: historicalAmount, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: historicalAmount, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);
      final reversal = await postingService.reverseByUuid(original.uuid);

      final revLine1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      expect(revLine1.credit, equals(historicalAmount));
      expect(revLine1.debit, equals(0));
    });

    test('5. Historical FX Preservation: Reversal preserves original exchange rate without using current FX rate', () async {
      activeCompanyId = companyA;
      const historicalRate = 3.75;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-05',
        voucherType: 'journal',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        description: 'USD foreign entry',
        isPosted: true,
        entryDate: DateTime.now().subtract(const Duration(days: 60)),
        lines: [
          JournalLineDraft(
            accountUuid: compA_acc1,
            debit: 100,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: historicalRate,
            baseDebit: 375,
            baseCredit: 0,
          ),
          JournalLineDraft(
            accountUuid: compA_acc2,
            debit: 0,
            credit: 100,
            currencyCode: 'USD',
            exchangeRateToBase: historicalRate,
            baseDebit: 0,
            baseCredit: 375,
          ),
        ],
      );

      final original = await postingService.post(draft);
      final reversal = await postingService.reverseByUuid(original.uuid);

      final line1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      expect(line1.exchangeRateToBase, equals(historicalRate));
      expect(line1.credit, equals(100));
      expect(line1.baseCredit, equals(375));
    });

    test('6. Inventory Reversal: Reversing outbound document restores exact consumed cost layer quantities', () async {
      activeCompanyId = companyA;
      final now = DateTime.now();
      const itemCode = 'ITEM-ABC';
      const warehouseId = 'WH-01';

      final recUuid = generateUuidV4();
      final recLineUuid = generateUuidV4();

      // 1. Post Inbound Receipt (creates cost layer of 10 units at 50 SAR)
      final receiptDoc = InventoryDocumentRef(
        documentId: recUuid,
        documentNumber: 'REC-101',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: now,
        warehouseId: warehouseId,
      );

      await postingEngine.applyInboundPosting(
        document: receiptDoc,
        lines: [
          InboundLineData(
            lineUuid: recLineUuid,
            itemCode: itemCode,
            itemName: 'Item ABC',
            quantity: 10,
            unitCost: 50,
          ),
        ],
        warehouseId: warehouseId,
        documentDate: now,
      );

      // Verify open layer has 10 units remaining
      var layers = await costLayerService.getOpenLayers(itemCode, warehouseId: warehouseId);
      expect(layers.single.remainingQty, equals(10));

      // 2. Post Outbound Issue (consumes 4 units)
      final issUuid = generateUuidV4();
      final issLineUuid = generateUuidV4();
      final nowMs = now.toUtc().millisecondsSinceEpoch;

      final issueDoc = InventoryDocumentRef(
        documentId: issUuid,
        documentNumber: 'ISS-202',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: now,
        warehouseId: warehouseId,
      );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: issLineUuid,
              movementUuid: issUuid,
              movementType: 'issue',
              itemCode: itemCode,
              itemName: 'Item ABC',
              quantity: const Value(4),
            ),
          );

      await postingEngine.applyOutboundPosting(
        document: issueDoc,
        lines: [
          OutboundLineData(
            lineUuid: issLineUuid,
            itemCode: itemCode,
            itemName: 'Item ABC',
            quantity: 4,
          ),
        ],
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.fifo,
      );

      layers = await costLayerService.getOpenLayers(itemCode, warehouseId: warehouseId);
      expect(layers.single.remainingQty, equals(6));

      // 3. Reverse Outbound Issue
      await postingEngine.reversePosting(document: issueDoc);

      // 4. Layer remainingQty MUST be restored back to 10
      layers = await costLayerService.getOpenLayers(itemCode, warehouseId: warehouseId);
      expect(layers.single.remainingQty, equals(10));
    });

    test('7. COGS Reversal: Reversing Sales COGS swaps exact posted COGS amount', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'INV-303-COGS',
        voucherType: 'مبيعات',
        currencyCode: 'SAR',
        description: 'COGS recognition',
        isPosted: true,
        sourceType: 'sale',
        sourceId: 'SALE-303',
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 320, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 320, currencyCode: 'SAR'),
        ],
      );

      final cogsEntry = await postingService.post(draft);

      await postingService.voidBySource(sourceType: 'sale', sourceId: 'SALE-303');

      final reversal = await postingService.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: cogsEntry.uuid,
      );

      expect(reversal, isNotNull);
      expect(reversal!.isPosted, isTrue);
      expect(reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1).credit, equals(320));
      expect(reversal.lines.firstWhere((l) => l.accountUuid == compA_acc2).debit, equals(320));
    });

    test('8. Original Entry Remains Unchanged: Original entry fields remain 100% identical post-reversal', () async {
      activeCompanyId = companyA;
      final date = DateTime.now().subtract(const Duration(days: 5));
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-08',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Intact original check',
        isPosted: true,
        entryDate: date,
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 900, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 900, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);

      await postingService.reverseByUuid(original.uuid);

      final afterRev = await journalRepo.getByUuid(original.uuid);
      expect(afterRev!.uuid, equals(original.uuid));
      expect(afterRev.voucherNumber, equals('JE-REV-08'));
      expect(afterRev.isPosted, isTrue);
      expect(afterRev.deletedAt, isNull);
      expect(afterRev.lines.first.debit, equals(900));
    });

    test('9. Cross-Tenant Reversal Rejected: Company B cannot reverse Company A entry', () async {
      // Create entry under Company A
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-09',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Company A entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 450, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 450, currencyCode: 'SAR'),
        ],
      );

      final compAEntry = await postingService.post(draft);

      // Switch context to Company B
      activeCompanyId = companyB;

      // Attempt to reverse Company A entry from Company B context
      expect(
        () async => postingService.reverseByUuid(compAEntry.uuid),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Switch back to Company A context to verify entry is intact
      activeCompanyId = companyA;
      final checkCompA = await journalRepo.getByUuid(compAEntry.uuid);
      expect(checkCompA, isNotNull);
      expect(checkCompA!.isPosted, isTrue);

      final reversalCheck = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: compAEntry.uuid,
      );
      expect(reversalCheck, isNull);
    });

    test('10. Transaction Safety: Aborted reversal transaction leaves 0 partial database mutations', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-10',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Transaction safety entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 600, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 600, currencyCode: 'SAR'),
        ],
      );

      final original = await postingService.post(draft);

      final countBefore = (await db.select(db.journalEntries).get()).length;

      // Attempt reversal for non-existent entry or invalid UUID
      try {
        await postingService.reverseByUuid('NON-EXISTENT-UUID');
      } catch (_) {}

      final countAfter = (await db.select(db.journalEntries).get()).length;
      expect(countAfter, equals(countBefore));

      final originalCheck = await journalRepo.getByUuid(original.uuid);
      expect(originalCheck!.isPosted, isTrue);
    });
  });
}
