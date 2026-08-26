import 'package:stock_count/modules/sync/sync.dart';
import 'financial_transaction_line.dart';
import 'rp_payment_method.dart';
import 'transaction_source.dart';
import 'transaction_status.dart';
import 'transaction_type.dart';

/// Standalone receipt or payment document (operational treasury movement).
class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.uuid,
    required this.transactionNumber,
    required this.transactionType,
    required this.source,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.counterAmount,
    required this.counterCurrencyCode,
    required this.counterExchangeRate,
    required this.cashAccountId,
    required this.counterAccountId,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.documentStatus = TransactionStatus.unposted,
    this.voucherBookId,
    this.cashAccountCode,
    this.cashAccountName,
    this.counterAccountCode,
    this.counterAccountName,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.partyName,
    this.reference,
    this.description,
    this.relatedDocumentId,
    this.relatedDocumentType,
    this.cancelledAt,
    this.externalId,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
    this.lines = const [],
  });

  final int id;
  final String uuid;
  final String transactionNumber;
  final TransactionType transactionType;
  final TransactionSource source;
  final DateTime transactionDate;

  /// Cash/treasury amount in [currencyCode].
  final double amount;
  final String currencyCode;
  final String baseCurrencyCode;

  /// Cash currency → base rate snapshot.
  final double exchangeRate;

  /// Rollup of party allocations (first line / sum helper for lists).
  final double counterAmount;
  final String counterCurrencyCode;

  /// Counter currency → base rate snapshot (first line).
  final double counterExchangeRate;

  /// VoucherBook.uuid used for numbering.
  final String? voucherBookId;

  /// Cash/bank CoA Account.uuid.
  final String cashAccountId;
  final String? cashAccountCode;
  final String? cashAccountName;

  /// Primary counter CoA Account.uuid (first allocation line).
  final String counterAccountId;
  final String? counterAccountCode;
  final String? counterAccountName;

  final String? customerId;
  final String? customerCode;
  final String? customerName;

  /// Free-text payee/payer when not a customer master record.
  final String? partyName;

  final String? reference;
  final String? description;
  final RpPaymentMethod paymentMethod;
  final TransactionStatus documentStatus;

  final String? relatedDocumentId;
  final String? relatedDocumentType;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? externalId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  /// Explicit party/CoA allocations (empty → synthesize from header fields).
  final List<FinancialTransactionLine> lines;

  bool get isDeleted => deletedAt != null;

  bool get isCancelled => cancelledAt != null;

  String get partyDisplayName {
    final customer = customerName?.trim();
    if (customer != null && customer.isNotEmpty) return customer;
    final party = partyName?.trim();
    if (party != null && party.isNotEmpty) return party;
    return '';
  }

  /// Resolves allocation lines, falling back to the legacy single-counter header.
  List<FinancialTransactionLine> get resolvedLines {
    if (lines.isNotEmpty) return lines;
    return FinancialTransactionLinesCodec.fromHeader(
      accountId: counterAccountId,
      accountCode: counterAccountCode,
      accountName: counterAccountName,
      amount: counterAmount > 0 ? counterAmount : amount,
      currencyCode: counterCurrencyCode.trim().isEmpty
          ? currencyCode
          : counterCurrencyCode,
      exchangeRate:
          counterExchangeRate <= 0 ? exchangeRate : counterExchangeRate,
      description: description,
    );
  }
}

/// Mutable draft used for create/update.
class FinancialTransactionDraft {
  const FinancialTransactionDraft({
    required this.transactionType,
    required this.source,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.counterAmount,
    required this.counterCurrencyCode,
    required this.counterExchangeRate,
    required this.cashAccountId,
    required this.counterAccountId,
    required this.paymentMethod,
    this.voucherBookId,
    this.cashAccountCode,
    this.cashAccountName,
    this.counterAccountCode,
    this.counterAccountName,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.partyName,
    this.reference,
    this.description,
    this.relatedDocumentId,
    this.relatedDocumentType,
    this.documentStatus = TransactionStatus.unposted,
    this.externalId,
    this.lines = const [],
  });

  final TransactionType transactionType;
  final TransactionSource source;
  final DateTime transactionDate;
  final double amount;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;
  final double counterAmount;
  final String counterCurrencyCode;
  final double counterExchangeRate;
  final String? voucherBookId;
  final String cashAccountId;
  final String? cashAccountCode;
  final String? cashAccountName;
  final String counterAccountId;
  final String? counterAccountCode;
  final String? counterAccountName;
  final String? customerId;
  final String? customerCode;
  final String? customerName;
  final String? partyName;
  final String? reference;
  final String? description;
  final RpPaymentMethod paymentMethod;
  final String? relatedDocumentId;
  final String? relatedDocumentType;
  final TransactionStatus documentStatus;
  final String? externalId;
  final List<FinancialTransactionLine> lines;

  List<FinancialTransactionLine> get resolvedLines {
    if (lines.isNotEmpty) return lines;
    return FinancialTransactionLinesCodec.fromHeader(
      accountId: counterAccountId,
      accountCode: counterAccountCode,
      accountName: counterAccountName,
      amount: counterAmount > 0 ? counterAmount : amount,
      currencyCode: counterCurrencyCode.trim().isEmpty
          ? currencyCode
          : counterCurrencyCode,
      exchangeRate:
          counterExchangeRate <= 0 ? exchangeRate : counterExchangeRate,
      description: description,
    );
  }
}
