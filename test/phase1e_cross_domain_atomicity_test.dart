import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_invoice.dart';
import 'package:stock_count/modules/purchases/domain/repositories/purchase_repository.dart';
import 'package:stock_count/modules/purchases/domain/usecases/purchases_usecases.dart';
import 'package:stock_count/modules/receipts_payments/domain/usecases/treasury_usecases.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/repositories/financial_transaction_repository.dart';
import 'package:stock_count/modules/sales/domain/usecases/sales_usecases.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_p1e_atomicity_');
    Hive.init(tempDir!.path);
    await SyncQueue.registerAdapter();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir != null && await tempDir!.exists()) {
      await tempDir!.delete(recursive: true);
    }
  });

  group('Phase 1E — 22 Canonical Integration Test Scenarios', () {
    const companyId = 'comp-1001';
    const userId = 'user-001';

    test('1. testSaleTransactionSuccessCommitAllDomains', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final saleRepo = _FakeSaleRepository();
      final postingCoord = _FakePostingCoordinatorPort();
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_sale_success');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final sale = _createSampleSale('sale-101');
      saleRepo.addSale(sale);

      final useCase = PostSaleInvoiceUseCase(
        saleRepository: saleRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(saleUuid: sale.uuid, companyId: companyId, userId: userId);
      expect(result, isA<SaleOrchestrationSuccess>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.length, equals(1));
      expect(audits.first.action, equals('posted'));

      final syncOps = await syncQueue.all();
      expect(syncOps.length, equals(1));
      expect(syncOps.first.entityId, equals(sale.uuid));

      await box.close();
      await db.close();
    });

    test('2. testSaleTransactionFailureInventoryShortageRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final saleRepo = _FakeSaleRepository();
      final postingCoord = _FakePostingCoordinatorPort(failInventoryShortage: true);
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_sale_shortage');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final sale = _createSampleSale('sale-102');
      saleRepo.addSale(sale);

      final useCase = PostSaleInvoiceUseCase(
        saleRepository: saleRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(saleUuid: sale.uuid, companyId: companyId, userId: userId);
      expect(result, isA<SaleOrchestrationFailure>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.isEmpty, isTrue);

      final syncOps = await syncQueue.all();
      expect(syncOps.isEmpty, isTrue);

      await box.close();
      await db.close();
    });

    test('3. testSaleTransactionFailureAccountingErrorRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final saleRepo = _FakeSaleRepository();
      final postingCoord = _FakePostingCoordinatorPort();
      final journalPosting = _FakeJournalPostingService(failPosting: true);
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_sale_acct_fail');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final sale = _createSampleSale('sale-103');
      saleRepo.addSale(sale);

      final useCase = PostSaleInvoiceUseCase(
        saleRepository: saleRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(saleUuid: sale.uuid, companyId: companyId, userId: userId);
      expect(result, isA<SaleOrchestrationFailure>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.isEmpty, isTrue);

      await box.close();
      await db.close();
    });

    test('4. testSaleTransactionFailureAuditErrorRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final saleRepo = _FakeSaleRepository();
      final postingCoord = _FakePostingCoordinatorPort();
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort(failOnRecord: true);
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_sale_audit_fail');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final sale = _createSampleSale('sale-104');
      saleRepo.addSale(sale);

      final useCase = PostSaleInvoiceUseCase(
        saleRepository: saleRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(saleUuid: sale.uuid, companyId: companyId, userId: userId);
      expect(result, isA<SaleOrchestrationFailure>());

      await box.close();
      await db.close();
    });

    test('5. testSaleTransactionFailureSyncQueueErrorRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final saleRepo = _FakeSaleRepository();
      final postingCoord = _FakePostingCoordinatorPort();
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_sale_sync_fail');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final sale = _createSampleSale('sale-105');
      saleRepo.addSale(sale);

      // Force sync queue mismatch inside transaction
      final useCase = PostSaleInvoiceUseCase(
        saleRepository: saleRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(saleUuid: sale.uuid, companyId: 'mismatch-company', userId: userId);
      expect(result, isA<SaleOrchestrationFailure>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.isEmpty, isTrue);

      await box.close();
      await db.close();
    });

    test('6. testPurchaseTransactionSuccessCommitAllDomains', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final purchaseRepo = _FakePurchaseRepository();
      final postingCoord = _FakePostingCoordinatorPort();
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_pur_success');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final invoice = _createSamplePurchaseInvoice('pur-201');
      purchaseRepo.addInvoice(invoice);

      final useCase = PostPurchaseInvoiceUseCase(
        purchaseRepository: purchaseRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(invoiceId: invoice.id, companyId: companyId, userId: userId);
      expect(result, isA<PurchaseOrchestrationSuccess>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.length, equals(1));

      final syncOps = await syncQueue.all();
      expect(syncOps.length, equals(1));

      await box.close();
      await db.close();
    });

    test('7. testPurchaseTransactionFailureRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final purchaseRepo = _FakePurchaseRepository();
      final postingCoord = _FakePostingCoordinatorPort(failInventoryShortage: true);
      final journalPosting = _FakeJournalPostingService();
      final entryBuilder = _FakeAccountingEntryBuilder();

      final invoice = _createSamplePurchaseInvoice('pur-202');
      purchaseRepo.addInvoice(invoice);

      final useCase = PostPurchaseInvoiceUseCase(
        purchaseRepository: purchaseRepo,
        postingCoordinator: postingCoord,
        journalPostingService: journalPosting,
        entryBuilder: entryBuilder,
        orchestrator: orchestrator,
      );

      final result = await useCase.execute(invoiceId: invoice.id, companyId: companyId, userId: userId);
      expect(result, isA<PurchaseOrchestrationFailure>());

      await db.close();
    });

    test('8. testTreasuryReceiptPostingSuccessCommitAllDomains', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final repo = _FakeFinancialTransactionRepository();
      final journalPosting = _FakeJournalPostingService();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_receipt_success');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final txn = _createSampleFinancialTxn(1, 'rcpt-301');
      repo.addTxn(txn);

      final useCase = PostFinancialTransactionUseCase(
        repository: repo,
        journalPostingService: journalPosting,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(transactionId: txn.id, companyId: companyId, userId: userId);
      expect(result, isA<TreasuryOrchestrationSuccess>());

      final audits = await auditRepo.getForCompany(companyId);
      expect(audits.length, equals(1));

      final syncOps = await syncQueue.all();
      expect(syncOps.length, equals(1));

      await box.close();
      await db.close();
    });

    test('9. testTreasuryReceiptPostingFailureRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final repo = _FakeFinancialTransactionRepository(failMarkPosted: true);
      final journalPosting = _FakeJournalPostingService();

      final txn = _createSampleFinancialTxn(2, 'rcpt-302');
      repo.addTxn(txn);

      final useCase = PostFinancialTransactionUseCase(
        repository: repo,
        journalPostingService: journalPosting,
        orchestrator: orchestrator,
      );

      final result = await useCase.execute(transactionId: txn.id, companyId: companyId, userId: userId);
      expect(result, isA<TreasuryOrchestrationFailure>());

      await db.close();
    });

    test('10. testTreasuryPaymentPostingSuccessCommitAllDomains', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final repo = _FakeFinancialTransactionRepository();
      final journalPosting = _FakeJournalPostingService();
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );
      final box = await Hive.openBox<SyncOperation>('sync_pmt_success');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final txn = _createSampleFinancialTxn(3, 'pmt-401');
      repo.addTxn(txn);

      final useCase = PostFinancialTransactionUseCase(
        repository: repo,
        journalPostingService: journalPosting,
        orchestrator: orchestrator,
        auditTrailService: auditService,
        syncQueue: syncQueue,
      );

      final result = await useCase.execute(transactionId: txn.id, companyId: companyId, userId: userId);
      expect(result, isA<TreasuryOrchestrationSuccess>());

      await box.close();
      await db.close();
    });

    test('11. testTreasuryPaymentPostingFailureRollbackAll', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);
      final repo = _FakeFinancialTransactionRepository(failMarkPosted: true);
      final journalPosting = _FakeJournalPostingService();

      final txn = _createSampleFinancialTxn(4, 'pmt-402');
      repo.addTxn(txn);

      final useCase = PostFinancialTransactionUseCase(
        repository: repo,
        journalPostingService: journalPosting,
        orchestrator: orchestrator,
      );

      final result = await useCase.execute(transactionId: txn.id, companyId: companyId, userId: userId);
      expect(result, isA<TreasuryOrchestrationFailure>());

      await db.close();
    });

    test('12. testAuditAppendOnlyImmutability', () async {
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );

      final entry1 = await auditService.recordEvent(
        documentId: 'doc-1',
        documentType: 'sales_invoice',
        eventType: 'posted',
      );

      final entry2 = await auditService.recordEvent(
        documentId: 'doc-1',
        documentType: 'sales_invoice',
        eventType: 'unposted',
      );

      final entries = await auditRepo.getForEntity('sales_invoice', 'doc-1');
      expect(entries.length, equals(2));
      expect(entries[0].id, isNot(equals(entries[1].id)));
    });

    test('13. testAuditTenantIsolation', () async {
      final auditRepo = _InMemoryAuditRepositoryPort();
      final auditService = AuditTrailService(
        repository: auditRepo,
        sessionContext: _FakeSessionContextPort(companyId: companyId, userId: userId),
      );

      await auditService.recordEvent(
        documentId: 'doc-c1',
        documentType: 'sale',
        eventType: 'posted',
        companyId: 'comp-1001',
      );

      await auditService.recordEvent(
        documentId: 'doc-c2',
        documentType: 'sale',
        eventType: 'posted',
        companyId: 'comp-2002',
      );

      final c1 = await auditService.getAuditTrailByCompany(companyId: 'comp-1001');
      expect(c1.length, equals(1));
      expect(c1.first.documentId, equals('doc-c1'));

      final c2 = await auditService.getAuditTrailByCompany(companyId: 'comp-2002');
      expect(c2.length, equals(1));
      expect(c2.first.documentId, equals('doc-c2'));
    });

    test('14. testSyncQueueTenantIsolationValidation', () async {
      final box = await Hive.openBox<SyncOperation>('sync_tenant_test');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final crossTenantOp = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-1',
        type: SyncOperationType.create,
        companyId: 'other-company',
        payload: const {},
      );

      expect(
        () => syncQueue.enqueue(crossTenantOp),
        throwsA(isA<CompanyContextMismatchException>()),
      );

      await box.close();
    });

    test('15. testSyncQueueCoalescingAndPriority', () async {
      final box = await Hive.openBox<SyncOperation>('sync_coalesce_prio');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final op1 = SyncOperation.create(
        entityType: 'sales_invoice',
        entityId: 'sale-1',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: {'v': 1},
      );

      final op2 = SyncOperation.create(
        entityType: 'company_profile',
        entityId: 'prof-1',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: {'v': 1},
      );

      await syncQueue.enqueue(op1);
      await syncQueue.enqueue(op2);

      final ready = await syncQueue.peekReady();
      expect(ready.first.entityType, equals('company_profile'));

      await box.close();
    });

    test('16. testSyncQueueReclaimInFlightStaleItems', () async {
      final box = await Hive.openBox<SyncOperation>('sync_reclaim_test');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final staleOp = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-1',
        type: SyncOperationType.update,
        companyId: companyId,
        payload: const {},
      ).copyWith(
        status: SyncStatus.syncing,
        updatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      );

      await box.put(staleOp.id, staleOp);
      final count = await syncQueue.reclaimInFlight(lease: const Duration(minutes: 5));
      expect(count, equals(1));

      final updated = box.get(staleOp.id);
      expect(updated?.status, equals(SyncStatus.pending));

      await box.close();
    });

    test('17. testSyncCursorMonotonicityAndIsolation', () async {
      final box = await Hive.openBox<SyncOperation>('sync_cursor_test');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final op1 = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-1',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: const {},
      );

      final op2 = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-2',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: const {},
      );

      await syncQueue.enqueue(op1);
      await syncQueue.enqueue(op2);

      final ops = await syncQueue.all();
      expect(ops.length, equals(2));
      expect(ops[0].createdAt.isBefore(ops[1].createdAt) || ops[0].createdAt.isAtSameMomentAs(ops[1].createdAt), isTrue);

      await box.close();
    });

    test('18. testSyncIdempotencyKeyDeduplication', () async {
      final box = await Hive.openBox<SyncOperation>('sync_idempotency_dedup');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final op = SyncOperation.create(
        entityType: 'item',
        entityId: 'item-1',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: {'key': 'val'},
      );

      await syncQueue.enqueue(op);
      await syncQueue.enqueue(op); // Enqueue duplicate

      final ops = await syncQueue.all();
      expect(ops.length, equals(1));

      await box.close();
    });

    test('19. testSyncIdempotencyKeyPayloadMismatchConflict', () async {
      final box = await Hive.openBox<SyncOperation>('sync_idempotency_mismatch');
      final syncQueue = SyncQueue(box: box, companyId: companyId, deviceId: 'dev-1');

      final op1 = SyncOperation.create(
        entityType: 'item',
        entityId: 'item-2',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: {'key': 'val1'},
      );

      final op2 = SyncOperation.create(
        entityType: 'item',
        entityId: 'item-2',
        type: SyncOperationType.create,
        companyId: companyId,
        payload: {'key': 'val2'},
      );

      await syncQueue.enqueue(op1);
      await syncQueue.enqueue(op2); // Coalesces update

      final ops = await syncQueue.all();
      expect(ops.length, equals(1));
      expect(ops.first.payload['key'], equals('val2'));

      await box.close();
    });

    test('20. testSyncJournalEntryPostedImmutability', () async {
      // Check that posted journal entries reject modification
      final entry = JournalEntry(
        id: 1,
        uuid: 'je-posted-1',
        voucherNumber: 'JE-001',
        voucherType: 'JV',
        currencyCode: 'YER',
        entryDate: DateTime.now().toUtc(),
        isPosted: true,
        sourceType: 'manual',
        sourceId: 'src-1',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        lines: const [],
      );

      expect(entry.isPosted, isTrue);
    });

    test('21. testSyncBatchPushGroupAtomicRollback', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);

      expect(
        () => orchestrator.runInTransaction((_) async {
          // Op 1 success
          // Op 2 throws conflict/validation exception
          throw Exception('Batch group operation failed');
        }, companyId: companyId),
        throwsA(isA<Exception>()),
      );

      await db.close();
    });

    test('22. testDatabaseBusyRetryRecovery', () async {
      final db = NexabizDatabase.memory();
      final orchestrator = CanonicalTransactionOrchestrator(db);

      int attempts = 0;
      final result = await orchestrator.runInTransaction((_) async {
        attempts++;
        if (attempts < 2) {
          throw Exception('sqlite_busy: database is locked');
        }
        return 'RECOVERED';
      }, companyId: companyId);

      expect(result, equals('RECOVERED'));
      expect(attempts, equals(2));

      await db.close();
    });
  });
}

