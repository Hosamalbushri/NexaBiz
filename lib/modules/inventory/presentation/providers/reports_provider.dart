import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/models/catalog_search_field.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/report_export_labels.dart';
import '../../domain/models/report_export_result.dart';
import 'inventory_providers.dart';

enum ReportExportFormat { excel, pdf }

const int kReportPageSize = 20;

const List<int> kReportPageSizeOptions = [10, 20, 30, 50];

final reportsSearchQueryProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final reportsSearchFieldProvider =
    StateProvider.autoDispose<CatalogSearchField>(
      (ref) => CatalogSearchField.all,
    );

final reportsSelectedFilterProvider = StateProvider.autoDispose<ReportFilter>((
  ref,
) {
  return ReportFilter.all;
});

final reportPageIndexProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final reportPageSizeProvider = StateProvider.autoDispose<int>(
  (ref) => kReportPageSize,
);

/// Loads one page of report rows (does not bind the full list to the grid).
final pagedReportItemsProvider =
    FutureProvider.autoDispose<PagedResult<InventoryItem>>((ref) async {
      ref.watch(inventoryRevisionProvider);

      final page = ref.watch(reportPageIndexProvider);
      final pageSize = ref.watch(reportPageSizeProvider);
      final query = ref.watch(reportsSearchQueryProvider);
      final searchField = ref.watch(reportsSearchFieldProvider);
      final filter = ref.watch(reportsSelectedFilterProvider);

      return ref
          .read(inventoryRepositoryProvider)
          .getPaged(
            page: page,
            pageSize: pageSize,
            query: query,
            searchField: searchField,
            status: filter.status,
          );
    });

class ReportExportNotifier extends StateNotifier<AsyncValue<String?>> {
  ReportExportNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<List<InventoryItem>> _loadFilteredItems() async {
    final query = _ref.read(reportsSearchQueryProvider);
    final searchField = _ref.read(reportsSearchFieldProvider);
    final filter = _ref.read(reportsSelectedFilterProvider);
    final items = await _ref
        .read(inventoryRepositoryProvider)
        .search(query, searchField: searchField);
    final status = filter.status;
    if (status == null) {
      return items;
    }
    return [for (final item in items) if (item.status == status) item];
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
        ReportExportFormat.excel =>
          await _ref
              .read(excelExportDatasourceProvider)
              .export(items: items, labels: labels),
        ReportExportFormat.pdf =>
          await _ref
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
    final lower = path.toLowerCase();
    final mimeType = lower.endsWith('.pdf')
        ? 'application/pdf'
        : lower.endsWith('.xlsx')
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : null;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        subject: 'Inventory report',
      ),
    );
  }

  /// Opens the system print dialog for the export (PDF file, or a PDF
  /// regenerating of the current filtered report when the export was Excel).
  Future<void> printExportedFile(
    String path, {
    required ReportExportLabels labels,
  }) async {
    final Uint8List bytes;
    if (path.toLowerCase().endsWith('.pdf')) {
      final file = File(path);
      if (!await file.exists()) {
        throw StateError('Exported file not found.');
      }
      bytes = await file.readAsBytes();
    } else {
      final items = await _loadFilteredItems();
      final pdfPath = await _ref
          .read(pdfExportDatasourceProvider)
          .export(items: items, labels: labels);
      bytes = await File(pdfPath).readAsBytes();
    }

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: p.basenameWithoutExtension(path),
    );
  }
}

final reportExportProvider =
    StateNotifierProvider.autoDispose<
      ReportExportNotifier,
      AsyncValue<String?>
    >((ref) => ReportExportNotifier(ref));
