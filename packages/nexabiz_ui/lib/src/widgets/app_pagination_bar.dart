import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shared pagination control used across inventory list / grid screens.
///
/// Refactored to compose [shadcn.Pagination] internally while maintaining the
/// 0-indexed page index application contract, page-size selection, and item range stats.
class AppPaginationBar extends StatelessWidget {
  const AppPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
    this.pageSizeOptions = const [],
    this.onPageSizeChanged,
    this.compact = false,
  });

  /// Zero-based page index.
  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  /// When non-empty and [onPageSizeChanged] is set, shows a page-size menu.
  final List<int> pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;

  /// When true, uses tighter padding (e.g. inside data grids).
  final bool compact;

  bool get _canChangePageSize =>
      pageSizeOptions.isNotEmpty && onPageSizeChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final from = totalCount == 0 ? 0 : page * pageSize + 1;
    final to = totalCount == 0
        ? 0
        : ((page + 1) * pageSize).clamp(0, totalCount);

    final safe1BasedPage = totalPages <= 0 ? 1 : (page + 1).clamp(1, totalPages);
    final safeTotalPages = totalPages <= 0 ? 1 : totalPages;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (_canChangePageSize)
              _PageSizeSelector(
                pageSize: pageSize,
                options: pageSizeOptions,
                tooltip: 'Items per page',
                onChanged: onPageSizeChanged!,
              )
            else
              Text(
                '$from - $to of $totalCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: shadcn.Pagination(
                    page: safe1BasedPage,
                    totalPages: safeTotalPages,
                    maxPages: compact ? 3 : 5,
                    showSkipToFirstPage: !compact,
                    showSkipToLastPage: !compact,
                    onPageChanged: (new1BasedPage) {
                      onPageChanged(new1BasedPage - 1);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.pageSize,
    required this.options,
    required this.tooltip,
    required this.onChanged,
  });

  final int pageSize;
  final List<int> options;
  final String tooltip;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safeValue = options.contains(pageSize) ? pageSize : options.first;

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: safeValue,
            isDense: true,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: AppSpacing.xs,
            ),
            icon: Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            items: [
              for (final size in options)
                DropdownMenuItem<int>(value: size, child: Text('$size')),
            ],
            onChanged: (value) {
              if (value == null || value == pageSize) {
                return;
              }
              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}
