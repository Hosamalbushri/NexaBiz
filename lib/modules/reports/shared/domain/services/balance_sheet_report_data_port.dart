import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';

/// Labels required for localized rendering of the Balance Sheet.
class BalanceSheetReportLabels {
  const BalanceSheetReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.asOfDateLabel,
    required this.assetsHeader,
    required this.liabilitiesHeader,
    required this.equityHeader,
    required this.retainedEarningsLabel,
    required this.totalAssetsLabel,
    required this.totalLiabilitiesLabel,
    required this.totalEquityLabel,
    required this.totalLiabilitiesAndEquityLabel,
    required this.balancedLabel,
    required this.unbalancedLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String asOfDateLabel;
  final String assetsHeader;
  final String liabilitiesHeader;
  final String equityHeader;
  final String retainedEarningsLabel;
  final String totalAssetsLabel;
  final String totalLiabilitiesLabel;
  final String totalEquityLabel;
  final String totalLiabilitiesAndEquityLabel;
  final String balancedLabel;
  final String unbalancedLabel;
  final String emptyMessage;
}

/// One account line item in the Balance Sheet.
class BalanceSheetLineItem {
  const BalanceSheetLineItem({
    required this.accountCode,
    required this.accountName,
    required this.amount,
  });

  final String accountCode;
  final String accountName;
  final double amount;
}

/// Data payload for Balance Sheet.
class BalanceSheetReportPayload {
  const BalanceSheetReportPayload({
    required this.labels,
    required this.baseCurrencyCode,
    this.asOfDate,
    required this.assetItems,
    required this.liabilityItems,
    required this.equityItems,
    required this.retainedEarnings,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
  });

  final BalanceSheetReportLabels labels;
  final String baseCurrencyCode;
  final DateTime? asOfDate;

  final List<BalanceSheetLineItem> assetItems;
  final List<BalanceSheetLineItem> liabilityItems;
  final List<BalanceSheetLineItem> equityItems;

  final double retainedEarnings;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalLiabilitiesAndEquity;
  final bool isBalanced;
}

/// Data port interface for Balance Sheet reporting.
abstract class BalanceSheetReportDataPort {
  Future<BalanceSheetReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required BalanceSheetReportLabels labels,
  });
}

/// Provider for BalanceSheetReportDataPort.
final balanceSheetReportDataPortProvider = Provider<BalanceSheetReportDataPort>((
  ref,
) {
  throw UnimplementedError(
    'balanceSheetReportDataPortProvider must be overridden in providerOverrides',
  );
});
