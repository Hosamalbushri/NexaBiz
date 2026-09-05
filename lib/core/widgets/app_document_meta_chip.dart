import 'package:flutter/material.dart';

import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Reusable interactive meta info chip for document headers (e.g. Document #, Date).
class AppDocumentMetaChip extends StatelessWidget {
  const AppDocumentMetaChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.secondaryValue,
    this.onTap,
    this.emphasized = false,
    this.editIcon = Icons.edit_calendar_outlined,
  });

  final String label;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;
  final IconData? editIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = emphasized
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final iconBg = emphasized
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.onSurface.withValues(alpha: 0.06);
    final iconColor = emphasized ? scheme.primary : scheme.onSurfaceVariant;
    final valueColor = emphasized ? scheme.primary : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: emphasized
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                          letterSpacing: -0.15,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (secondaryValue != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        secondaryValue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null && editIcon != null) ...[
                const SizedBox(width: 2),
                Icon(
                  editIcon,
                  size: 15,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
