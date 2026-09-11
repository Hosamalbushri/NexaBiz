import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../patterns/app_list_page_pattern.dart';

/// Reusable ERP Module List Page Scaffold.
///
/// Delegates to canonical [AppListPagePattern] while maintaining backwards compatibility
/// for legacy list screen invocations.
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
    return AppListPagePattern<T>(
      title: title,
      headerActions: actions,
      items: items,
      isLoading: isLoading,
      errorText: error?.toString(),
      onRetry: onRetry ?? (onRefresh != null ? () => onRefresh!() : null),
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      onFilterTap: onFilterTap,
      activeFilterCount: activeFilterCount,
      activeFilterChips: activeFilterChips,
      emptyTitle: emptyTitle,
      emptySubtitle: emptyMessage,
      onEmptyAction: onEmptyAction,
      emptyActionLabel: emptyActionLabel,
      floatingActionButton: floatingActionButton,
      contentBuilder: (ctx, itemList) {
        if (gridDelegate != null) {
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: gridDelegate!,
            itemCount: itemList.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (c, index) {
              if (index >= itemList.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return itemBuilder(c, itemList[index]);
            },
          );
        }

        Widget content = ListView.separated(
          padding: const EdgeInsets.all(12.0),
          itemCount: itemList.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8.0),
          itemBuilder: (c, index) {
            if (index >= itemList.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return itemBuilder(c, itemList[index]);
          },
        );

        if (onLoadMore != null) {
          content = NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!isLoadingMore &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                onLoadMore!();
              }
              return false;
            },
            child: content,
          );
        }

        if (onRefresh != null) {
          content = shadcn.RefreshTrigger(onRefresh: onRefresh, child: content);
        }

        return content;
      },
    );
  }
}
