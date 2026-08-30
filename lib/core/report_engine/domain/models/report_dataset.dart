import 'package:flutter/material.dart';

/// Specification for top metadata KPI cards rendered above report table grid.
@immutable
class ReportHeaderCardData {
  const ReportHeaderCardData({
    required this.title,
    required this.value,
    this.subValue,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? accentColor;
}

/// Generic data row inside a [ReportDataset].
@immutable
class ReportRowData {
  const ReportRowData({
    required this.values,
    this.backgroundColor,
    this.documentType,
    this.documentUuid,
    this.isGroupHeader = false,
    this.isSummaryRow = false,
  });

  /// Map of field ID -> raw value (String, double, int, DateTime, bool).
  final Map<String, dynamic> values;

  /// Optional background row color override.
  final Color? backgroundColor;

  /// Target document type if row supports drill-down (e.g. 'sale', 'receipt', 'issue', 'journal').
  final String? documentType;

  /// Target document UUID for drill-down navigation.
  final String? documentUuid;

  /// Whether this row represents a group section header.
  final bool isGroupHeader;

  /// Whether this row represents a group subtotal or total row.
  final bool isSummaryRow;

  /// Convenience getter for field value.
  dynamic operator [](String key) => values[key];
}

/// Summary metric footer item.
@immutable
class ReportSummaryData {
  const ReportSummaryData({
    required this.label,
    required this.value,
    this.columnId,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String? columnId;
  final Color? color;
  final IconData? icon;
}

/// Metadata information accompanying a report dataset execution.
@immutable
class ReportMetadata {
  const ReportMetadata({
    required this.reportId,
    required this.reportTitle,
    required this.companyName,
    required this.generatedAt,
    required this.totalRowsCount,
    this.activeFiltersSummary = '',
    this.currencyCode = 'YER',
    this.hasMorePages = false,
  });

  final String reportId;
  final String reportTitle;
  final String companyName;
  final DateTime generatedAt;
  final int totalRowsCount;
  final String activeFiltersSummary;
  final String currencyCode;
  final bool hasMorePages;
}

/// Standalone decoupled dataset containing all query results & metadata.
/// This object is passed directly to Viewer, PDF, Excel, CSV, and Printing drivers.
@immutable
class ReportDataset {
  const ReportDataset({
    required this.metadata,
    this.headerCards = const [],
    this.rows = const [],
    this.summaryTotals = const [],
  });

  final ReportMetadata metadata;
  final List<ReportHeaderCardData> headerCards;
  final List<ReportRowData> rows;
  final List<ReportSummaryData> summaryTotals;

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  ReportDataset copyWith({
    ReportMetadata? metadata,
    List<ReportHeaderCardData>? headerCards,
    List<ReportRowData>? rows,
    List<ReportSummaryData>? summaryTotals,
  }) {
    return ReportDataset(
      metadata: metadata ?? this.metadata,
      headerCards: headerCards ?? this.headerCards,
      rows: rows ?? this.rows,
      summaryTotals: summaryTotals ?? this.summaryTotals,
    );
  }
}
