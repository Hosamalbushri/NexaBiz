import '../foundation/accounting_effect.dart';
import '../foundation/posting_intent.dart';
import '../posting/accounting_posting_authority_port.dart';
import '../rules/accounting_transaction_intent.dart';

class OperationalAccountingRequest {
  const OperationalAccountingRequest({
    required this.companyId,
    required this.sourceType,
    required this.sourceId,
    required this.transactionType,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.baseCurrencyCode,
    this.exchangeRate = 1.0,
    this.settlementType,
    this.customerId,
    this.vendorId,
    this.warehouseId,
    this.description,
  });

  final String companyId;
  final String sourceType;
  final String sourceId;
  final AccountingTransactionType transactionType;
  final DateTime transactionDate;
  final double amount;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String? settlementType;
  final String? customerId;
  final String? vendorId;
  final String? warehouseId;
  final String? description;
}

/// Central Integration Port connecting operational domains (Sales, Inventory, Treasury, Purchases)
/// to Accounting Domain Authority.
abstract class AccountingIntegrationPort {
  /// Authoritatively processes an operational transaction request.
  ///
  /// If accounting is disabled/not configured for [request.companyId], returns a skipped result without throwing or creating journals.
  /// If accounting is enabled, resolves the AccountingEffect via Rules Engine and posts through Posting Authority.
  Future<AccountingPostingResult> processOperationalTransaction(
    OperationalAccountingRequest request,
  );

  /// Processes a [PostingIntent] (Determined or Explicit) through the canonical validation and posting boundary.
  Future<AccountingPostingResult> processPostingIntent(
    PostingIntent intent,
  );
}

