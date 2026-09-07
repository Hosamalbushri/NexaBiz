import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';

/// Labels required for localized rendering of Income Statement (P&L).
class IncomeStatementReportLabels {
  const IncomeStatementReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.revenueHeader,
    required this.cogsHeader,
    required this.grossProfitLabel,
    required this.operatingExpensesHeader,
    required this.operatingProfitLabel,
    required this.netProfitLabel,
    required this.netLossLabel,
    required this.accountCodeLabel,
    required this.accountNameLabel,
    required this.amountLabel,
    required this.totalsLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String periodAll;
  final String revenueHeader;
  final String cogsHeader;
  final String grossProfitLabel;
  final String operatingExpensesHeader;
  final String operatingProfitLabel;
  final String netProfitLabel;
  final String netLossLabel;
  final String accountCodeLabel;
  final String accountNameLabel;
  final String amountLabel;
  final String totalsLabel;
  final String emptyMessage;
}

/// One line in the P&L report.
class IncomeStatementLineItem {
  const IncomeStatementLineItem({
    required this.accountCode,
    required this.accountName,
    required this.amount,
  });

  final String accountCode;
  final String accountName;
  final double amount;
}

/// Data payload for Income Statement / Profit & Loss.
class IncomeStatementReportPayload {
  const IncomeStatementReportPayload({
    required this.labels,
    required this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    required this.revenueItems,
    required this.cogsItems,
    required this.expenseItems,
    required this.totalRevenue,
    required this.totalCogs,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
  });

  final IncomeStatementReportLabels labels;
  final String baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;

  final List<IncomeStatementLineItem> revenueItems;
  final List<IncomeStatementLineItem> cogsItems;
  final List<IncomeStatementLineItem> expenseItems;

  final double totalRevenue;
  final double totalCogs;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;
}

/// Data port interface for Income Statement reporting.
abstract class IncomeStatementReportDataPort {
  Future<IncomeStatementReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required IncomeStatementReportLabels labels,
  });
}

/// Provider for IncomeStatementReportDataPort.
final incomeStatementReportDataPortProvider =
    Provider<IncomeStatementReportDataPort>((ref) {
      throw UnimplementedError(
        'incomeStatementReportDataPortProvider must be overridden in providerOverrides',
      );
    });
