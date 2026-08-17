import '../../../accounting/domain/models/journal_exception.dart';
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
import '../services/rp_ledger_posting_port.dart';
import '../services/rp_voucher_book_port.dart';

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
    required FinancialTransactionRepository repository,
    RpVoucherBookPort voucherBookPort = const NoOpRpVoucherBookPort(),
    RpLedgerPostingPort ledgerPosting = const NoOpRpLedgerPostingPort(),
    FinancialTransactionValidator validator =
        const FinancialTransactionValidator(),
  }) : _repository = repository,
       _voucherBookPort = voucherBookPort,
       _ledgerPosting = ledgerPosting,
       _validator = validator;

  final FinancialTransactionRepository _repository;
  final RpVoucherBookPort _voucherBookPort;
  final RpLedgerPostingPort _ledgerPosting;
  final FinancialTransactionValidator _validator;

  Future<FinancialTransaction> call(FinancialTransactionDraft draft) async {
    final merged = normalizeFinancialTransactionDraft(draft);
    _validator.validate(merged);
    final bookId = merged.voucherBookId?.trim();
    if (bookId == null || bookId.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.voucherBookRequired,
      );
    }
    final number = await _voucherBookPort.allocateNumber(
      bookId: bookId,
      type: merged.transactionType,
    );
    final created = await _repository.insert(merged, transactionNumber: number);
    try {
      await _ledgerPosting.syncTransaction(created);
    } on JournalException {
      await _repository.softDelete(created.id);
      rethrow;
    } catch (_) {
      await _repository.softDelete(created.id);
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return created;
  }
}

class UpdateFinancialTransaction {
  UpdateFinancialTransaction({
    required FinancialTransactionRepository repository,
    FinancialTransactionValidator validator =
        const FinancialTransactionValidator(),
    FinancialTransactionWorkflow workflow =
        const FinancialTransactionWorkflow(),
    RpLedgerPostingPort ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _repository = repository,
       _validator = validator,
       _workflow = workflow,
       _ledgerPosting = ledgerPosting;

  final FinancialTransactionRepository _repository;
  final FinancialTransactionValidator _validator;
  final FinancialTransactionWorkflow _workflow;
  final RpLedgerPostingPort _ledgerPosting;

  Future<FinancialTransaction> call(
    int id,
    FinancialTransactionDraft draft,
  ) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _workflow.assertCanEdit(existing);
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
    _validator.validate(merged);
    final updated = await _repository.update(id, merged);
    try {
      await _ledgerPosting.syncTransaction(updated);
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
    required FinancialTransactionRepository repository,
    FinancialTransactionWorkflow workflow =
        const FinancialTransactionWorkflow(),
    RpLedgerPostingPort ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _repository = repository,
       _workflow = workflow,
       _ledgerPosting = ledgerPosting;

  final FinancialTransactionRepository _repository;
  final FinancialTransactionWorkflow _workflow;
  final RpLedgerPostingPort _ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _workflow.assertCanPost(existing);
    final posted = await _repository.markPosted(id);
    try {
      await _ledgerPosting.syncTransaction(posted);
    } catch (e) {
      await _repository.update(
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
    required FinancialTransactionRepository repository,
    FinancialTransactionWorkflow workflow =
        const FinancialTransactionWorkflow(),
    RpLedgerPostingPort ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _repository = repository,
       _workflow = workflow,
       _ledgerPosting = ledgerPosting;

  final FinancialTransactionRepository _repository;
  final FinancialTransactionWorkflow _workflow;
  final RpLedgerPostingPort _ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _workflow.assertCanUnpost(existing);
    final unposted = await _repository.markUnposted(id);
    try {
      await _ledgerPosting.syncTransaction(unposted);
    } on JournalException {
      await _repository.markPosted(id);
      rethrow;
    } catch (_) {
      await _repository.markPosted(id);
      throw const FinancialTransactionException(
        FinancialTransactionException.ledgerPostingFailed,
      );
    }
    return unposted;
  }
}

class CancelFinancialTransaction {
  CancelFinancialTransaction({
    required FinancialTransactionRepository repository,
    FinancialTransactionWorkflow workflow =
        const FinancialTransactionWorkflow(),
    RpLedgerPostingPort ledgerPosting = const NoOpRpLedgerPostingPort(),
  }) : _repository = repository,
       _workflow = workflow,
       _ledgerPosting = ledgerPosting;

  final FinancialTransactionRepository _repository;
  final FinancialTransactionWorkflow _workflow;
  final RpLedgerPostingPort _ledgerPosting;

  Future<FinancialTransaction> call(int id) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    _workflow.assertCanCancel(existing);
    await _ledgerPosting.voidTransaction(existing);
    return _repository.markCancelled(id);
  }
}
