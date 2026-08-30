import 'package:flutter/material.dart';
import 'report_column_spec.dart';
import 'report_parameter_spec.dart';

/// Categories grouping reports in the catalog.
enum ReportCategory {
  inventory,
  sales,
  purchases,
  accounting,
  financial,
  customers,
  suppliers,
  custom,
}

extension ReportCategoryX on ReportCategory {
  String label({required bool isArabic}) {
    switch (this) {
      case ReportCategory.inventory:
        return isArabic ? 'تقارير المخزون' : 'Inventory Reports';
      case ReportCategory.sales:
        return isArabic ? 'تقارير المبيعات' : 'Sales Reports';
      case ReportCategory.purchases:
        return isArabic ? 'تقارير المشتريات' : 'Purchase Reports';
      case ReportCategory.accounting:
        return isArabic ? 'التقارير المحاسبية' : 'Accounting Reports';
      case ReportCategory.financial:
        return isArabic ? 'التقارير المالية' : 'Financial Reports';
      case ReportCategory.customers:
        return isArabic ? 'تقارير العملاء' : 'Customer Reports';
      case ReportCategory.suppliers:
        return isArabic ? 'تقارير الموردين' : 'Supplier Reports';
      case ReportCategory.custom:
        return isArabic ? 'تقارير مخصصة' : 'Custom Reports';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.inventory:
        return Icons.inventory_2_outlined;
      case ReportCategory.sales:
        return Icons.point_of_sale_outlined;
      case ReportCategory.purchases:
        return Icons.shopping_bag_outlined;
      case ReportCategory.accounting:
        return Icons.account_balance_outlined;
      case ReportCategory.financial:
        return Icons.account_balance_wallet_outlined;
      case ReportCategory.customers:
        return Icons.people_outline_rounded;
      case ReportCategory.suppliers:
        return Icons.local_shipping_outlined;
      case ReportCategory.custom:
        return Icons.analytics_outlined;
    }
  }
}

/// Group header specification spanning multiple table columns.
@immutable
class ReportGroupHeaderSpec {
  const ReportGroupHeaderSpec({
    required this.title,
    required this.startColumnIndex,
    required this.columnSpan,
    this.backgroundColor,
    this.textColor,
  });

  final String title;
  final int startColumnIndex;
  final int columnSpan;
  final Color? backgroundColor;
  final Color? textColor;
}

/// Sorting rule for report queries.
@immutable
class ReportSortSpec {
  const ReportSortSpec({
    required this.fieldId,
    this.ascending = true,
  });

  final String fieldId;
  final bool ascending;
}

/// Drill-down action metadata for navigating from a report row to original voucher screen.
@immutable
class ReportDrillDownSpec {
  const ReportDrillDownSpec({
    required this.targetScreenResolver,
    this.documentTypeField = 'documentType',
    this.documentUuidField = 'documentUuid',
  });

  final String documentTypeField;
  final String documentUuidField;
  final Widget Function(BuildContext context, String docType, String docUuid) targetScreenResolver;
}

/// Complete declarative specification of an ERP report.
@immutable
class ReportDefinitionSpec {
  const ReportDefinitionSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.parameters,
    required this.columns,
    this.groupHeaders = const [],
    this.defaultSorting = const [],
    this.requiredPermission,
    this.minTableWidth = 900.0,
    this.isLandscapePDF = true,
    this.drillDown,
  });

  /// Unique identifier of the report (e.g. 'product_stock_movement').
  final String id;

  /// Localized name of the report.
  final String name;

  /// Localized short description of the report's purpose.
  final String description;

  /// Business category.
  final ReportCategory category;

  /// Dynamic list of parameters & filters.
  final List<ReportParameterSpec> parameters;

  /// Columns definition list.
  final List<ReportColumnSpec> columns;

  /// Optional multi-level grouped headers.
  final List<ReportGroupHeaderSpec> groupHeaders;

  /// Default sorting order.
  final List<ReportSortSpec> defaultSorting;

  /// Permission string required to access this report (if null, available to all authorized users).
  final String? requiredPermission;

  /// Minimum scrollable table width in logical pixels.
  final double minTableWidth;

  /// Whether PDF generation defaults to Landscape orientation.
  final bool isLandscapePDF;

  /// Optional drill-down configuration.
  final ReportDrillDownSpec? drillDown;
}
