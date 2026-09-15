import 'package:flutter/material.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_pagination_bar.dart';

import 'app_layout_tokens.dart';
import 'app_page.dart';

/// Canonical Table View Page layout component for NexaBiz ERP screens.
///
/// Designed specifically for dense financial data tables, general ledgers, voucher lists,
/// and document tables requiring wide desktop constraints.
class AppTablePage extends StatelessWidget {
  const AppTablePage({
    super.key,
    required this.title,
    required this.table,
    this.subtitle,
    this.breadcrumbs,
    this.headerActions,
    this.toolbar,
    this.filterBar,
    this.isLoading = false,
    this.errorText,
    this.onRetry,
    this.isEmpty = false,
    this.emptyTitle = 'لا توجد سجلات',
    this.emptySubtitle = 'لا توجد بيانات متاحة لعرضها في الجدول',
    this.onEmptyAction,
    this.emptyActionLabel,
    this.page = 0,
    this.totalPages = 1,
    this.totalCount = 0,
    this.pageSize = 25,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 25, 50, 100],
    this.floatingActionButton,
    this.maxWidth = AppLayoutTokens.maxTableWidth,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? headerActions;

  final Widget table;
  final Widget? toolbar;
  final Widget? filterBar;

  // Feedback states
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;

  final Widget? floatingActionButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      maxWidth: maxWidth,
      scrollable: false,
      floatingActionButton: floatingActionButton,
      header: AppPageHeader(
        title: title,
        subtitle: subtitle,
        breadcrumbs: breadcrumbs,
        actions: headerActions,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (toolbar != null) ...[
            toolbar!,
            const SizedBox(height: AppLayoutTokens.tableToolbarGap),
          ],
          if (filterBar != null) ...[
            filterBar!,
            const SizedBox(height: AppLayoutTokens.tableFilterGap),
          ],
          Expanded(child: _buildTableBody()),
          if (onPageChanged != null && totalPages > 1) ...[
            const SizedBox(height: AppLayoutTokens.tablePaginationGap),
            AppPaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              pageSizeOptions: pageSizeOptions,
              onPageChanged: onPageChanged!,
              onPageSizeChanged: onPageSizeChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (isLoading) {
      return const AppLoading();
    }
    if (errorText != null) {
      return AppErrorState(message: errorText, onRetry: onRetry);
    }
    if (isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        onAction: onEmptyAction,
        actionLabel: emptyActionLabel,
      );
    }
    return table;
  }
}

