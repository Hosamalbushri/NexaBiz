import 'package:flutter/material.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_pagination_bar.dart';
import '../widgets/app_search_toolbar.dart';
import 'app_layout_tokens.dart';
import 'app_page.dart';

/// Canonical List Page layout component for NexaBiz screens.
///
/// Standardizes Header + Expandable Top-of-Page Search/Filter Toolbar + Content (Loading/Error/Empty/Table/Grid)
/// + Pagination Bar + FAB.
class AppListPage<T> extends StatefulWidget {
  const AppListPage({
    super.key,
    required this.title,
    required this.items,
    required this.contentBuilder,
    this.subtitle,
    this.breadcrumbs,
    this.headerActions,
    this.centerTitle = true,
    this.showBackButton,
    this.onBackTap,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint = 'بحث...',
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.activeFilterChips = const [],
    this.showFilterInHeader = true,
    this.isLoading = false,
    this.errorText,
    this.onRetry,
    this.emptyTitle = 'لا توجد سجلات',
    this.emptySubtitle = 'جرّب تعديل كلمة البحث أو تصفية البيانات',
    this.onEmptyAction,
    this.emptyActionLabel,
    this.page = 0,
    this.totalPages = 1,
    this.totalCount = 0,
    this.pageSize = 25,
    this.onPageChanged,
    this.floatingActionButton,
    this.maxWidth = AppLayoutTokens.maxTableWidth,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? headerActions;
  final bool centerTitle;
  final bool? showBackButton;
  final VoidCallback? onBackTap;

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
  final bool showFilterInHeader;

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
  final double maxWidth;

  @override
  State<AppListPage<T>> createState() => _AppListPageState<T>();
}

class _AppListPageState<T> extends State<AppListPage<T>> {
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.searchController?.text.isNotEmpty == true) {
      _isSearchExpanded = true;
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        widget.searchController?.clear();
        widget.onSearchClear?.call();
        widget.onSearchChanged?.call('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch = widget.onSearchChanged != null || widget.searchController != null;
    final showSearchToolbar = _isSearchExpanded || (widget.searchController?.text.isNotEmpty == true);

    return AppPage(
      maxWidth: widget.maxWidth,
      floatingActionButton: widget.floatingActionButton,
      scrollable: false,
      header: AppPageHeader(
        title: widget.title,
        subtitle: widget.subtitle,
        breadcrumbs: widget.breadcrumbs,
        actions: widget.headerActions,
        centerTitle: widget.centerTitle,
        showBackButton: widget.showBackButton,
        onBack: widget.onBackTap,
        onFilterTap: widget.showFilterInHeader ? widget.onFilterTap : null,
        filterCount: widget.activeFilterCount,
        onSearchTap: hasSearch ? _toggleSearch : null,
        isSearching: showSearchToolbar,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSearch && showSearchToolbar) ...[
            AppSearchToolbar(
              searchController: widget.searchController,
              onSearchChanged: widget.onSearchChanged,
              onSearchClear: () {
                widget.onSearchClear?.call();
                setState(() {
                  _isSearchExpanded = false;
                });
              },
              searchHint: widget.searchHint,
              onFilterTap: widget.showFilterInHeader ? null : widget.onFilterTap,
              filterCount: widget.activeFilterCount,
            ),
          ],
          if (widget.activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: AppLayoutTokens.tableFilterGap),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppLayoutTokens.pagePaddingStandard),
              child: Row(children: widget.activeFilterChips),
            ),
          ],
          Expanded(child: _buildBody(context)),
          if (widget.onPageChanged != null && widget.totalPages > 1) ...[
            const SizedBox(height: AppLayoutTokens.tablePaginationGap),
            AppPaginationBar(
              page: widget.page,
              totalPages: widget.totalPages,
              totalCount: widget.totalCount,
              pageSize: widget.pageSize,
              onPageChanged: widget.onPageChanged!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return const AppLoading();
    }

    if (widget.errorText != null && widget.items.isEmpty) {
      return AppErrorState(message: widget.errorText, onRetry: widget.onRetry);
    }

    if (widget.items.isEmpty) {
      return AppEmptyState(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
        onAction: widget.onEmptyAction,
        actionLabel: widget.emptyActionLabel,
      );
    }

    return widget.contentBuilder(context, widget.items);
  }
}
