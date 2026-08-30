import 'package:flutter/foundation.dart';
import '../domain/models/report_cursor.dart';
import '../domain/models/report_dataset.dart';
import '../domain/models/report_execution_context.dart';
import '../domain/models/report_summary.dart';
import '../domain/services/paged_report_data_provider.dart';

/// State snapshot for universal report execution.
@immutable
class UniversalReportState {
  const UniversalReportState({
    required this.context,
    this.summary,
    this.items = const [],
    this.nextCursor,
    this.hasNextPage = false,
    this.isLoadingSummary = false,
    this.isLoadingFirstPage = false,
    this.isLoadingNextPage = false,
    this.summaryError,
    this.pageError,
  });

  final ReportExecutionContext context;
  final ReportSummary? summary;
  final List<ReportRowData> items;
  final ReportCursor? nextCursor;
  final bool hasNextPage;
  final bool isLoadingSummary;
  final bool isLoadingFirstPage;
  final bool isLoadingNextPage;
  final String? summaryError;
  final String? pageError;

  bool get isLoading => isLoadingSummary || isLoadingFirstPage;
  bool get isEmpty => !isLoadingFirstPage && items.isEmpty;

  UniversalReportState copyWith({
    ReportExecutionContext? context,
    ReportSummary? summary,
    List<ReportRowData>? items,
    ReportCursor? nextCursor,
    bool? hasNextPage,
    bool? isLoadingSummary,
    bool? isLoadingFirstPage,
    bool? isLoadingNextPage,
    String? summaryError,
    String? pageError,
    bool clearSummaryError = false,
    bool clearPageError = false,
    bool clearNextCursor = false,
  }) {
    return UniversalReportState(
      context: context ?? this.context,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      summaryError: clearSummaryError ? null : (summaryError ?? this.summaryError),
      pageError: clearPageError ? null : (pageError ?? this.pageError),
    );
  }
}

/// Execution Controller for NexaBiz Paged Report Engine.
/// Strictly read-only, context-safe, request-token concurrency protected, and memory efficient.
class UniversalReportExecutionController extends ValueNotifier<UniversalReportState> {
  UniversalReportExecutionController({
    required this.provider,
    required ReportExecutionContext initialContext,
    this.pageSize = 50,
  }) : super(UniversalReportState(context: initialContext));

  final PagedReportDataProvider<ReportRowData> provider;
  final int pageSize;

  /// Concurrency request token token to prevent out-of-order execution race conditions
  int _activeRequestToken = 0;

  /// Executes full query (Summary + First Page) with new [ReportExecutionContext].
  /// Cancels previous pagination state and invalidates existing cursors.
  Future<void> executeNewContext(ReportExecutionContext newContext) async {
    final token = ++_activeRequestToken;

    value = UniversalReportState(
      context: newContext,
      isLoadingSummary: true,
      isLoadingFirstPage: true,
    );

    // 1. Async Fetch Summary
    try {
      final summary = await provider.fetchSummary(newContext);
      if (token != _activeRequestToken) return; // Stale request ignored

      value = value.copyWith(
        summary: summary,
        isLoadingSummary: false,
        clearSummaryError: true,
      );
    } catch (e) {
      if (token != _activeRequestToken) return;
      value = value.copyWith(
        isLoadingSummary: false,
        summaryError: e.toString(),
      );
    }

    // 2. Async Fetch First Page (cursor: null)
    try {
      final firstPage = await provider.fetchPage(
        newContext,
        cursor: null,
        pageSize: pageSize,
      );
      if (token != _activeRequestToken) return; // Stale request ignored

      value = value.copyWith(
        items: firstPage.items,
        nextCursor: firstPage.nextCursor,
        clearNextCursor: firstPage.nextCursor == null,
        hasNextPage: firstPage.hasNextPage,
        isLoadingFirstPage: false,
        clearPageError: true,
      );
    } catch (e) {
      if (token != _activeRequestToken) return;
      value = value.copyWith(
        isLoadingFirstPage: false,
        pageError: e.toString(),
      );
    }
  }

  /// Incremental fetch of next page using existing [nextCursor].
  Future<void> fetchNextPage() async {
    if (!value.hasNextPage || value.isLoadingNextPage || value.nextCursor == null) {
      return;
    }

    final token = _activeRequestToken;
    final currentCursor = value.nextCursor;

    value = value.copyWith(isLoadingNextPage: true, clearPageError: true);

    try {
      final page = await provider.fetchPage(
        value.context,
        cursor: currentCursor,
        pageSize: pageSize,
      );

      if (token != _activeRequestToken) return; // Stale request ignored

      value = value.copyWith(
        items: [...value.items, ...page.items],
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        hasNextPage: page.hasNextPage,
        isLoadingNextPage: false,
        clearPageError: true,
      );
    } catch (e) {
      if (token != _activeRequestToken) return;
      value = value.copyWith(
        isLoadingNextPage: false,
        pageError: e.toString(),
      );
    }
  }

  /// Refreshes current report execution context from beginning.
  Future<void> refresh() => executeNewContext(value.context);
}
