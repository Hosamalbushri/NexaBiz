import '../../../../core/sync/sync_status.dart';
import 'discount_type.dart';
import 'payment_method.dart';
import 'payment_status.dart';
import 'sale_data_source.dart';
import 'sale_item.dart';
import 'sale_payment.dart';
import 'sale_settlement_type.dart';
import 'sale_status.dart';

/// Sales document (invoice / POS ticket).
///
/// [customerId] is Customer.uuid when linked; null for walk-in with snapshot name.
/// Monetary totals are stored in [currencyCode] using [exchangeRate] snapshot.
class Sale {
  const Sale({
    required this.id,
    required this.uuid,
    required this.saleNumber,
    required this.saleDate,
    required this.settlementType,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.items,
    required this.payments,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.saleStatus,
    required this.dataSource,
    required this.createdAt,
    required this.updatedAt,
    this.voucherBookId,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.customerAccountId,
    this.cashAccountId,
    this.notes,
    this.submittedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.externalId,
    this.externalDocumentNumber,
    this.externalStatus,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final String saleNumber;
  final DateTime saleDate;
  final SaleSettlementType settlementType;

  /// VoucherBook.uuid used for numbering.
  final String? voucherBookId;

  final String? customerId;
  final String? customerCode;
  final String? customerName;

  /// Customer CoA account (Account.uuid) used for credit sales.
  final String? customerAccountId;

  /// Cash/treasury CoA account (Account.uuid) used for cash sales.
  final String? cashAccountId;

  final String currencyCode;
  final String baseCurrencyCode;

  /// Snapshot of rateToBase at save time (base units per 1 sale-currency unit).
  final double exchangeRate;

  final List<SaleItem> items;
  final List<SalePayment> payments;

  final double subtotal;
  final double itemDiscountTotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final SaleStatus saleStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? externalId;
  final String? externalDocumentNumber;
  final String? externalStatus;
  final SaleDataSource dataSource;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get isWalkIn => customerId == null;

  Sale copyWith({
    int? id,
    String? uuid,
    String? saleNumber,
    DateTime? saleDate,
    SaleSettlementType? settlementType,
    String? voucherBookId,
    bool clearVoucherBookId = false,
    String? customerId,
    bool clearCustomerId = false,
    String? customerCode,
    bool clearCustomerCode = false,
    String? customerName,
    bool clearCustomerName = false,
    String? customerAccountId,
    bool clearCustomerAccountId = false,
    String? cashAccountId,
    bool clearCashAccountId = false,
    String? currencyCode,
    String? baseCurrencyCode,
    double? exchangeRate,
    List<SaleItem>? items,
    List<SalePayment>? payments,
    double? subtotal,
    double? itemDiscountTotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    SaleStatus? saleStatus,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    bool clearSubmittedAt = false,
    DateTime? confirmedAt,
    bool clearConfirmedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
    String? externalId,
    bool clearExternalId = false,
    String? externalDocumentNumber,
    bool clearExternalDocumentNumber = false,
    String? externalStatus,
    bool clearExternalStatus = false,
    SaleDataSource? dataSource,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Sale(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleNumber: saleNumber ?? this.saleNumber,
      saleDate: saleDate ?? this.saleDate,
      settlementType: settlementType ?? this.settlementType,
      voucherBookId: clearVoucherBookId
          ? null
          : (voucherBookId ?? this.voucherBookId),
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      customerCode: clearCustomerCode
          ? null
          : (customerCode ?? this.customerCode),
      customerName: clearCustomerName
          ? null
          : (customerName ?? this.customerName),
      customerAccountId: clearCustomerAccountId
          ? null
          : (customerAccountId ?? this.customerAccountId),
      cashAccountId: clearCashAccountId
          ? null
          : (cashAccountId ?? this.cashAccountId),
      currencyCode: currencyCode ?? this.currencyCode,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleStatus: saleStatus ?? this.saleStatus,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: clearSubmittedAt ? null : (submittedAt ?? this.submittedAt),
      confirmedAt: clearConfirmedAt ? null : (confirmedAt ?? this.confirmedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
      externalId: clearExternalId ? null : (externalId ?? this.externalId),
      externalDocumentNumber: clearExternalDocumentNumber
          ? null
          : (externalDocumentNumber ?? this.externalDocumentNumber),
      externalStatus: clearExternalStatus
          ? null
          : (externalStatus ?? this.externalStatus),
      dataSource: dataSource ?? this.dataSource,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

/// Payload for create / update (no id / timestamps required).
class SaleDraft {
  const SaleDraft({
    required this.items,
    required this.saleDate,
    required this.settlementType,
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    this.voucherBookId,
    this.customerId,
    this.customerCode,
    this.customerName,
    this.customerAccountId,
    this.cashAccountId,
    this.discountType = DiscountType.fixed,
    this.discountValue = 0,
    this.taxRate = 0,
    this.paidAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    this.saleStatus = SaleStatus.unposted,
    this.dataSource = SaleDataSource.local,
    this.externalId,
    this.externalDocumentNumber,
    this.externalStatus,
    this.payments = const [],
  });

  final DateTime saleDate;
  final SaleSettlementType settlementType;
  final String? voucherBookId;
  final String? customerId;
  final String? customerCode;
  final String? customerName;
  final String? customerAccountId;
  final String? cashAccountId;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;
  final List<SaleItemDraft> items;
  final DiscountType discountType;
  final double discountValue;
  final double taxRate;
  final double paidAmount;
  final PaymentMethod paymentMethod;
  final String? notes;
  final SaleStatus saleStatus;
  final SaleDataSource dataSource;
  final String? externalId;
  final String? externalDocumentNumber;
  final String? externalStatus;
  final List<SalePaymentDraft> payments;
}
