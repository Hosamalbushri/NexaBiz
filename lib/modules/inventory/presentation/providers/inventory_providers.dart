import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl();
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

final inventoryItemsProvider =
    StreamProvider.autoDispose<List<InventoryItem>>((ref) {
  return ref.watch(watchInventoryItemsProvider).call();
});

final reportSummaryProvider = Provider.autoDispose<ReportSummary>((ref) {
  final items = ref.watch(inventoryItemsProvider).valueOrNull ?? const [];
  return ReportSummary.fromItems(items);
});
