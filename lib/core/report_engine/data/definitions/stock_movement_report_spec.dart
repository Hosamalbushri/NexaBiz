import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';
import '../../domain/models/report_column_spec.dart';
import '../../domain/models/report_definition_spec.dart';
import '../../domain/models/report_parameter_spec.dart';
import '../../domain/services/report_relative_date_evaluator.dart';

/// Declarative specification for Stock Movement Report (تقرير حركة الأصناف والمخزون).
final stockMovementReportSpec = ReportDefinitionSpec(
  id: 'stock_movement',
  name: 'تقرير حركة الأصناف والمخزون',
  description: 'تقرير تفصيلي وإجمالي لعرض كافة الوارد والمنصرف بالكميات الرئيسية والفرعية ورصيد الحركة ومبالغ التكلفة بأسلوب ERP.',
  category: ReportCategory.inventory,
  minTableWidth: 1250,
  groupHeaders: const [
    ReportGroupHeaderSpec(
      title: 'الوارد (التوريد)',
      startColumnIndex: 4,
      columnSpan: 2,
      backgroundColor: Color(0xFFE8F5E9),
      textColor: Color(0xFF1B5E20),
    ),
    ReportGroupHeaderSpec(
      title: 'المنصرف (الصرف)',
      startColumnIndex: 6,
      columnSpan: 2,
      backgroundColor: Color(0xFFFFEBEE),
      textColor: Color(0xFFB71C1C),
    ),
  ],
  parameters: const [
    ReportParameterSpec(
      id: 'statementType',
      label: 'نوع الكشف',
      type: ReportParameterType.select,
      defaultValue: 'detailed',
      options: [
        ReportSelectOption(value: 'detailed', label: 'تفصيلي (جميع الحركات)'),
        ReportSelectOption(value: 'summary', label: 'إجمالي (مجمع لكل صنف)'),
      ],
    ),
    ReportParameterSpec(
      id: 'dateRange',
      label: 'تاريخ الحركة',
      type: ReportParameterType.dateRange,
      isRequired: true,
      defaultValue: ReportRelativeDateRange.thisMonth,
    ),
    ReportParameterSpec(
      id: 'productCode',
      label: 'الصنف المستهدف',
      type: ReportParameterType.product,
      placeholder: 'اختر صنفاً معيناً لتقييد التقرير...',
    ),
    ReportParameterSpec(
      id: 'postingStatus',
      label: 'حالة الترحيل',
      type: ReportParameterType.postingStatus,
      defaultValue: ReportPostingStatusFilter.posted,
    ),
  ],
  columns: const [
    ReportColumnSpec(
      id: 'transactionDate',
      label: 'تاريخ المستند',
      dataType: ReportColumnDataType.date,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'documentTypeLabel',
      label: 'نوع الحركة',
      dataType: ReportColumnDataType.badge,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'documentNumber',
      label: 'رقم المستند',
      dataType: ReportColumnDataType.text,
      flex: 2,
      isSearchable: true,
    ),
    ReportColumnSpec(
      id: 'productName',
      label: 'الصنف',
      dataType: ReportColumnDataType.text,
      flex: 3,
      isSearchable: true,
    ),
    ReportColumnSpec(
      id: 'inMainQuantity',
      label: 'كمية رئيسية',
      dataType: ReportColumnDataType.quantity,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'inSubQuantity',
      label: 'كمية فرعية',
      dataType: ReportColumnDataType.quantity,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'outMainQuantity',
      label: 'كمية رئيسية',
      dataType: ReportColumnDataType.quantity,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'outSubQuantity',
      label: 'كمية فرعية',
      dataType: ReportColumnDataType.quantity,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'balanceQuantity',
      label: 'الرصيد الصافي',
      dataType: ReportColumnDataType.quantity,
      alignment: Alignment.centerRight,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'unitCost',
      label: 'تكلفة الوحدة',
      dataType: ReportColumnDataType.currency,
      alignment: Alignment.centerRight,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'totalValue',
      label: 'إجمالي القيمة',
      dataType: ReportColumnDataType.currency,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
  ],
);
