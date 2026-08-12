import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Shared pagination control used across inventory list / grid screens.
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPrev = page > 0;
    final canNext = totalPages > 0 && page < totalPages - 1;
    final from = totalCount == 0 ? 0 : page * pageSize + 1;
    final to = totalCount == 0
        ? 0
        : ((page + 1) * pageSize).clamp(0, totalCount);
    final pageLabel = l10n.paginationPage(
      totalPages == 0 ? 0 : page + 1,
      totalPages,
    );

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
                tooltip: l10n.paginationItemsPerPage,
                onChanged: onPageSizeChanged!,
              )
            else
              Expanded(
                child: Text(
                  l10n.paginationRange(from, to, totalCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
            const SizedBox(width: AppSpacing.xs),
            _PaginationIconButton(
              tooltip: l10n.previousPage,
              icon: Icons.chevron_left_rounded,
              enabled: canPrev,
              onPressed: () => onPageChanged(page - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    pageLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            _PaginationIconButton(
              tooltip: l10n.nextPage,
              icon: Icons.chevron_right_rounded,
              enabled: canNext,
              onPressed: () => onPageChanged(page + 1),
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
                DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size'),
                ),
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

class _PaginationIconButton extends StatelessWidget {
  const _PaginationIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.28);
    final background = enabled
        ? colorScheme.primary.withValues(alpha: 0.10)
        : colorScheme.onSurface.withValues(alpha: 0.04);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 22, color: accent),
          ),
        ),
      ),
    );
  }
}
