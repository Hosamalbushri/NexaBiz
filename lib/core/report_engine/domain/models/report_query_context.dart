import 'package:flutter/foundation.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';

/// Context containing resolved parameters, security boundaries, and pagination
/// passed to Report Data Providers when executing queries.
@immutable
class ReportQueryContext {
  const ReportQueryContext({
    required this.companyId,
    required this.userId,
    this.currencyCode = 'SAR',
    this.fiscalYearId,
    this.allowedWarehouseIds = const [],
    this.allowedAccountIds = const [],
    this.parameterValues = const {},
    this.postingStatus = ReportPostingStatusFilter.all,
    this.fromDate,
    this.toDate,
    this.pageNumber = 1,
    this.pageSize = 100,
    this.asOfDate,
    this.searchQuery,
  });

  /// Tenant / Company scope isolation key.
  final String companyId;

  /// Active User ID.
  final String userId;

  /// Active currency code for monetary formatting (e.g. 'SAR', 'YER', 'USD').
  final String currencyCode;

  /// Active Fiscal Year ID if applicable.
  final String? fiscalYearId;

  /// Warehouse IDs permitted for current user (empty = all permitted).
  final List<String> allowedWarehouseIds;

  /// Account IDs permitted for current user (empty = all permitted).
  final List<String> allowedAccountIds;

  /// Map of parameter values resolved from dynamic UI form.
  final Map<String, dynamic> parameterValues;

  /// Posting status choice (All / Posted / Unposted).
  final ReportPostingStatusFilter postingStatus;

  /// Start date of query range.
  final DateTime? fromDate;

  /// End date of query range.
  final DateTime? toDate;

  /// As-Of point-in-time calculation date.
  final DateTime? asOfDate;

  /// Search query filter text.
  final String? searchQuery;

  /// Page number for server-side pagination (1-indexed).
  final int pageNumber;

  /// Records count per page.
  final int pageSize;

  /// Utility to get typed parameter value safely.
  T? getParam<T>(String key) {
    final val = parameterValues[key];
    if (val is T) return val;
    return null;
  }

  /// Utility to check if specific warehouse is permitted.
  bool isWarehouseAllowed(String warehouseId) {
    if (allowedWarehouseIds.isEmpty) return true;
    return allowedWarehouseIds.contains(warehouseId);
  }

  /// Utility to check if specific account is permitted.
  bool isAccountAllowed(String accountId) {
    if (allowedAccountIds.isEmpty) return true;
    return allowedAccountIds.contains(accountId);
  }

  ReportQueryContext copyWith({
    String? companyId,
    String? userId,
    String? currencyCode,
    String? fiscalYearId,
    List<String>? allowedWarehouseIds,
    List<String>? allowedAccountIds,
    Map<String, dynamic>? parameterValues,
    ReportPostingStatusFilter? postingStatus,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? asOfDate,
    String? searchQuery,
    int? pageNumber,
    int? pageSize,
  }) {
    return ReportQueryContext(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      currencyCode: currencyCode ?? this.currencyCode,
      fiscalYearId: fiscalYearId ?? this.fiscalYearId,
      allowedWarehouseIds: allowedWarehouseIds ?? this.allowedWarehouseIds,
      allowedAccountIds: allowedAccountIds ?? this.allowedAccountIds,
      parameterValues: parameterValues ?? this.parameterValues,
      postingStatus: postingStatus ?? this.postingStatus,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      asOfDate: asOfDate ?? this.asOfDate,
      searchQuery: searchQuery ?? this.searchQuery,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
