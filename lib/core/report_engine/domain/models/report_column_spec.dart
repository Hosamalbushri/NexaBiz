import 'package:flutter/material.dart';

/// Formatting types supported by report columns.
enum ReportColumnDataType {
  text,
  number,
  currency,
  quantity,
  date,
  dateTime,
  percentage,
  boolean,
  badge,
}

/// Aggregation functions for table column footers & totals.
enum ReportColumnAggregation {
  none,
  sum,
  count,
  avg,
  min,
  max,
}

/// Specification defining a column in the dynamic Report Engine.
@immutable
class ReportColumnSpec {
  const ReportColumnSpec({
    required this.id,
    required this.label,
    this.dataType = ReportColumnDataType.text,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.center,
    this.isNumeric = false,
    this.aggregation = ReportColumnAggregation.none,
    this.isSearchable = true,
    this.isSortable = true,
    this.isVisible = true,
    this.headerBackgroundColor,
    this.headerTextColor,
    this.footerValue,
    this.currencyCode,
  });

  /// Unique column identifier (key matching field in dataset row).
  final String id;

  /// Localized column header label.
  final String label;

  /// Data type determining cell formatting & layout.
  final ReportColumnDataType dataType;

  /// Flex weight in table row layout.
  final int flex;

  /// Optional fixed width in logical pixels.
  final double? width;

  /// Text / cell content alignment.
  final Alignment alignment;

  /// Whether column contains numeric data (enables tabular figures).
  final bool isNumeric;

  /// Aggregation rule applied in footer.
  final ReportColumnAggregation aggregation;

  /// Whether column participates in client search filtering.
  final bool isSearchable;

  /// Whether column supports sorting.
  final bool isSortable;

  /// Whether column is visible by default.
  final bool isVisible;

  /// Optional header background override.
  final Color? headerBackgroundColor;

  /// Optional header text color override.
  final Color? headerTextColor;

  /// Optional custom static footer value string.
  final String? footerValue;

  /// Optional currency code override (e.g. 'YER', 'SAR', 'USD').
  final String? currencyCode;

  ReportColumnSpec copyWith({
    String? id,
    String? label,
    ReportColumnDataType? dataType,
    int? flex,
    double? width,
    Alignment? alignment,
    bool? isNumeric,
    ReportColumnAggregation? aggregation,
    bool? isSearchable,
    bool? isSortable,
    bool? isVisible,
    Color? headerBackgroundColor,
    Color? headerTextColor,
    String? footerValue,
    String? currencyCode,
  }) {
    return ReportColumnSpec(
      id: id ?? this.id,
      label: label ?? this.label,
      dataType: dataType ?? this.dataType,
      flex: flex ?? this.flex,
      width: width ?? this.width,
      alignment: alignment ?? this.alignment,
      isNumeric: isNumeric ?? this.isNumeric,
      aggregation: aggregation ?? this.aggregation,
      isSearchable: isSearchable ?? this.isSearchable,
      isSortable: isSortable ?? this.isSortable,
      isVisible: isVisible ?? this.isVisible,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      footerValue: footerValue ?? this.footerValue,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
