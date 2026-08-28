import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_tree_node.dart';
import '../../domain/services/account_labels.dart';
import 'account_type_style.dart';

/// Reusable hierarchical Chart of Accounts tree.
///
/// Fully virtualized using ListView.builder to handle thousands of accounts
/// without UI lag or frame drops.
class AccountTree extends StatelessWidget {
  const AccountTree({
    super.key,
    required this.roots,
    required this.expandedIds,
    required this.onToggleExpand,
    this.selectedId,
    this.onSelect,
    this.onOpenDetails,
    this.padding = EdgeInsets.zero,
  });

  final List<AccountTreeNode> roots;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggleExpand;
  final String? selectedId;
  final ValueChanged<Account>? onSelect;
  final ValueChanged<Account>? onOpenDetails;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (roots.isEmpty) {
      return const SizedBox.shrink();
    }

    final flatEntries = AccountTreeNode.flatten(
      roots,
      expandedIds: expandedIds,
      selectedId: selectedId,
    );

    return ListView.builder(
      padding: padding,
      itemCount: flatEntries.length,
      itemBuilder: (context, index) {
        final entry = flatEntries[index];
        final childWidget = entry.isRoot
            ? Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                child: _AccountRootCard(
                  entry: entry,
                  onToggleExpand: () => onToggleExpand(entry.account.uuid),
                  onOpenDetails: onOpenDetails,
                ),
              )
            : _AccountChildRow(
                entry: entry,
                typeColor: accountTypeColor(
                  Theme.of(context).colorScheme,
                  entry.account.accountType,
                ),
                onToggleExpand: entry.node.hasChildren
                    ? () => onToggleExpand(entry.account.uuid)
                    : null,
                onOpenDetails: onOpenDetails == null
                    ? null
                    : () => onOpenDetails!(entry.account),
                onSelect: onSelect == null
                    ? null
                    : () => onSelect!(entry.account),
              );

        // Limit stagger animation to initial visible window to avoid spawning thousands of animators.
        if (index < 12) {
          return childWidget
              .animate(delay: (30 * index).ms)
              .fadeIn(duration: 180.ms, curve: Curves.easeOut)
              .moveY(
                begin: 8,
                end: 0,
                duration: 200.ms,
                curve: Curves.easeOutCubic,
              );
        }

        return childWidget;
      },
    );
  }
}

class _AccountRootCard extends StatelessWidget {
  const _AccountRootCard({
    required this.entry,
    required this.onToggleExpand,
    this.onOpenDetails,
  });

  final AccountTreeFlatEntry entry;
  final VoidCallback onToggleExpand;
  final ValueChanged<Account>? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final account = entry.account;
    final node = entry.node;
    final typeColor = accountTypeColor(theme.colorScheme, account.accountType);
    final expanded = entry.isExpanded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: typeColor.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10,
          ),
          child: InkWell(
            onTap: node.hasChildren
                ? onToggleExpand
                : () => onOpenDetails?.call(account),
            onLongPress: onOpenDetails == null
                ? null
                : () => onOpenDetails!(account),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TypeAvatar(type: account.accountType, color: typeColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AccountLabels.displayName(l10n, account),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                AccountLabels.typeLabel(
                                  l10n,
                                  account.accountType,
                                ),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (node.hasChildren) ...[
                              Text(
                                ' · ',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                l10n.accountingSectionChildrenCount(
                                  node.descendantCount,
                                ),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _TrailingCode(
                    code: account.accountCode,
                    emphasis: true,
                    color: typeColor,
                  ),
                  if (node.hasChildren)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.xs,
                      ),
                      child: AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: typeColor,
                        ),
                      ),
                    )
                  else if (onOpenDetails != null)
                    IconButton(
                      tooltip: l10n.accountingAccountDetails,
                      onPressed: () => onOpenDetails!(account),
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountChildRow extends StatelessWidget {
  const _AccountChildRow({
    required this.entry,
    required this.typeColor,
    this.onToggleExpand,
    this.onOpenDetails,
    this.onSelect,
  });

  final AccountTreeFlatEntry entry;
  final Color typeColor;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final account = entry.account;
    final displayName = AccountLabels.displayName(l10n, account);
    final depthInset = (entry.depth * 12.0);
    final selected = entry.isSelected;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (entry.node.hasChildren && onToggleExpand != null) {
            onToggleExpand!();
          } else {
            (onSelect ?? onOpenDetails)?.call();
          }
        },
        onLongPress: onOpenDetails,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.sm + depthInset,
            end: AppSpacing.sm,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: entry.node.hasChildren
                    ? InkWell(
                        onTap: onToggleExpand,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: AnimatedRotation(
                          turns: entry.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 22,
                            color: typeColor.withValues(alpha: 0.9),
                          ),
                        ),
                      )
                    : Icon(
                        account.isGroup ? Icons.folder_outlined : Icons.circle,
                        size: account.isGroup ? 16 : 7,
                        color: typeColor.withValues(alpha: 0.75),
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: account.isGroup
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: account.isActive
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    if (account.isGroup ||
                        account.isSystemAccount ||
                        !account.isActive) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (account.isGroup)
                            AppStatusBadge(
                              label: l10n.accountingAccountGroup,
                              tone: AppStatusTone.neutral,
                              animate: false,
                            ),
                          if (account.isSystemAccount)
                            AppStatusBadge(
                              label: l10n.accountingSystemAccount,
                              tone: AppStatusTone.info,
                              animate: false,
                            ),
                          if (!account.isActive)
                            AppStatusBadge(
                              label: l10n.accountingAccountInactive,
                              tone: AppStatusTone.warning,
                              animate: false,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TrailingCode(code: account.accountCode, color: typeColor),
              if (onOpenDetails != null)
                IconButton(
                  tooltip: l10n.accountingAccountDetails,
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpenDetails,
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({required this.type, required this.color});

  final AccountType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(accountTypeIcon(type), color: color, size: 22),
    );
  }
}

class _TrailingCode extends StatelessWidget {
  const _TrailingCode({
    required this.code,
    required this.color,
    this.emphasis = false,
  });

  final String code;
  final Color color;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: EdgeInsets.symmetric(
        horizontal: emphasis ? 7 : 5,
        vertical: emphasis ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: emphasis ? 11.5 : 10.5,
        ),
      ),
    );
  }
}
