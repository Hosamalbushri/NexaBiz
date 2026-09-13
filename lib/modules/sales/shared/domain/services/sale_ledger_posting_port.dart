import 'package:stock_count/core/errors/unconfigured_integration_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';

/// Posts local ledger journals for sales (standalone cash + credit).
///
/// Wired in App to Accounting [JournalRepository] — Sales must not import
/// Accounting.
abstract class SaleLedgerPostingPort {
  /// Upserts a balanced journal for a cash or credit sale.
  ///
  /// [JournalEntry.isPosted] follows [Sale.saleStatus.isPosted].
  /// Debits customer (credit) or cash account (cash) for [Sale.total],
  /// debits sales discounts (`5170`) for item + invoice discount, and credits
  /// sales revenue (`4100`) for total + discounts (gross).
  /// No-op when net and discount are both ≤ 0, or the required AR/cash account
  /// is missing while net > 0.
  Future<void> syncSale(Sale sale);

  /// Soft-voids the sale journal linked by sale uuid.
  Future<void> voidSale(Sale sale);
}

class NoOpSaleLedgerPostingPort implements SaleLedgerPostingPort {
  const NoOpSaleLedgerPostingPort({this.isIntegratedMode = false});

  final bool isIntegratedMode;

  @override
  Future<void> syncSale(Sale sale) async {
    if (isIntegratedMode) {
      throw const UnconfiguredIntegrationException(
        'Integrated Mode active: Sales ledger posting port is missing or unconfigured.',
      );
    }
  }

  @override
  Future<void> voidSale(Sale sale) async {
    if (isIntegratedMode) {
      throw const UnconfiguredIntegrationException(
        'Integrated Mode active: Sales ledger posting port is missing or unconfigured.',
      );
    }
  }
}
