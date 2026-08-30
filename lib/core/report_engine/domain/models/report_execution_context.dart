import 'package:flutter/foundation.dart';

/// Enum representing the posting filter applied during report execution.
enum PostingScope {
  all,
  postedOnly,
  unpostedOnly,
}

/// Helper extension on PostingScope for easy string serialization/deserialization.
extension PostingScopeX on PostingScope {
  static PostingScope fromString(String? val) {
    if (val == null) return PostingScope.all;
    switch (val.trim().toLowerCase()) {
      case 'posted':
      case 'postedonly':
        return PostingScope.postedOnly;
      case 'unposted':
      case 'unpostedonly':
        return PostingScope.unpostedOnly;
      case 'all':
      default:
        return PostingScope.all;
    }
  }
}

/// Specification for sorting report datasets.
@immutable
class ReportSortSpec {
  const ReportSortSpec({
    required this.columnKey,
    this.ascending = true,
  });

  final String columnKey;
  final bool ascending;
}

/// Immutable, complete execution context for a report query.
/// Passed identically to both summary and detail paged queries.
@immutable
class ReportExecutionContext {
  const ReportExecutionContext({
    required this.companyId,
    this.userId,
    this.filters = const {},
    this.postingScope = PostingScope.all,
    this.warehouseScope,
    this.accountScope,
    this.asOfDate,
    this.currencyScope = 'ALL',
    this.sorting = const ReportSortSpec(columnKey: 'date', ascending: true),
  });

  final String companyId;
  final String? userId;
  final Map<String, dynamic> filters;
  final PostingScope postingScope;
  final String? warehouseScope;
  final String? accountScope;
  final DateTime? asOfDate;
  final String currencyScope;
  final ReportSortSpec sorting;

  DateTime? get fromDate {
    final raw = filters['fromDate'];
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? get toDate {
    final raw = filters['toDate'];
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
