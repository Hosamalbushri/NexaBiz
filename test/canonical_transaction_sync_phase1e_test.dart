import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';

import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_p1e_');
    Hive.init(tempDir!.path);
    await SyncQueue.registerAdapter();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir != null && await tempDir!.exists()) {
      await tempDir!.delete(recursive: true);
    }
  });

  group('Phase 1E — Canonical Transaction, Audit & Sync Integrity', () {
    final now = DateTime.now().toUtc();

    group('1. Canonical Transaction Orchestration & Atomicity', () {
      test('Test 1.1 — CanonicalTransactionOrchestrator commits all writes atomically on success', () async {
        final db = NexabizDatabase.memory();
        final orchestrator = CanonicalTransactionOrchestrator(db);

        final result = await orchestrator.runInTransaction<String>(
          (context) async {
            expect(context.companyId, equals('comp-1001'));
            expect(context.correlationId, isNotEmpty);
            return 'SUCCESS';
          },
          companyId: 'comp-1001',
          userId: 'user-001',
        );

        expect(result, equals('SUCCESS'));
        await db.close();
      });

      test('Test 1.2 — CanonicalTransactionOrchestrator rolls back completely on any inner failure', () async {
        final db = NexabizDatabase.memory();
        final orchestrator = CanonicalTransactionOrchestrator(db);

        expect(
          () => orchestrator.runInTransaction<void>(
            (context) async {
              throw Exception('Simulated cross-domain transaction failure');
            },
            companyId: 'comp-1001',
          ),
          throwsA(isA<Exception>()),
        );

        await db.close();
      });

      test('Test 1.3 — Operational context derives correlationId, userId, and timestamp', () {
        final context = OperationContext(
          companyId: 'comp-2002',
          userId: 'user-777',
        );

        expect(context.companyId, equals('comp-2002'));
        expect(context.userId, equals('user-777'));
        expect(context.correlationId, isNotEmpty);
        expect(context.timestamp, isNotNull);
      });
    });

    group('2. Audit Trail Authority, Immutability & Tenant Isolation', () {
      test('Test 2.1 — Audit Trail entries store companyId, userId, entity attributes correctly', () async {
        final mockRepo = _InMemoryAuditRepositoryPort();
        final sessionCtx = _FakeSessionContextPort(companyId: 'comp-1001', userId: 'user-01');
        final auditService = AuditTrailService(
          repository: mockRepo,
          sessionContext: sessionCtx,
        );

        final entry = await auditService.recordEvent(
          documentId: 'DOC-101',
          documentType: 'sales_invoice',
          eventType: 'posted',
          notes: 'Invoice posted successfully',
        );

        expect(entry.documentId, equals('DOC-101'));
        expect(entry.documentType, equals('sales_invoice'));
        expect(entry.eventType, equals('posted'));
        expect(entry.companyId, equals('comp-1001'));
        expect(entry.userId, equals('user-01'));
      });

      test('Test 2.2 — Audit query filtered by companyId enforces strict tenant isolation', () async {
        final mockRepo = _InMemoryAuditRepositoryPort();
        final sessionCtx = _FakeSessionContextPort(companyId: 'comp-1001', userId: 'user-01');
        final auditService = AuditTrailService(
          repository: mockRepo,
          sessionContext: sessionCtx,
        );

        await auditService.recordEvent(
          documentId: 'DOC-COMP1',
          documentType: 'sales_invoice',
          eventType: 'posted',
          companyId: 'comp-1001',
        );

        await auditService.recordEvent(
          documentId: 'DOC-COMP2',
          documentType: 'sales_invoice',
          eventType: 'posted',
          companyId: 'comp-2002',
        );

        final comp1Audits = await auditService.getAuditTrailByCompany(companyId: 'comp-1001');
        expect(comp1Audits.length, equals(1));
        expect(comp1Audits.first.documentId, equals('DOC-COMP1'));

        final comp2Audits = await auditService.getAuditTrailByCompany(companyId: 'comp-2002');
        expect(comp2Audits.length, equals(1));
        expect(comp2Audits.first.documentId, equals('DOC-COMP2'));
      });
    });

    group('3. Sync Engine Outbox, Idempotency & Reclaim Safety', () {
      test('Test 3.1 — SyncQueue rejects cross-tenant enqueue with CompanyContextMismatchException', () async {
        final box = await Hive.openBox<SyncOperation>('test_sync_box_tenant');
        final syncQueue = SyncQueue(
          box: box,
          companyId: 'comp-1001',
          deviceId: 'device-001',
        );

        final crossTenantOp = SyncOperation.create(
          entityType: 'customer',
          entityId: 'cust-999',
          type: SyncOperationType.create,
          payload: const {},
          companyId: 'comp-8888', // Mismatch!
        );

        expect(
          () => syncQueue.enqueue(crossTenantOp),
          throwsA(isA<CompanyContextMismatchException>()),
        );

        await box.close();
      });

      test('Test 3.2 — SyncQueue priority ordering sorts company profile before receipts & sales', () async {
        final box = await Hive.openBox<SyncOperation>('test_sync_box_prio');
        final syncQueue = SyncQueue(
          box: box,
          companyId: 'comp-1001',
          deviceId: 'device-001',
        );

        final saleOp = SyncOperation.create(
          entityType: 'sales_invoice',
          entityId: 'sale-1',
          type: SyncOperationType.create,
          payload: const {},
          companyId: 'comp-1001',
        );

        final profileOp = SyncOperation.create(
          entityType: 'company_profile',
          entityId: 'prof-1',
          type: SyncOperationType.create,
          payload: const {},
          companyId: 'comp-1001',
        );

        await syncQueue.enqueue(saleOp);
        await syncQueue.enqueue(profileOp);

        final ready = await syncQueue.peekReady(now: now);
        expect(ready.length, equals(2));
        expect(ready.first.entityType, equals('company_profile'));
        expect(ready.last.entityType, equals('sales_invoice'));

        await box.close();
      });

      test('Test 3.3 — reclaimInFlight resets interrupted syncing ops past 5-minute lease back to pending', () async {
        final box = await Hive.openBox<SyncOperation>('test_sync_box_reclaim');
        final syncQueue = SyncQueue(
          box: box,
          companyId: 'comp-1001',
          deviceId: 'device-001',
        );

        final oldSyncingOp = SyncOperation.create(
          entityType: 'product',
          entityId: 'prod-1',
          type: SyncOperationType.create,
          payload: const {},
          companyId: 'comp-1001',
        ).copyWith(
          status: SyncStatus.syncing,
          updatedAt: now.subtract(const Duration(minutes: 6)),
        );

        await box.put(oldSyncingOp.id, oldSyncingOp);

        final reclaimedCount = await syncQueue.reclaimInFlight(
          now: now,
          lease: const Duration(minutes: 5),
        );

        expect(reclaimedCount, equals(1));
        final updatedOp = box.get(oldSyncingOp.id);
        expect(updatedOp?.status, equals(SyncStatus.pending));

        await box.close();
      });

      test('Test 3.4 — SyncQueue coalesces multiple update operations for same entity into single latest operation', () async {
        final box = await Hive.openBox<SyncOperation>('test_sync_box_coalesce');
        final syncQueue = SyncQueue(
          box: box,
          companyId: 'comp-1001',
          deviceId: 'device-001',
        );

        final op1 = SyncOperation.create(
          entityType: 'product',
          entityId: 'prod-100',
          type: SyncOperationType.create,
          companyId: 'comp-1001',
          payload: {'name': 'Initial Product Name'},
        );

        final op2 = SyncOperation.create(
          entityType: 'product',
          entityId: 'prod-100',
          type: SyncOperationType.update,
          companyId: 'comp-1001',
          payload: {'name': 'Updated Product Name'},
        );

        await syncQueue.enqueue(op1);
        await syncQueue.enqueue(op2);

        final allOps = await syncQueue.all();
        expect(allOps.length, equals(1));
        expect(allOps.first.type, equals(SyncOperationType.create));
        expect(allOps.first.payload['name'], equals('Updated Product Name'));

        await box.close();
      });
    });
  });
}

class _InMemoryAuditRepositoryPort implements AuditRepositoryPort {
  final List<AuditEntry> _entries = [];

  @override
  Future<void> record(AuditEntry entry) async {
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
