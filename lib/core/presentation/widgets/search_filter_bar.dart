import 'package:flutter/material.dart';

import '../../widgets/app_search_toolbar.dart';

/// Standardized search and filter bar component.
///
/// Delegates to canonical [AppSearchToolbar] composite component.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
    this.searchHint = 'بحث...',
    this.debounceMs = 300,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.activeFilterChips = const [],
    this.trailingAction,
  });

  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final int debounceMs;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final List<Widget> activeFilterChips;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchToolbar(
          onSearchChanged: onSearchChanged,
          searchHint: searchHint,
          onFilterTap: onFilterTap,
          filterCount: activeFilterCount,
          actions: trailingAction != null ? [trailingAction!] : null,
        ),
        if (activeFilterChips.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: activeFilterChips),
          ),
        ],
      ],
    );
  }
}
