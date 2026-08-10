import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/report_export_labels.dart';
import '../../domain/models/report_export_result.dart';
import 'inventory_providers.dart';

enum ReportExportFormat { excel, pdf }

const int kReportPageSize = 20;

final reportsSearchQueryProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final reportsSelectedFilterProvider =
    StateProvider.autoDispose<ReportFilter>((ref) {
  return ReportFilter.all;
});

final reportPageIndexProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

/// Loads one page of report rows (does not bind the full list to the grid).
final pagedReportItemsProvider =
    FutureProvider.autoDispose<PagedResult<InventoryItem>>((ref) async {
  ref.watch(inventoryRevisionProvider);

  final page = ref.watch(reportPageIndexProvider);
  final query = ref.watch(reportsSearchQueryProvider);
  final filter = ref.watch(reportsSelectedFilterProvider);

  return ref.read(inventoryRepositoryProvider).getPaged(
        page: page,
        pageSize: kReportPageSize,
        query: query,
        status: filter.status,
      );
});

class ReportExportNotifier extends StateNotifier<AsyncValue<String?>> {
  ReportExportNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<List<InventoryItem>> _loadFilteredItems() async {
    final query = _ref.read(reportsSearchQueryProvider).trim().toLowerCase();
    final filter = _ref.read(reportsSelectedFilterProvider);
    final items = await _ref.read(inventoryRepositoryProvider).getAll();

    return [
      for (final item in items)
        if ((filter.status == null || item.status == filter.status) &&
            (query.isEmpty ||
                item.itemName.toLowerCase().contains(query) ||
                item.itemCode.toLowerCase().contains(query) ||
                (item.barcode?.toLowerCase().contains(query) ?? false)))
          item,
    ];
  }

  /// Fast validation before any loading UI is shown.
  Future<ReportExportValidationError?> validateBeforeExport() async {
    final items = await _loadFilteredItems();
    if (items.isEmpty) {
      return const ReportExportValidationError(
        ReportExportValidationError.emptyItems,
      );
    }
    return null;
  }

  Future<ReportExportResult> exportReport({
    required ReportExportFormat format,
    required ReportExportLabels labels,
  }) async {
    state = const AsyncLoading();
    try {
      final validationError = await validateBeforeExport();
      if (validationError != null) {
        state = const AsyncData(null);
        return validationError;
      }

      final items = await _loadFilteredItems();
      final path = switch (format) {
        ReportExportFormat.excel => await _ref
            .read(excelExportDatasourceProvider)
            .export(items: items, labels: labels),
        ReportExportFormat.pdf => await _ref
            .read(pdfExportDatasourceProvider)
            .export(items: items, labels: labels),
      };
      state = AsyncData(path);
      return ReportExportSuccess(path);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return ReportExportFailure(error.toString());
    }
  }

  Future<void> shareExportedFile(String path) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)]),
    );
  }
}

final reportExportProvider = StateNotifierProvider.autoDispose<
    ReportExportNotifier, AsyncValue<String?>>(
  (ref) => ReportExportNotifier(ref),
);
