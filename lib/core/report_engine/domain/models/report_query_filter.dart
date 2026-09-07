import 'package:flutter/foundation.dart';
import 'report_execution_context.dart';

/// Standardized, canonical query filter model for all NexaBiz ERP reports.
///
/// Encapsulates all query filters (company, date range, fiscal period, account,
/// party, warehouse, product, cash register, currency, posting scope, document type)
/// in a single read-side immutable object.
@immutable
class ReportQueryFilter {
  const ReportQueryFilter({
    required this.companyId,
    this.userId,
    this.fromDate,
    this.toDate,
    this.asOfDate,
    this.fiscalYearId,
    this.fiscalPeriodId,
    this.accountUuid,
    this.customerUuid,
    this.supplierUuid,
    this.warehouseUuid,
    this.productUuid,
    this.cashRegisterUuid,
    this.currencyCode = 'ALL',
    this.postingScope = PostingScope.postedOnly,
    this.documentType,
    this.searchQuery,
    this.pageNumber = 1,
    this.pageSize = 100,
    this.customFilters = const {},
  });

  /// Tenant/Company isolation scope (REQUIRED).
  final String companyId;

  /// User requesting the report.
  final String? userId;

  /// Start date of date-range queries.
  final DateTime? fromDate;

  /// End date of date-range queries.
  final DateTime? toDate;

  /// Point-in-time calculation date (e.g. As-Of Balance Sheet / Inventory Valuation).
  final DateTime? asOfDate;

  /// Fiscal Year ID scope.
  final String? fiscalYearId;

  /// Fiscal Period ID scope.
  final String? fiscalPeriodId;

  /// Account UUID filter for chart-of-accounts queries.
  final String? accountUuid;

  /// Customer UUID filter for customer operations/statements.
  final String? customerUuid;

  /// Supplier UUID filter for vendor operations/statements.
  final String? supplierUuid;

  /// Warehouse UUID filter for stock movement and inventory valuation.
  final String? warehouseUuid;

  /// Product / Item UUID filter for stock movements.
  final String? productUuid;

  /// Cash register UUID filter for register movement reports.
  final String? cashRegisterUuid;

  /// Currency code filter or reporting currency override.
  final String currencyCode;

  /// Posting status filter (defaults to [PostingScope.postedOnly] for financial integrity).
  final PostingScope postingScope;

  /// Document/voucher type filter (e.g. 'receipt', 'issue', 'manual').
  final String? documentType;

  /// Free-text search term.
  final String? searchQuery;

  /// Page number for keyset or OFFSET pagination (1-indexed).
  final int pageNumber;

  /// Record limit per page.
  final int pageSize;

  /// Extensible key-value map for report-specific custom filters.
  final Map<String, dynamic> customFilters;

  /// Utility constructor for creating a financial report filter defaults.
  factory ReportQueryFilter.financial({
    required String companyId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? asOfDate,
    String? accountUuid,
    String currencyCode = 'ALL',
    PostingScope postingScope = PostingScope.postedOnly,
    Map<String, dynamic> customFilters = const {},
  }) {
    return ReportQueryFilter(
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
      asOfDate: asOfDate,
      accountUuid: accountUuid,
      currencyCode: currencyCode,
      postingScope: postingScope,
      customFilters: customFilters,
    );
  }

  /// Converts this filter to a legacy [ReportExecutionContext] for engine compatibility.
  ReportExecutionContext toExecutionContext({String? defaultCurrency}) {
    return ReportExecutionContext(
      companyId: companyId,
      userId: userId,
      postingScope: postingScope,
      warehouseScope: warehouseUuid,
      accountScope: accountUuid,
      asOfDate: asOfDate,
      currencyScope: currencyCode.isEmpty
          ? (defaultCurrency ?? 'ALL')
          : currencyCode,
      filters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (customerUuid != null) 'customerUuid': customerUuid,
        if (supplierUuid != null) 'supplierUuid': supplierUuid,
        if (productUuid != null) 'productCode': productUuid,
        if (cashRegisterUuid != null) 'cashRegisterUuid': cashRegisterUuid,
        if (documentType != null) 'documentType': documentType,
        if (searchQuery != null) 'searchQuery': searchQuery,
        ...customFilters,
      },
    );
  }

  ReportQueryFilter copyWith({
    String? companyId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? asOfDate,
    String? fiscalYearId,
    String? fiscalPeriodId,
    String? accountUuid,
    String? customerUuid,
    String? supplierUuid,
    String? warehouseUuid,
    String? productUuid,
    String? cashRegisterUuid,
    String? currencyCode,
    PostingScope? postingScope,
    String? documentType,
    String? searchQuery,
    int? pageNumber,
    int? pageSize,
    Map<String, dynamic>? customFilters,
  }) {
    return ReportQueryFilter(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      asOfDate: asOfDate ?? this.asOfDate,
      fiscalYearId: fiscalYearId ?? this.fiscalYearId,
      fiscalPeriodId: fiscalPeriodId ?? this.fiscalPeriodId,
      accountUuid: accountUuid ?? this.accountUuid,
      customerUuid: customerUuid ?? this.customerUuid,
      supplierUuid: supplierUuid ?? this.supplierUuid,
      warehouseUuid: warehouseUuid ?? this.warehouseUuid,
      productUuid: productUuid ?? this.productUuid,
      cashRegisterUuid: cashRegisterUuid ?? this.cashRegisterUuid,
      currencyCode: currencyCode ?? this.currencyCode,
      postingScope: postingScope ?? this.postingScope,
      documentType: documentType ?? this.documentType,
      searchQuery: searchQuery ?? this.searchQuery,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      customFilters: customFilters ?? this.customFilters,
    );
  }
}
