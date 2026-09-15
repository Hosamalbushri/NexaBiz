import 'package:flutter/material.dart';

import '../../layout/app_list_page.dart';

/// Legacy compatible List Page pattern delegating to canonical [AppListPage].
class AppListPagePattern<T> extends StatelessWidget {
  const AppListPagePattern({
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

  @override
  Widget build(BuildContext context) {
    return AppListPage<T>(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      headerActions: headerActions,
      centerTitle: centerTitle,
      showBackButton: showBackButton,
      onBackTap: onBackTap,
      items: items,
      contentBuilder: contentBuilder,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      onSearchClear: onSearchClear,
      searchHint: searchHint,
      onFilterTap: onFilterTap,
      activeFilterCount: activeFilterCount,
      activeFilterChips: activeFilterChips,
      showFilterInHeader: showFilterInHeader,
      isLoading: isLoading,
      errorText: errorText,
      onRetry: onRetry,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      onEmptyAction: onEmptyAction,
      emptyActionLabel: emptyActionLabel,
      page: page,
      totalPages: totalPages,
      totalCount: totalCount,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      floatingActionButton: floatingActionButton,
    );
  }
}
