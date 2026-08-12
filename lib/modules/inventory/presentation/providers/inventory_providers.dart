import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../data/datasources/excel_export_datasource.dart';
import '../../data/datasources/excel_import_datasource.dart';
import '../../data/datasources/pdf_export_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/services/counting_calculator.dart';
import '../../domain/services/pack_size_parser.dart';
import '../../domain/usecases/inventory_usecases.dart';

final inventoryRepositoryImplProvider = Provider<InventoryRepositoryImpl>((ref) {
  return InventoryRepositoryImpl(syncQueue: ref.watch(syncQueueProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return ref.watch(inventoryRepositoryImplProvider);
});

final packSizeParserProvider = Provider<PackSizeParser>((ref) {
  return const PackSizeParser();
});

final countingCalculatorProvider = Provider<CountingCalculator>((ref) {
  return const CountingCalculator();
});

final excelImportDatasourceProvider = Provider<ExcelImportDatasource>((ref) {
  return ExcelImportDatasource(
    packSizeParser: ref.watch(packSizeParserProvider),
  );
});

final excelExportDatasourceProvider = Provider<ExcelExportDatasource>((ref) {
  return ExcelExportDatasource();
});

final pdfExportDatasourceProvider = Provider<PdfExportDatasource>((ref) {
  return PdfExportDatasource();
});

final getInventoryItemsProvider = Provider<GetInventoryItems>((ref) {
  return GetInventoryItems(ref.watch(inventoryRepositoryProvider));
});

final watchInventoryItemsProvider = Provider<WatchInventoryItems>((ref) {
  return WatchInventoryItems(ref.watch(inventoryRepositoryProvider));
});

final searchInventoryItemsProvider = Provider<SearchInventoryItems>((ref) {
  return SearchInventoryItems(ref.watch(inventoryRepositoryProvider));
});

final saveInventoryCountProvider = Provider<SaveInventoryCount>((ref) {
  return SaveInventoryCount(ref.watch(inventoryRepositoryProvider));
});

final replaceInventoryItemsProvider = Provider<ReplaceInventoryItems>((ref) {
  return ReplaceInventoryItems(ref.watch(inventoryRepositoryProvider));
});

/// Lightweight invalidation for count/search/reports pages — avoids rebuilding
/// from a full Hive `watchAll()` stream on every mutation.
final inventoryRevisionProvider = StateProvider<int>((ref) => 0);

void bumpInventoryRevision(Ref ref) {
  ref.read(inventoryRevisionProvider.notifier).state++;
}

void bumpInventoryRevisionFromWidget(WidgetRef ref) {
  ref.read(inventoryRevisionProvider.notifier).state++;
}

/// Full catalog stream — prefer [inventoryRevisionProvider] + paged queries
/// for list UIs. Kept for callers that still need a live full list.
final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(watchInventoryItemsProvider).call();
});

/// Report KPIs without materializing a full `List` in providers first.
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((
  ref,
) async {
  ref.watch(inventoryRevisionProvider);
  return ref.read(inventoryRepositoryProvider).getReportSummary();
});
