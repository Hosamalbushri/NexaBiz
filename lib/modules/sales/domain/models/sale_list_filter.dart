import '../entities/payment_method.dart';
import '../entities/payment_status.dart';
import '../entities/sale_data_source.dart';
import '../entities/sale_status.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Filter criteria for the sales list (offline query).
class SaleListFilter {
  const SaleListFilter({
    this.query = '',
    this.saleStatus,
    this.paymentStatus,
    this.paymentMethod,
    this.dataSource,
    this.syncStatus,
    this.customerId,
    this.fromDate,
    this.toDate,
  });

  final String query;
  final SaleStatus? saleStatus;
  final PaymentStatus? paymentStatus;
  final PaymentMethod? paymentMethod;
  final SaleDataSource? dataSource;
  final SyncStatus? syncStatus;
  final String? customerId;
  final DateTime? fromDate;
  final DateTime? toDate;

  SaleListFilter copyWith({
    String? query,
    SaleStatus? saleStatus,
    bool clearSaleStatus = false,
    PaymentStatus? paymentStatus,
    bool clearPaymentStatus = false,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    SaleDataSource? dataSource,
    bool clearDataSource = false,
    SyncStatus? syncStatus,
    bool clearSyncStatus = false,
    String? customerId,
    bool clearCustomerId = false,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
  }) {
    return SaleListFilter(
      query: query ?? this.query,
      saleStatus: clearSaleStatus ? null : (saleStatus ?? this.saleStatus),
      paymentStatus: clearPaymentStatus
          ? null
          : (paymentStatus ?? this.paymentStatus),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      saleStatus != null ||
      paymentStatus != null ||
      paymentMethod != null ||
      dataSource != null ||
      syncStatus != null ||
      customerId != null ||
      fromDate != null ||
      toDate != null;
}
