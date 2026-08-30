import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/report_engine/report_engine.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_providers.dart';

/// App navigation entry point for Product Stock Movement Report (تقرير حركة الأصناف والمخزون).
/// Powered by the dynamic Universal ERP Report Engine.
class ProductStockMovementReportPage extends ConsumerWidget {
  const ProductStockMovementReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);
    final currencyCode = companyAsync.valueOrNull?.defaultCurrencyCode ?? 'SAR';
    final companyName = companyAsync.valueOrNull?.name ?? 'NexaBiz ERP';

    final inventoryDb = ref.watch(inventoryDatabaseProvider);
    final salesDb = ref.watch(salesDatabaseProvider);

    final provider = StockMovementReportDataProvider(
      inventoryDb: inventoryDb,
      salesDb: salesDb,
      companyName: companyName,
    );

    return UniversalReportViewerPage(
      definition: stockMovementReportSpec,
      dataProvider: provider,
      currencyCode: currencyCode,
    );
  }
}
