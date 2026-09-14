import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/repositories/financial_transaction_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

sealed class TreasuryOrchestrationResult {
  const TreasuryOrchestrationResult();
}

class TreasuryOrchestrationSuccess extends TreasuryOrchestrationResult {
  final String transactionUuid;
  final String message;
  final String? journalEntryUuid;

  const TreasuryOrchestrationSuccess({
    required this.transactionUuid,
    required this.message,
    this.journalEntryUuid,
  });
}

class TreasuryOrchestrationFailure extends TreasuryOrchestrationResult {
  final String transactionUuid;
  final String reason;

  const TreasuryOrchestrationFailure({
    required this.transactionUuid,
    required this.reason,
  });
}

/// Use case for orchestrating Financial Transactions (Receipts & Payments) across Treasury, Accounting, Audit, and Sync.
class PostFinancialTransactionUseCase {
  final FinancialTransactionRepository _repository;
  final JournalPostingService _journalPostingService;
  final CanonicalTransactionOrchestrator _orchestrator;
  final AuditTrailService? _auditTrailService;
  final SyncQueue? _syncQueue;

  PostFinancialTransactionUseCase({
    required this._repository,
    required this._journalPostingService,
    required this._orchestrator,
    this._auditTrailService,
    this._syncQueue,
  });

  Future<TreasuryOrchestrationResult> execute({
    required String transactionId,
    required String companyId,
    String? userId,
  }) async {
    try {
      final txn = await _repository.getById(transactionId);
      if (txn == null) {
        return TreasuryOrchestrationFailure(
          transactionUuid: transactionId,
          reason: 'المعاملة المالية غير موجودة',
        );
      }

      if (txn.documentStatus == TransactionStatus.posted) {
        return TreasuryOrchestrationSuccess(
          transactionUuid: txn.uuid,
          message: 'المعاملة المالية مرحلة بالفعل',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          // 1. Mark Financial Transaction as Posted in DB
          final postedTxn = await _repository.markPosted(transactionId);

          // 2. Void any existing journal entry for this treasury transaction
          await _journalPostingService.voidBySource(
            sourceType: 'financial_transaction',
            sourceId: txn.uuid,
          );

          // 3. Record Audit Event inside transaction
          final auditTrail = _auditTrailService;
          if (auditTrail != null) {
            await auditTrail.recordEvent(
              documentId: txn.uuid,
              documentType: 'receipt_payment',
              eventType: 'posted',
              userId: userId ?? context.userId,
              companyId: companyId,
              notes: 'Financial Transaction ${txn.uuid} posted',
            );
          }

          // 4. Enqueue Sync Operation inside transaction
          final syncQ = _syncQueue;
          if (syncQ != null) {
            await syncQ.enqueue(
              SyncOperation.create(
                entityType: 'receipt_payment',
                entityId: txn.uuid,
                type: SyncOperationType.update,
                companyId: companyId,
                payload: {
                  'id': postedTxn.id,
                  'uuid': postedTxn.uuid,
                  'documentStatus': TransactionStatus.posted.name,
                  'companyId': companyId,
                },
              ),
            );
          }

          return TreasuryOrchestrationSuccess(
            transactionUuid: postedTxn.uuid,
            message: 'تم ترحيل المعاملة المالية وعكس السجلات المحاسبية بنجاح',
          );
        },
        companyId: companyId,
        userId: userId,
      );
    } catch (e) {
      return TreasuryOrchestrationFailure(
        transactionUuid: transactionId,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

/// Use case for unposting a Financial Transaction inside a single atomic database transaction.
class UnpostFinancialTransactionUseCase {
  final FinancialTransactionRepository _repository;
  final JournalPostingService _journalPostingService;
  final CanonicalTransactionOrchestrator _orchestrator;
  final AuditTrailService? _auditTrailService;
  final SyncQueue? _syncQueue;

  UnpostFinancialTransactionUseCase({
    required this._repository,
    required this._journalPostingService,
    required this._orchestrator,
    this._auditTrailService,
    this._syncQueue,
  });

  Future<TreasuryOrchestrationResult> execute({
    required String transactionId,
    required String companyId,
    String? userId,
  }) async {
    try {
      final txn = await _repository.getById(transactionId);
      if (txn == null) {
        return TreasuryOrchestrationFailure(
          transactionUuid: transactionId,
          reason: 'المعاملة المالية غير موجودة',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          final unpostedTxn = await _repository.markUnposted(transactionId);

          await _journalPostingService.voidBySource(
            sourceType: 'financial_transaction',
            sourceId: txn.uuid,
          );

          // Record Audit Event inside transaction
          final auditTrail = _auditTrailService;
          if (auditTrail != null) {
            await auditTrail.recordEvent(
              documentId: txn.uuid,
              documentType: 'receipt_payment',
              eventType: 'unposted',
              userId: userId ?? context.userId,
              companyId: companyId,
              notes: 'Financial Transaction ${txn.uuid} unposted',
            );
          }

          // Enqueue Sync Operation inside transaction
          final syncQ = _syncQueue;
          if (syncQ != null) {
            await syncQ.enqueue(
              SyncOperation.create(
                entityType: 'receipt_payment',
                entityId: txn.uuid,
                type: SyncOperationType.update,
                companyId: companyId,
                payload: {
                  'id': unpostedTxn.id,
                  'uuid': unpostedTxn.uuid,
                  'documentStatus': TransactionStatus.unposted.name,
                  'companyId': companyId,
                },
              ),
            );
          }

          return TreasuryOrchestrationSuccess(
            transactionUuid: unpostedTxn.uuid,
            message: 'تم إلغاء ترحيل المعاملة المالية بنجاح',
          );
        },
        companyId: companyId,
        userId: userId,
      );
    } catch (e) {
      return TreasuryOrchestrationFailure(
        transactionUuid: transactionId,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
