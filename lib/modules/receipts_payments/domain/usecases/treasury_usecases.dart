import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/repositories/financial_transaction_repository.dart';

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

  PostFinancialTransactionUseCase({
    required FinancialTransactionRepository repository,
    required JournalPostingService journalPostingService,
    required CanonicalTransactionOrchestrator orchestrator,
  })  : _repository = repository,
        _journalPostingService = journalPostingService,
        _orchestrator = orchestrator;

  Future<TreasuryOrchestrationResult> execute({
    required int transactionId,
    required String companyId,
    String? userId,
  }) async {
    try {
      final txn = await _repository.getById(transactionId);
      if (txn == null) {
        return TreasuryOrchestrationFailure(
          transactionUuid: transactionId.toString(),
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
        transactionUuid: transactionId.toString(),
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

  UnpostFinancialTransactionUseCase({
    required FinancialTransactionRepository repository,
    required JournalPostingService journalPostingService,
    required CanonicalTransactionOrchestrator orchestrator,
  })  : _repository = repository,
        _journalPostingService = journalPostingService,
        _orchestrator = orchestrator;

  Future<TreasuryOrchestrationResult> execute({
    required int transactionId,
    required String companyId,
    String? userId,
  }) async {
    try {
      final txn = await _repository.getById(transactionId);
      if (txn == null) {
        return TreasuryOrchestrationFailure(
          transactionUuid: transactionId.toString(),
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
        transactionUuid: transactionId.toString(),
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
