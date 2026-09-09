import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_pagination_bar.dart';
import '../../widgets/app_search_toolbar.dart';
import 'app_page_shell.dart';

/// Canonical List Page Pattern for NexaBiz ERP screens.
///
/// Standardizes Header + Search/Filter Toolbar + Content (Loading/Error/Empty/Table/Grid)
/// + Pagination Bar + Primary FAB layout.
class AppListPagePattern<T> extends StatelessWidget {
  const AppListPagePattern({
    super.key,
    required this.title,
    required this.items,
    required this.contentBuilder,
    this.subtitle,
    this.breadcrumbs,
    this.headerActions,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint = 'Search...',
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.activeFilterChips = const [],
    this.isLoading = false,
    this.errorText,
    this.onRetry,
    this.emptyTitle = 'No records found',
    this.emptySubtitle = 'Try adjusting your search query or filters',
    this.onEmptyAction,
    this.emptyActionLabel,
    this.page = 0,
    this.totalPages = 1,
    this.totalCount = 0,
    this.pageSize = 25,
    this.onPageChanged,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? headerActions;

  final List<T> items;
  final Widget Function(BuildContext context, List<T> items) contentBuilder;

  // Search & Filters
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String searchHint;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final List<Widget> activeFilterChips;

  // Feedback states
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;

  // Pagination
  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;

  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      floatingActionButton: floatingActionButton,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            title: title,
            subtitle: subtitle,
            breadcrumbs: breadcrumbs,
            actions: headerActions,
          ),
          if (onSearchChanged != null || onFilterTap != null)
            AppSearchToolbar(
              searchController: searchController,
              onSearchChanged: onSearchChanged,
              onSearchClear: onSearchClear,
              searchHint: searchHint,
              onFilterTap: onFilterTap,
              filterCount: activeFilterCount,
            ),
          if (activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(children: activeFilterChips),
            ),
          ],
          Expanded(child: _buildBody(context)),
          if (onPageChanged != null && totalPages > 1) ...[
            const SizedBox(height: AppSpacing.md),
            AppPaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              onPageChanged: onPageChanged!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const AppLoading();
    }

    if (errorText != null && items.isEmpty) {
      return AppErrorState(message: errorText, onRetry: onRetry);
    }

    if (items.isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        onAction: onEmptyAction,
        actionLabel: emptyActionLabel,
      );
    }

    return contentBuilder(context, items);
  }
}
