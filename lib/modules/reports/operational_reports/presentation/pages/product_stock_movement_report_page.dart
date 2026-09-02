import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/report_engine/report_engine.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';

/// App navigation entry point for Product Stock Movement Report (تقرير حركة الأصناف والمخزون).
/// Powered by the dynamic Universal ERP Report Engine.
class ProductStockMovementReportPage extends ConsumerWidget {
  const ProductStockMovementReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);
    final currencyCode = companyAsync.valueOrNull?.defaultCurrencyCode ?? 'SAR';
    final companyName = companyAsync.valueOrNull?.name ?? 'NexaBiz ERP';

    final provider = ref.watch(stockMovementReportEngineDataProvider) ??
        StockMovementReportDataProvider(
          inventoryDb: null as dynamic,
          salesDb: null as dynamic,
          companyName: companyName,
        );

    return UniversalReportViewerPage(
      definition: stockMovementReportSpec,
      dataProvider: provider,
      currencyCode: currencyCode,
    );
  }
}
