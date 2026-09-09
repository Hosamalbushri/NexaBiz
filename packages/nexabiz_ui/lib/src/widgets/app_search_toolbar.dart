import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_search_field.dart';

/// Canonical search toolbar composite for NexaBiz ERP lists and tables.
///
/// Combines search field with optional filter trigger, view mode toggle,
/// and sort action dropdown.
class AppSearchToolbar extends StatelessWidget {
  const AppSearchToolbar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint = 'Search...',
    this.onFilterTap,
    this.filterCount = 0,
    this.actions,
  });

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String searchHint;
  final VoidCallback? onFilterTap;
  final int filterCount;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: searchController,
              hint: searchHint,
              onChanged: onSearchChanged,
              onClear: onSearchClear,
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: filterCount > 0 ? 'Filters ($filterCount)' : 'Filters',
              icon: Icons.tune_rounded,
              variant: filterCount > 0
                  ? AppButtonVariant.filled
                  : AppButtonVariant.outlined,
              onPressed: onFilterTap,
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