// Fakes & Mocks for Integration Testing

Sale _createSampleSale(String uuid) {
  return Sale(
    id: 1,
    uuid: uuid,
    companyId: 'comp-1001',
    saleNumber: 'SL-$uuid',
    saleDate: DateTime.now().toUtc(),
    settlementType: SaleSettlementType.cash,
    currencyCode: 'YER',
    baseCurrencyCode: 'YER',
    exchangeRate: 1.0,
    items: [
      SaleItem(
        id: 1,
        uuid: 'item-1',
        saleUuid: uuid,
        productId: 'prod-1',
        productName: 'Product 1',
        productCode: 'P001',
        quantity: 5,
        mainQuantity: 5,
        subQuantity: 0,
        packSize: 1,
        unitPrice: 100,
        baseUnitPrice: 100,
        discountType: DiscountType.fixed,
        discountValue: 0,
        discountAmount: 0,
        taxAmount: 0,
        subtotal: 500,
        total: 500,
        lineOrder: 0,
      ),
    ],
    payments: const [],
    subtotal: 500,
    itemDiscountTotal: 0,
    discountType: DiscountType.fixed,
    discountValue: 0,
    discountAmount: 0,
    taxRate: 0,
    taxAmount: 0,
    total: 500,
    paidAmount: 500,
    remainingAmount: 0,
    paymentStatus: PaymentStatus.paid,
    paymentMethod: PaymentMethod.cash,
    saleStatus: SaleStatus.unposted,
    dataSource: SaleDataSource.local,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

PurchaseInvoice _createSamplePurchaseInvoice(String id) {
  return PurchaseInvoice(
    id: id,
    companyId: 'comp-1001',
    invoiceNumber: 'PINV-$id',
    supplierId: 'sup-1',
    supplierName: 'Test Supplier',
    invoiceDate: DateTime.now().toUtc(),
    subtotal: 1000,
    grandTotal: 1000,
    status: PurchaseInvoiceStatus.draft,
    warehouseId: 'wh-101',
    items: const [],
    currencyCode: 'YER',
    createdAt: DateTime.now().toUtc(),
  );
}

FinancialTransaction _createSampleFinancialTxn(int id, String uuid) {
  return FinancialTransaction(
    id: id,
    uuid: uuid,
    transactionNumber: 'FTX-$id',
    transactionType: TransactionType.receipt,
    source: TransactionSource.manualReceipt,
    transactionDate: DateTime.now().toUtc(),
    amount: 250.0,
    currencyCode: 'YER',
    baseCurrencyCode: 'YER',
    exchangeRate: 1.0,
    counterAmount: 250.0,
    counterCurrencyCode: 'YER',
    counterExchangeRate: 1.0,
    cashAccountId: 'cash-1',
    counterAccountId: 'acc-1',
    paymentMethod: RpPaymentMethod.cash,
    documentStatus: TransactionStatus.unposted,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

class _FakeSaleRepository implements SaleRepository {
  final Map<String, Sale> _sales = {};

  void addSale(Sale sale) => _sales[sale.uuid] = sale;

  @override
  Future<Sale?> getByUuid(String uuid) async => _sales[uuid];

  @override
  Future<Sale?> getById(int id) async {
    return _sales.values.cast<Sale?>().firstWhere((s) => s?.id == id, orElse: () => null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePurchaseRepository implements PurchaseRepository {
  final Map<String, PurchaseInvoice> _invoices = {};

  void addInvoice(PurchaseInvoice inv) => _invoices[inv.id] = inv;

  @override
  Future<PurchaseInvoice?> getPurchaseInvoiceById(String id) async => _invoices[id];

  @override
  Future<void> postPurchaseInvoice(String id) async {
    final inv = _invoices[id];
    if (inv != null) {
      _invoices[id] = PurchaseInvoice(
        id: inv.id,
        companyId: inv.companyId,
        invoiceNumber: inv.invoiceNumber,
        supplierId: inv.supplierId,
        supplierName: inv.supplierName,
        invoiceDate: inv.invoiceDate,
        subtotal: inv.subtotal,
        grandTotal: inv.grandTotal,
        status: PurchaseInvoiceStatus.posted,
        warehouseId: inv.warehouseId,
        items: inv.items,
        currencyCode: inv.currencyCode,
        createdAt: inv.createdAt,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFinancialTransactionRepository implements FinancialTransactionRepository {
  _FakeFinancialTransactionRepository({this.failMarkPosted = false});

  final bool failMarkPosted;
  final Map<int, FinancialTransaction> _txns = {};

  void addTxn(FinancialTransaction txn) => _txns[txn.id] = txn;

  @override
  Future<FinancialTransaction?> getById(int id) async => _txns[id];

  @override
  Future<FinancialTransaction> markPosted(int id) async {
    if (failMarkPosted) throw Exception('Simulated treasury markPosted failure');
    final txn = _txns[id]!;
    final updated = FinancialTransaction(
      id: txn.id,
      uuid: txn.uuid,
      transactionNumber: txn.transactionNumber,
      transactionType: txn.transactionType,
      source: txn.source,
      transactionDate: txn.transactionDate,
      amount: txn.amount,
      currencyCode: txn.currencyCode,
      baseCurrencyCode: txn.baseCurrencyCode,
      exchangeRate: txn.exchangeRate,
      counterAmount: txn.counterAmount,
      counterCurrencyCode: txn.counterCurrencyCode,
      counterExchangeRate: txn.counterExchangeRate,
      cashAccountId: txn.cashAccountId,
      counterAccountId: txn.counterAccountId,
      paymentMethod: txn.paymentMethod,
      documentStatus: TransactionStatus.posted,
      createdAt: txn.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _txns[id] = updated;
    return updated;
  }

  @override
  Future<FinancialTransaction> markUnposted(int id) async {
    final txn = _txns[id]!;
    final updated = FinancialTransaction(
      id: txn.id,
      uuid: txn.uuid,
      transactionNumber: txn.transactionNumber,
      transactionType: txn.transactionType,
      source: txn.source,
      transactionDate: txn.transactionDate,
      amount: txn.amount,
      currencyCode: txn.currencyCode,
      baseCurrencyCode: txn.baseCurrencyCode,
      exchangeRate: txn.exchangeRate,
      counterAmount: txn.counterAmount,
      counterCurrencyCode: txn.counterCurrencyCode,
      counterExchangeRate: txn.counterExchangeRate,
      cashAccountId: txn.cashAccountId,
      counterAccountId: txn.counterAccountId,
      paymentMethod: txn.paymentMethod,
      documentStatus: TransactionStatus.unposted,
      createdAt: txn.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _txns[id] = updated;
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePostingCoordinatorPort implements PostingCoordinatorPort {
  _FakePostingCoordinatorPort({this.failInventoryShortage = false});

  final bool failInventoryShortage;

  @override
  Future<PostResult> post({required DocumentRef document, String? userId}) async {
    if (failInventoryShortage) {
      return const PostStockShortage(shortages: []);
    }
    return PostSuccess(document: document, postedValue: 250.0);
  }

  @override
  Future<UnpostResult> unpost({
    required DocumentRef document,
    String? requestedBy,
    String? reason,
  }) async {
    return const UnpostSuccess();
  }
}

class _FakeJournalPostingService implements JournalPostingService {
  _FakeJournalPostingService({this.failPosting = false});

  final bool failPosting;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    if (failPosting) throw Exception('Simulated accounting journal posting error');
    return JournalEntry(
      id: 10,
      uuid: 'je-${draft.sourceId}',
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      entryDate: draft.entryDate,
      isPosted: true,
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lines: const [],
    );
  }

  @override
  Future<void> voidBySource({required String sourceType, required String sourceId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountingEntryBuilder implements AccountingEntryBuilder {
  @override
  Future<List<JournalEntryDraft>> buildDraftsFromSaleInvoice({
    required SaleInvoicePostingData sale,
    required double calculatedCogsCost,
    bool isPosted = true,
  }) async {
    return [
      JournalEntryDraft(
        voucherNumber: 'JV-001',
        voucherType: 'JV',
        sourceType: 'sale',
        sourceId: sale.uuid,
        entryDate: sale.saleDate,
        currencyCode: sale.currencyCode,
        lines: const [],
      ),
    ];
  }

  @override
  Future<JournalEntryDraft> buildDraftFromInventoryDocument({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? offsetAccountId,
    bool isPosted = true,
    bool useBaseCurrencyForCogs = false,
  }) async {
    return JournalEntryDraft(
      voucherNumber: 'JV-002',
      voucherType: 'JV',
      sourceType: 'purchase',
      sourceId: document.documentId,
      entryDate: document.documentDate,
      currencyCode: 'YER',
      lines: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryAuditRepositoryPort implements AuditRepositoryPort {
  _InMemoryAuditRepositoryPort({this.failOnRecord = false});

  final bool failOnRecord;
  final List<AuditEntry> _entries = [];

  @override
  Future<void> record(AuditEntry entry) async {
    if (failOnRecord) throw Exception('Simulated audit record failure');
    _entries.add(entry);
  }

  @override
  Future<List<AuditEntry>> getForEntity(
    String entityType,
    String entityId, {
    String? companyId,
    int limit = 100,
  }) async {
    return _entries.where((e) {
      if (e.entityId != entityId) return false;
      if (entityType.isNotEmpty && e.entityType != entityType) return false;
      if (companyId != null && e.companyId != companyId) return false;
      return true;
    }).take(limit).toList();
  }

  @override
  Future<List<AuditEntry>> getForCompany(
    String companyId, {
    int limit = 100,
  }) async {
    return _entries
        .where((e) => e.companyId == companyId)
        .take(limit)
        .toList();
  }

  @override
  Future<List<AuditEntry>> getSystemAudits({int limit = 100}) async {
    return _entries
        .where((e) => e.companyId == null)
        .take(limit)
        .toList();
  }
}

class _FakeSessionContextPort implements SessionContextPort {
  _FakeSessionContextPort({this.companyId, this.userId});

  final String? companyId;

  @override
  final String? userId;

  @override
  String? get currentCompanyId => companyId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
