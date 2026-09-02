import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/report_engine/report_engine.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';

/// App navigation entry point for Sales Period Analysis Report (تقرير مبيعات الفترة والعملاء).
/// Powered by the dynamic Universal ERP Report Engine.
class SalesPeriodReportPage extends ConsumerWidget {
  const SalesPeriodReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);
    final currencyCode = companyAsync.valueOrNull?.defaultCurrencyCode ?? 'SAR';
    final companyName = companyAsync.valueOrNull?.name ?? 'NexaBiz ERP';

    final provider = ref.watch(salesPeriodReportEngineDataProvider) ??
        SalesPeriodReportDataProvider(
          salesDb: null as dynamic,
          companyName: companyName,
        );

    return UniversalReportViewerPage(
      definition: salesPeriodReportSpec,
      dataProvider: provider,
      currencyCode: currencyCode,
    );
  }
}
