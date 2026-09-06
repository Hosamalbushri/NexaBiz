import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import '../entities/financial_transaction.dart';
import '../entities/transaction_dashboard_summary.dart';
import '../entities/transaction_list_item.dart';
import '../entities/transaction_status.dart';
import '../models/financial_transaction_exception.dart';
import '../models/transaction_list_filter.dart';
import '../models/transaction_paged_result.dart';
import '../repositories/financial_transaction_repository.dart';
import '../services/financial_transaction_validator.dart';
import '../services/financial_transaction_workflow.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';

class GetFinancialTransactionById {
  const GetFinancialTransactionById(this._repository);

  final FinancialTransactionRepository _repository;

  Future<FinancialTransaction?> call(int id) => _repository.getById(id);
}

class SearchFinancialTransactions {
  const SearchFinancialTransactions(this._repository);

  final FinancialTransactionRepository _repository;

  Future<TransactionPagedResult<TransactionListItem>> call({
    TransactionListFilter filter = const TransactionListFilter(),
    int page = 0,
    int pageSize = 30,
  }) {
    return _repository.searchListPaged(
      filter: filter,
      page: page,
      pageSize: pageSize,
    );
  }
}

class GetTransactionDashboard {
  const GetTransactionDashboard(this._repository);

  final FinancialTransactionRepository _repository;

  Future<TransactionDashboardSummary> call({
    required DateTime periodFrom,
    required DateTime periodTo,
    required DateTime todayStart,
    required DateTime todayEnd,
  }) {
    return _repository.dashboardSummary(
      periodFrom: periodFrom,
      periodTo: periodTo,
      todayStart: todayStart,
      todayEnd: todayEnd,
    );
  }
}

class CreateFinancialTransaction {
  CreateFinancialTransaction({
    required this.repository,
    required PermissionGuard permissionGuard,
    this.voucherBookPort = const NoOpRpVoucherBookPort(),
    this.ledgerPosting = const NoOpRpLedgerPostingPort(),
    this.validator = const FinancialTransactionValidator(),
  }) : _guard = permissionGuard;

  final FinancialTransactionRepository repository;
  final PermissionGuard _guard;
  final RpVoucherBookPort voucherBookPort;
  final RpLedgerPostingPort ledgerPosting;
  final FinancialTransactionValidator validator;

  Future<FinancialTransaction> call(FinancialTransactionDraft draft) async {
    final merged = normalizeFinancialTransactionDraft(draft);
    _guard.requireAny(
      ReceiptsPaymentsPermissions.createFor(merged.transactionType),
    );
    validator.validate(merged);
    final bookId = merged.voucherBookId?.trim();
    if (bookId == null || bookId.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.voucherBookRequired,
      );
    }
    final number = await voucherBookPort.allocateNumber(
      bookId: bookId,
      type: merged.transactionType,
    );
    final created = await repository.insert(merged, transactionNumber: number);
    try {
      await ledgerPosting.syncTransaction(created);
    } on JournalException {
      await repository.softDelete(created.id);
      rethrow;
    } catch (_) {
      await repository.softDelete(created.id);
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return created;
  }
}

class UpdateFinancialTransaction {
  UpdateFinancialTransaction({
    required this.repository,
    this.validator = const FinancialTransactionValidator(),
    this.workflow = const FinancialTransactionWorkflow(),
    this.ledgerPosting = const NoOpRpLedgerPostingPort(),
  });

  final FinancialTransactionRepository repository;
  final FinancialTransactionValidator validator;
  final FinancialTransactionWorkflow workflow;
  final RpLedgerPostingPort ledgerPosting;

