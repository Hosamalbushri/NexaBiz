import 'package:flutter/material.dart';

import '../widgets/app_state_feedback.dart';
import '../widgets/search_filter_bar.dart';

/// Reusable ERP Module List Page Scaffold.
///
/// Standardizes app bar, search bar, list/grid items, loading/empty/error feedback states,
/// pagination, and floating action buttons across business modules.
class ModuleListScaffold<T> extends StatelessWidget {
  const ModuleListScaffold({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.error,
    this.onRefresh,
    this.onRetry,
    this.searchQuery = '',
    this.onSearchChanged,
    this.searchHint = 'بحث...',
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.activeFilterChips = const [],
    this.emptyTitle = 'لا توجد بيانات للعرض',
    this.emptyMessage = 'لم يتم العثور على أي عناصر تطابق معاييرك',
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.floatingActionButton,
    this.actions,
    this.gridDelegate,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool isLoading;
  final Object? error;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;

  // Search & Filter
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final List<Widget> activeFilterChips;

  // Empty State
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  // Scaffold Actions & Layout
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final SliverGridDelegate? gridDelegate;

  // Pagination
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final showSearch = onSearchChanged != null || onFilterTap != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            if (showSearch)
              SearchFilterBar(
                searchQuery: searchQuery,
                onSearchChanged: onSearchChanged,
                searchHint: searchHint,
                onFilterTap: onFilterTap,
                activeFilterCount: activeFilterCount,
                activeFilterChips: activeFilterChips,
              ),
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const AppLoadingState();
    }

    if (error != null && items.isEmpty) {
      return AppErrorState(
        error: error,
        onRetry: onRetry ?? onRefresh,
      );
    }

    if (items.isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }

    Widget contentWidget;

    if (gridDelegate != null) {
      contentWidget = GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: gridDelegate!,
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return itemBuilder(ctx, items[index]);
        },
      );
    } else {
      contentWidget = ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
        itemBuilder: (ctx, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return itemBuilder(ctx, items[index]);
        },
      );
    }

    if (onLoadMore != null) {
      contentWidget = NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoadingMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            onLoadMore!();
          }
          return false;
        },
        child: contentWidget,
      );
    }

    if (onRefresh != null) {
      contentWidget = RefreshIndicator(
        onRefresh: onRefresh!,
        child: contentWidget,
      );
    }

    return contentWidget;
  }
}
