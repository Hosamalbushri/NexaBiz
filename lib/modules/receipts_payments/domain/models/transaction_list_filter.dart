import '../../../../core/sync/sync_status.dart';
import '../entities/rp_payment_method.dart';
import '../entities/transaction_source.dart';
import '../entities/transaction_status.dart';
import '../entities/transaction_type.dart';

/// Filter criteria for transaction list (applied in SQL).
class TransactionListFilter {
  const TransactionListFilter({
    this.query = '',
    this.transactionType,
    this.documentStatus,
    this.paymentMethod,
    this.syncStatus,
    this.source,
    this.customerId,
    this.cashAccountId,
    this.counterAccountId,
    this.fromDate,
    this.toDate,
    this.cashAccountCodePrefix,
  });

  final String query;
  final TransactionType? transactionType;
  final TransactionStatus? documentStatus;
  final RpPaymentMethod? paymentMethod;
  final SyncStatus? syncStatus;
  final TransactionSource? source;
  final String? customerId;
  final String? cashAccountId;
  final String? counterAccountId;
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Matches `cash_account_code LIKE '[prefix]%'` (e.g. `1211`, `1212`).
  final String? cashAccountCodePrefix;

  TransactionListFilter copyWith({
    String? query,
    TransactionType? transactionType,
    bool clearTransactionType = false,
    TransactionStatus? documentStatus,
    bool clearDocumentStatus = false,
    RpPaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    SyncStatus? syncStatus,
    bool clearSyncStatus = false,
    TransactionSource? source,
    bool clearSource = false,
    String? customerId,
    bool clearCustomerId = false,
    String? cashAccountId,
    bool clearCashAccountId = false,
    String? counterAccountId,
    bool clearCounterAccountId = false,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
    String? cashAccountCodePrefix,
    bool clearCashAccountCodePrefix = false,
  }) {
    return TransactionListFilter(
      query: query ?? this.query,
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      documentStatus: clearDocumentStatus
          ? null
          : (documentStatus ?? this.documentStatus),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      source: clearSource ? null : (source ?? this.source),
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      cashAccountId:
          clearCashAccountId ? null : (cashAccountId ?? this.cashAccountId),
      counterAccountId: clearCounterAccountId
          ? null
          : (counterAccountId ?? this.counterAccountId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      cashAccountCodePrefix: clearCashAccountCodePrefix
          ? null
          : (cashAccountCodePrefix ?? this.cashAccountCodePrefix),
    );
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      transactionType != null ||
      documentStatus != null ||
      paymentMethod != null ||
      syncStatus != null ||
      source != null ||
      customerId != null ||
      cashAccountId != null ||
      counterAccountId != null ||
      fromDate != null ||
      toDate != null ||
      cashAccountCodePrefix != null;
}