  Future<FinancialTransaction> call(
    int id,
    FinancialTransactionDraft draft,
  ) async {
    final existing = await repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    workflow.assertCanEdit(existing);
    final merged = normalizeFinancialTransactionDraft(
      FinancialTransactionDraft(
        transactionType: existing.transactionType,
        source: draft.source,
        transactionDate: draft.transactionDate,
        amount: draft.amount,
        currencyCode: draft.currencyCode,
        baseCurrencyCode: draft.baseCurrencyCode,
        exchangeRate: draft.exchangeRate,
        counterAmount: draft.counterAmount,
        counterCurrencyCode: draft.counterCurrencyCode,
        counterExchangeRate: draft.counterExchangeRate,
        voucherBookId: existing.voucherBookId,
        cashAccountId: draft.cashAccountId,
        cashAccountCode: draft.cashAccountCode,
        cashAccountName: draft.cashAccountName,
        counterAccountId: draft.counterAccountId,
        counterAccountCode: draft.counterAccountCode,
        counterAccountName: draft.counterAccountName,
        customerId: draft.customerId,
        customerCode: draft.customerCode,
        customerName: draft.customerName,
        partyName: draft.partyName,
        reference: draft.reference,
        description: draft.description,
        paymentMethod: draft.paymentMethod,
        relatedDocumentId: draft.relatedDocumentId,
        relatedDocumentType: draft.relatedDocumentType,
        documentStatus: existing.documentStatus,
        externalId: draft.externalId,
        lines: draft.lines,
      ),
    );
    validator.validate(merged);
    final updated = await repository.update(id, merged);
    try {
      await ledgerPosting.syncTransaction(updated);
    } on JournalException {
      rethrow;
    } catch (_) {
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return updated;
  }
}

class PostFinancialTransaction {
  PostFinancialTransaction({
    required this.repository,
    required PermissionGuard permissionGuard,
    this.workflow = const FinancialTransactionWorkflow(),
    this.ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _guard = permissionGuard;

  final FinancialTransactionRepository repository;
  final PermissionGuard _guard;
  final FinancialTransactionWorkflow workflow;
  final RpLedgerPostingPort ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _guard.requireAny(
      ReceiptsPaymentsPermissions.postFor(existing.transactionType),
    );
    workflow.assertCanPost(existing);
    final posted = await repository.markPosted(id);
    try {
      await ledgerPosting.syncTransaction(posted);
    } catch (e) {
      await repository.update(
        id,
        FinancialTransactionDraft(
          transactionType: existing.transactionType,
          source: existing.source,
          transactionDate: existing.transactionDate,
          amount: existing.amount,
          currencyCode: existing.currencyCode,
          baseCurrencyCode: existing.baseCurrencyCode,
          exchangeRate: existing.exchangeRate,
          counterAmount: existing.counterAmount > 0
              ? existing.counterAmount
              : existing.amount,
          counterCurrencyCode: existing.counterCurrencyCode.trim().isEmpty
              ? existing.currencyCode
              : existing.counterCurrencyCode,
          counterExchangeRate: existing.counterExchangeRate <= 0
              ? existing.exchangeRate
              : existing.counterExchangeRate,
          voucherBookId: existing.voucherBookId,
          cashAccountId: existing.cashAccountId,
          cashAccountCode: existing.cashAccountCode,
          cashAccountName: existing.cashAccountName,
          counterAccountId: existing.counterAccountId,
          counterAccountCode: existing.counterAccountCode,
          counterAccountName: existing.counterAccountName,
          customerId: existing.customerId,
          customerCode: existing.customerCode,
          customerName: existing.customerName,
          partyName: existing.partyName,
          reference: existing.reference,
          description: existing.description,
          paymentMethod: existing.paymentMethod,
          relatedDocumentId: existing.relatedDocumentId,
          relatedDocumentType: existing.relatedDocumentType,
          documentStatus: TransactionStatus.unposted,
          externalId: existing.externalId,
          lines: existing.lines,
        ),
      );
      if (e is JournalException) {
        rethrow;
      }
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return posted;
  }
}

class UnpostFinancialTransaction {
  UnpostFinancialTransaction({
    required this.repository,
    this.workflow = const FinancialTransactionWorkflow(),
    this.ledgerPosting = const NoOpRpLedgerPostingPort(),
  });

  final FinancialTransactionRepository repository;
  final FinancialTransactionWorkflow workflow;
  final RpLedgerPostingPort ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    workflow.assertCanUnpost(existing);
    final unposted = await repository.markUnposted(id);
    try {
      await ledgerPosting.syncTransaction(unposted);
    } on JournalException {
      await repository.markPosted(id);
      rethrow;
    } catch (_) {
      await repository.markPosted(id);
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return unposted;
  }
}

class CancelFinancialTransaction {
  CancelFinancialTransaction({
    required this.repository,
    required PermissionGuard permissionGuard,
    this.workflow = const FinancialTransactionWorkflow(),
    this.ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _guard = permissionGuard;

  final FinancialTransactionRepository repository;
  final PermissionGuard _guard;
  final FinancialTransactionWorkflow workflow;
  final RpLedgerPostingPort ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _guard.requireAny(
      ReceiptsPaymentsPermissions.cancelFor(existing.transactionType),
    );
    workflow.assertCanCancel(existing);
    await ledgerPosting.voidTransaction(existing);
    return repository.markCancelled(id);
  }
}
