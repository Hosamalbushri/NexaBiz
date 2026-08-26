import '../entities/financial_transaction.dart';
import '../entities/transaction_dashboard_summary.dart';
import '../entities/transaction_list_item.dart';
import '../models/transaction_list_filter.dart';
import '../models/transaction_paged_result.dart';

abstract class FinancialTransactionRepository {
  Future<FinancialTransaction?> getById(int id);

  Future<FinancialTransaction?> getByUuid(String uuid);

  Future<FinancialTransaction> insert(
    FinancialTransactionDraft draft, {
    required String transactionNumber,
  });

  Future<FinancialTransaction> update(int id, FinancialTransactionDraft draft);

  Future<FinancialTransaction> markPosted(int id);

  Future<FinancialTransaction> markUnposted(int id);

  Future<FinancialTransaction> markCancelled(int id);

  Future<void> softDelete(int id);

  /// Header-only paged list query.
  Future<TransactionPagedResult<TransactionListItem>> searchListPaged({
    TransactionListFilter filter = const TransactionListFilter(),
    int page = 0,
    int pageSize = 30,
  });

  /// Database-level dashboard aggregates for [periodFrom]..[periodTo] and today.
  Future<TransactionDashboardSummary> dashboardSummary({
    required DateTime periodFrom,
    required DateTime periodTo,
    required DateTime todayStart,
    required DateTime todayEnd,
  });

  /// Cap for report body rows (totals still from SQL aggregates).
  Future<List<TransactionListItem>> listForReport({
    required TransactionListFilter filter,
    int limit = 5000,
  });

  Future<({double total, int count})> aggregateTotals(
    TransactionListFilter filter,
  );

  /// Emits when list-affecting data changes (for UI refresh).
  Stream<void> watchListChanges();
}
