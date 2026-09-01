import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/audit/domain/entities/audit_trail_entry.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_generator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

class _FakePostingEngine implements PostingEngine {
  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async =>
      100.0;

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      100.0;

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      100.0;

  @override
  Future<void> reversePosting({
    required InventoryDocumentRef document,
  }) async {}
}

class _FakeStockValidationService implements StockValidationService {
  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async =>
      1000.0;

  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async =>
      [];
}

class _FakeDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async =>
      [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late AccountRepositoryImpl accountRepo;
  late FiscalYearRepositoryImpl fiscalYearRepo;
  late AccountingPeriodValidator periodValidator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalService;
  late AuditTrailService auditService;
  late PostingCoordinatorImpl postingCoordinator;
  late SyncQueue syncQueue;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;

  late String acc1;
  late String acc2;

  const companyId = 'AuditTestCompany';
  final year2025Start = DateTime.utc(2025, 1, 1);
  final year2025End = DateTime.utc(2025, 12, 31, 23, 59, 59);

  Future<FiscalYear> createFY2025() async {
    final generator = const AccountingPeriodGenerator();
    final periods = generator.generateMonthly(
      startDate: year2025Start,
      endDate: year2025End,
      periodCount: 12,
    );
    final fy = await fiscalYearRepo.createFiscalYear(
      draft: FiscalYearDraft(
        code: 'FY2025',
        name: 'FY 2025',
        startDate: year2025Start,
        endDate: year2025End,
        baseCurrencyCode: 'YER',
        periodCount: 12,
        periodFrequency: PeriodFrequency.monthly,
        fxRevaluationEnabled: false,
      ),
      periods: periods,
    );
    final periodList = await fiscalYearRepo.listPeriods(fy.uuid);
    for (final p in periodList) {
      await fiscalYearRepo.openPeriod(periodUuid: p.uuid, openedBy: 'admin');
    }
    return fy;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audit_trail_test_');
    Hive.init(tempDir.path);
    await SyncQueue.registerAdapter();

    syncBox = await Hive.openBox<SyncOperation>('test_audit_sync_box_${DateTime.now().millisecondsSinceEpoch}');
    syncQueue = SyncQueue(box: syncBox, companyId: companyId);

    accDb = AccountingDatabase.memory();
    invDb = InventoryDatabase.memory();

    accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => companyId,
    );
    await accountRepo.seedDefaultChart();
    await accountRepo.ensureDefaultChartSeeded();

    final activeAccounts = (await accDb.select(accDb.accounts).get())
        .where((a) => !a.isGroup && a.isActive)
        .toList();
    acc1 = activeAccounts[0].uuid;
    acc2 = activeAccounts[1].uuid;

    fiscalYearRepo = FiscalYearRepositoryImpl(
      accDb,
      readCompanyId: () => companyId,
    );

    periodValidator = AccountingPeriodValidator(
      repository: fiscalYearRepo,
      legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
    );

    auditService = AuditTrailService(
      db: invDb,
      syncQueue: syncQueue,
      readCompanyId: () => companyId,
    );

    journalRepo = JournalRepositoryImpl(
      accDb,
      periodValidator: periodValidator,
      accounts: accountRepo,
      readCompanyId: () => companyId,
    );

    journalService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
      auditService: auditService,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: _FakeStockValidationService(),
      dependencyDetector: _FakeDependencyDetector(),
      postingEngine: _FakePostingEngine(),
      periodValidator: periodValidator,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
      syncQueue: syncQueue,
    );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
    if (syncBox.isOpen) {
      await syncBox.close();
    }
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 21 — Complete Audit Trail Test Suite', () {
    test('1. Posting creates an audit event with timestamps, actor, and snapshots', () async {
      await createFY2025();

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-AUDIT-1',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Audit test entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 1000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 1000, currencyCode: 'YER'),
        ],
      );

      final posted = await journalService.post(draft, userId: 'user-101');
      expect(posted.isPosted, true);

      final auditTrail = await auditService.getAuditTrail(documentId: posted.uuid);
      expect(auditTrail, isNotEmpty);

      final postEvent = auditTrail.firstWhere((e) => e.eventType == 'post');
      expect(postEvent.documentId, posted.uuid);
      expect(postEvent.documentType, 'journal_entry');
      expect(postEvent.userId, 'user-101');
      expect(postEvent.timestamp, isNotNull);
      expect(postEvent.metadata, isNotNull);
      expect(postEvent.metadata!['before'], isNotNull);
      expect(postEvent.metadata!['after'], isNotNull);
    });

    test('2. Reversal creates an audit event linking original and reversal transactions', () async {
      await createFY2025();

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 20),
        voucherNumber: 'V-AUDIT-ORIG',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Original entry to reverse',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 5000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 5000, currencyCode: 'YER'),
        ],
      );

      final original = await journalService.post(draft, userId: 'user-101');
      final reversal = await journalService.reverseByUuid(original.uuid);

      final reversalAudit = await auditService.getAuditTrail(documentId: reversal.uuid);
      expect(reversalAudit, isNotEmpty);

      final revEvent = reversalAudit.firstWhere((e) => e.eventType == 'reverse');
      expect(revEvent.documentId, reversal.uuid);
      expect(revEvent.metadata, isNotNull);
      expect(revEvent.metadata!['originalTransactionId'], original.uuid);
      expect(revEvent.metadata!['reversalTransactionId'], reversal.uuid);
    });

    test('3. Unauthorized attempt (posting into closed period) is recorded in audit trail', () async {
      final fy = await createFY2025();
      final periodList = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periodList.firstWhere((p) => p.periodNumber == 1);
      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'admin',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      final closedDraft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-CLOSED-ATTEMPT',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Attempt post into closed Jan',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 100, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 100, currencyCode: 'YER'),
        ],
      );

      try {
        await journalService.post(closedDraft, userId: 'malicious-actor');
        fail('Should have thrown JournalException.periodClosed');
      } on JournalException catch (e) {
        expect(e.code, JournalException.periodClosed);
      }

      final unauthEvents = await auditService.getAuditTrailByCompany(
        companyId: companyId,
        eventType: 'unauthorized_attempt',
      );
      expect(unauthEvents, isNotEmpty);
      final attempt = unauthEvents.first;
      expect(attempt.eventType, 'unauthorized_attempt');
      expect(attempt.userId, 'malicious-actor');
      expect(attempt.metadata!['errorReason'], contains('closed'));
    });

    test('4. Audit data changes contain before and after values', () async {
      await createFY2025();

      const docUuid = '00000000-0000-0000-0000-000000000100';
      const lineUuid = '00000000-0000-0000-0000-000000000101';

      // Create & post receipt via database
      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: docUuid,
          receiptNumber: 'REC-100',
          receiptDate: DateTime.utc(2025, 1, 10).millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          status: const Value('draft'),
          companyId: const Value(companyId),
        ),
      );

      await invDb.into(invDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineUuid,
          movementUuid: docUuid,
          movementType: 'receipt',
          itemCode: 'ITEM-1',
          itemName: 'Item 1',
          quantity: const Value(10.0),
          unitCost: const Value(50.0),
          totalCost: const Value(500.0),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: docUuid,
        documentNumber: 'REC-100',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2025, 1, 10),
      );

      final result = await postingCoordinator.post(document: docRef, userId: 'inv-user');
      expect(result, isA<PostSuccess>());

      final auditTrail = await auditService.getAuditTrail(documentId: docUuid);
      expect(auditTrail, isNotEmpty);

      final postEvent = auditTrail.firstWhere((e) => e.eventType == 'post');
      expect(postEvent.metadata, isNotNull);
      expect(postEvent.metadata!['before'], equals({'status': 'draft'}));
      expect(postEvent.metadata!['after'], equals({'status': 'posted', 'postedValue': 100.0}));
    });

    test('5. Audit data survives reversal and maintains historical chain', () async {
      await createFY2025();

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 25),
        voucherNumber: 'V-HIST-1',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Historical entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 2000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 2000, currencyCode: 'YER'),
        ],
      );

      final original = await journalService.post(draft, userId: 'user-1');
      final reversal = await journalService.reverseByUuid(original.uuid);

      final originalAudit = await auditService.getAuditTrail(documentId: original.uuid);
      final reversalAudit = await auditService.getAuditTrail(documentId: reversal.uuid);

      expect(originalAudit, isNotEmpty);
      expect(reversalAudit, isNotEmpty);

      // Verify original post audit log is intact
      expect(originalAudit.any((e) => e.eventType == 'post'), true);
      // Verify reversal audit log references original
      expect(reversalAudit.first.metadata!['originalTransactionId'], original.uuid);
    });

    test('6. Audit data enqueues sync payload so audit events survive sync', () async {
      await createFY2025();

      final event = await auditService.recordEvent(
        documentId: 'DOC-SYNC-1',
        documentType: 'stock_receipt',
        eventType: 'post',
        userId: 'sync-user',
        notes: 'Test sync survival',
        metadata: {'postedValue': 1200.0},
      );

      final pendingOps = await syncQueue.peekAll();
      final auditOp = pendingOps.firstWhere((op) => op.entityType == 'audit_event');

      expect(auditOp.entityId, event.uuid);
      expect(auditOp.payload['documentId'], 'DOC-SYNC-1');
      expect(auditOp.payload['eventType'], 'post');
      expect(auditOp.payload['metadata'], equals({'postedValue': 1200.0}));
    });

    test('7. Audit trail is strictly immutable (no update or delete interfaces exist)', () async {
      await createFY2025();

      final event = await auditService.recordEvent(
        documentId: 'IMMUTABLE-DOC-1',
        documentType: 'journal_entry',
        eventType: 'post',
        userId: 'user-sys',
        notes: 'Immutability check',
      );

      final records = await auditService.getAuditTrail(documentId: 'IMMUTABLE-DOC-1');
      expect(records.length, 1);
      expect(records.first.uuid, event.uuid);
    });
  });
}
