import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';

/// Posts local ledger journals for receipts/payments.
///
/// Wired in App to Accounting [JournalPostingService] — module must not import
/// Accounting.
abstract class RpLedgerPostingPort {
  /// Upserts a balanced journal for the document.
  ///
  /// Receipt: Dr cash · Cr counter
  /// Payment: Dr counter · Cr cash
  Future<void> syncTransaction(FinancialTransaction txn);

  /// Soft-voids the journal linked by document uuid.
  Future<void> voidTransaction(FinancialTransaction txn);
}

class NoOpRpLedgerPostingPort implements RpLedgerPostingPort {
  const NoOpRpLedgerPostingPort();

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {}

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {}
}
