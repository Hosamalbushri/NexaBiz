import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';
import '../../domain/models/report_column_spec.dart';
import '../../domain/models/report_definition_spec.dart';
import '../../domain/models/report_parameter_spec.dart';
import '../../domain/services/report_relative_date_evaluator.dart';


/// Specification for Sales Period Analysis Report (تقرير مبيعات الفترة والعملاء).
final salesPeriodReportSpec = ReportDefinitionSpec(
  id: 'sales_period',
  name: 'تقرير مبيعات الفترة والعملاء',
  description: 'تحليل شامل لفواتير المبيعات وصافي المبيعات حسب الفترة والعملاء وحالة التسوية.',
  category: ReportCategory.sales,
  minTableWidth: 1000,
  parameters: const [
    ReportParameterSpec(
      id: 'dateRange',
      label: 'فترة المبيعات',
      type: ReportParameterType.dateRange,
      isRequired: true,
      defaultValue: ReportRelativeDateRange.thisMonth,
    ),
    ReportParameterSpec(
      id: 'customer',
      label: 'العميل المستهدف',
      type: ReportParameterType.customer,
      placeholder: 'اختر عميلاً معيناً...',
    ),
    ReportParameterSpec(
      id: 'postingStatus',
      label: 'حالة الفاتورة',
      type: ReportParameterType.postingStatus,
      defaultValue: ReportPostingStatusFilter.all,
    ),
  ],
  columns: const [
    ReportColumnSpec(
      id: 'invoiceDate',
      label: 'تاريخ الفاتورة',
      dataType: ReportColumnDataType.date,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'invoiceNumber',
      label: 'رقم الفاتورة',
      dataType: ReportColumnDataType.text,
      flex: 2,
      isSearchable: true,
    ),
    ReportColumnSpec(
      id: 'customerName',
      label: 'اسم العميل',
      dataType: ReportColumnDataType.text,
      flex: 3,
      isSearchable: true,
    ),
    ReportColumnSpec(
      id: 'paymentType',
      label: 'طريقة الدفع',
      dataType: ReportColumnDataType.badge,
      flex: 2,
    ),
    ReportColumnSpec(
      id: 'subtotal',
      label: 'المبلغ قبل الضريبة',
      dataType: ReportColumnDataType.currency,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'taxAmount',
      label: 'مبلغ الضريبة',
      dataType: ReportColumnDataType.currency,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
    ReportColumnSpec(
      id: 'grandTotal',
      label: 'صافي الفاتورة',
      dataType: ReportColumnDataType.currency,
      alignment: Alignment.centerRight,
      flex: 2,
      aggregation: ReportColumnAggregation.sum,
    ),
  ],
);
