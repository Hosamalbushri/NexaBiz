import 'package:stock_count/core/errors/unconfigured_integration_exception.dart';
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
  const NoOpRpLedgerPostingPort({this.isIntegratedMode = false});

  final bool isIntegratedMode;

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    if (isIntegratedMode) {
      throw const UnconfiguredIntegrationException(
        'Integrated Mode active: Receipts & Payments ledger posting port is missing or unconfigured.',
      );
    }
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    if (isIntegratedMode) {
      throw const UnconfiguredIntegrationException(
        'Integrated Mode active: Receipts & Payments ledger posting port is missing or unconfigured.',
      );
    }
  }
}
