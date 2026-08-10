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

/// Full filtered list for export only.
final filteredReportItemsProvider =
    Provider.autoDispose<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryItemsProvider).valueOrNull ?? const [];
  final query = ref.watch(reportsSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(reportsSelectedFilterProvider);

  Iterable<InventoryItem> filtered = items;
  final status = filter.status;
  if (status != null) {
    filtered = filtered.where((item) => item.status == status);
  }
  if (query.isNotEmpty) {
    filtered = filtered.where((item) {
      return item.itemName.toLowerCase().contains(query) ||
          item.itemCode.toLowerCase().contains(query) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
    });
  }
  return filtered.toList(growable: false);
});

/// Loads one page of report rows (does not bind the full list to the grid).
final pagedReportItemsProvider =
    FutureProvider.autoDispose<PagedResult<InventoryItem>>((ref) async {
  ref.watch(inventoryItemsProvider);

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

  /// Fast validation before any loading UI is shown.
  ReportExportValidationError? validateBeforeExport() {
    final inventory = _ref.read(inventoryItemsProvider);
    if (inventory.isLoading) {
      return const ReportExportValidationError(
        ReportExportValidationError.dataNotReady,
      );
    }
    if (inventory.hasError) {
      return const ReportExportValidationError(
        ReportExportValidationError.dataNotReady,
      );
    }

    final items = _ref.read(filteredReportItemsProvider);
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
    final validationError = validateBeforeExport();
    if (validationError != null) {
      state = const AsyncData(null);
      return validationError;
    }

    state = const AsyncLoading();
    try {
      final items = _ref.read(filteredReportItemsProvider);
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
