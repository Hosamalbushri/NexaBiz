import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../data/database/receipts_payments_database.dart';
import '../../data/repositories/financial_transaction_repository_impl.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/entities/transaction_dashboard_summary.dart';
import '../../domain/repositories/financial_transaction_repository.dart';
import '../../domain/services/rp_currency_port.dart';
import '../../domain/services/rp_customer_lookup_port.dart';
import '../../domain/services/rp_ledger_posting_port.dart';
import '../../domain/services/rp_treasury_account_port.dart';
import '../../domain/services/rp_voucher_book_port.dart';
import '../../domain/usecases/financial_transaction_usecases.dart';

final receiptsPaymentsDatabaseProvider = Provider<ReceiptsPaymentsDatabase>((
  ref,
) {
  final db = ReceiptsPaymentsDatabase();
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final financialTransactionRepositoryImplProvider =
    Provider<FinancialTransactionRepositoryImpl>((ref) {
  return FinancialTransactionRepositoryImpl(
    ref.watch(receiptsPaymentsDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

final financialTransactionRepositoryProvider =
    Provider<FinancialTransactionRepository>((ref) {
  return ref.watch(financialTransactionRepositoryImplProvider);
});

final rpTreasuryAccountPortProvider = Provider<RpTreasuryAccountPort>((ref) {
  return const NoOpRpTreasuryAccountPort();
});

final rpVoucherBookPortProvider = Provider<RpVoucherBookPort>((ref) {
  return const NoOpRpVoucherBookPort();
});

final rpCustomerLookupPortProvider = Provider<RpCustomerLookupPort>((ref) {
  return const NoOpRpCustomerLookupPort();
});

final rpLedgerPostingPortProvider = Provider<RpLedgerPostingPort>((ref) {
  return const NoOpRpLedgerPostingPort();
});

final rpCurrencyPortProvider = Provider<RpCurrencyPort>((ref) {
  return const NoOpRpCurrencyPort();
});
final getFinancialTransactionByIdProvider =
    Provider<GetFinancialTransactionById>((ref) {
  return GetFinancialTransactionById(
    ref.watch(financialTransactionRepositoryProvider),
  );
});

final searchFinancialTransactionsProvider =
    Provider<SearchFinancialTransactions>((ref) {
  return SearchFinancialTransactions(
    ref.watch(financialTransactionRepositoryProvider),
  );
});

final getTransactionDashboardProvider = Provider<GetTransactionDashboard>((
  ref,
) {
  return GetTransactionDashboard(
    ref.watch(financialTransactionRepositoryProvider),
  );
});

final createFinancialTransactionProvider =
    Provider<CreateFinancialTransaction>((ref) {
  return CreateFinancialTransaction(
    repository: ref.watch(financialTransactionRepositoryProvider),
    voucherBookPort: ref.watch(rpVoucherBookPortProvider),
    ledgerPosting: ref.watch(rpLedgerPostingPortProvider),
  );
});

final updateFinancialTransactionProvider =
    Provider<UpdateFinancialTransaction>((ref) {
  return UpdateFinancialTransaction(
    repository: ref.watch(financialTransactionRepositoryProvider),
    ledgerPosting: ref.watch(rpLedgerPostingPortProvider),
  );
});

final postFinancialTransactionProvider = Provider<PostFinancialTransaction>((
  ref,
) {
  return PostFinancialTransaction(
    repository: ref.watch(financialTransactionRepositoryProvider),
    ledgerPosting: ref.watch(rpLedgerPostingPortProvider),
  );
});

final cancelFinancialTransactionProvider =
    Provider<CancelFinancialTransaction>((ref) {
  return CancelFinancialTransaction(
    repository: ref.watch(financialTransactionRepositoryProvider),
    ledgerPosting: ref.watch(rpLedgerPostingPortProvider),
  );
});

final financialTransactionByIdProvider =
    FutureProvider.family<FinancialTransaction?, int>((ref, id) {
  return ref.watch(getFinancialTransactionByIdProvider)(id);
});

final transactionDashboardProvider =
    FutureProvider.autoDispose<TransactionDashboardSummary>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart
      .add(const Duration(days: 1))
      .subtract(const Duration(microseconds: 1));
  final periodFrom = DateTime(now.year, now.month, 1);
  final periodTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  return ref.watch(getTransactionDashboardProvider)(
    periodFrom: periodFrom,
    periodTo: periodTo,
    todayStart: todayStart,
    todayEnd: todayEnd,
  );
});
