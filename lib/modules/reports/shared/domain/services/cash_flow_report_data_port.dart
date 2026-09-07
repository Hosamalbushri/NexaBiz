import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';

/// Labels required for localized rendering of Cash Flow Statement.
class CashFlowReportLabels {
  const CashFlowReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.operatingActivitiesHeader,
    required this.investingActivitiesHeader,
    required this.financingActivitiesHeader,
    required this.openingCashLabel,
    required this.netCashMovementLabel,
    required this.endingCashLabel,
    required this.accountCodeLabel,
    required this.accountNameLabel,
    required this.inflowLabel,
    required this.outflowLabel,
    required this.netFlowLabel,
    required this.totalsLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String periodAll;
  final String operatingActivitiesHeader;
  final String investingActivitiesHeader;
  final String financingActivitiesHeader;
  final String openingCashLabel;
  final String netCashMovementLabel;
  final String endingCashLabel;
  final String accountCodeLabel;
  final String accountNameLabel;
  final String inflowLabel;
  final String outflowLabel;
  final String netFlowLabel;
  final String totalsLabel;
  final String emptyMessage;
}

/// Cash movement line row.
class CashFlowLineItem {
  const CashFlowLineItem({
    required this.accountCode,
    required this.accountName,
    required this.inflow,
    required this.outflow,
    required this.netFlow,
  });

  final String accountCode;
  final String accountName;
  final double inflow;
  final double outflow;
  final double netFlow;
}

/// Data payload for Cash Flow Statement.
class CashFlowReportPayload {
  const CashFlowReportPayload({
    required this.labels,
    required this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    required this.operatingItems,
    required this.investingItems,
    required this.financingItems,
    required this.openingCashBalance,
    required this.totalOperatingNet,
    required this.totalInvestingNet,
    required this.totalFinancingNet,
    required this.netCashChange,
    required this.endingCashBalance,
  });

  final CashFlowReportLabels labels;
  final String baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;

  final List<CashFlowLineItem> operatingItems;
  final List<CashFlowLineItem> investingItems;
  final List<CashFlowLineItem> financingItems;

  final double openingCashBalance;
  final double totalOperatingNet;
  final double totalInvestingNet;
  final double totalFinancingNet;
  final double netCashChange;
  final double endingCashBalance;
}

/// Data port interface for Cash Flow reporting.
abstract class CashFlowReportDataPort {
  Future<CashFlowReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required CashFlowReportLabels labels,
  });
}

/// Provider for CashFlowReportDataPort.
final cashFlowReportDataPortProvider = Provider<CashFlowReportDataPort>((ref) {
  throw UnimplementedError(
    'cashFlowReportDataPortProvider must be overridden in providerOverrides',
  );
});
