import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/settings/company/functional_currency_providers.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/report_engine/report_engine.dart';
import 'package:stock_count/modules/reports/data/definitions/stock_movement_report_spec.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';

/// App navigation entry point for Product Stock Movement Report (تقرير حركة الأصناف والمخزون).
/// Powered by the dynamic Universal ERP Report Engine.
class ProductStockMovementReportPage extends ConsumerWidget {
  const ProductStockMovementReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);
    final currencyInfoAsync = ref.watch(functionalCurrencyStateInfoProvider);
    final currencyCode = currencyInfoAsync.valueOrNull?.currencyCode ?? '';
    final companyName = companyAsync.valueOrNull?.name ?? 'NexaBiz ERP';

    final provider =
        ref.watch(stockMovementReportEngineDataProvider) ??
        StockMovementReportDataProvider(
          db: ref.watch(nexabizDatabaseProvider),
          companyName: companyName,
        );

    return UniversalReportViewerPage(
      definition: stockMovementReportSpec,
      dataProvider: provider,
      currencyCode: currencyCode,
    );
  }
}
