import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_tree_node.dart';
import '../../domain/services/account_labels.dart';
import 'account_type_style.dart';

/// Reusable hierarchical Chart of Accounts tree.
///
/// Roots render as section cards; children as scannable indented rows with
/// account codes aligned to the trailing edge.
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

    return ListView.separated(
      padding: padding,
      itemCount: roots.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _AccountSection(
              node: roots[index],
              expandedIds: expandedIds,
              selectedId: selectedId,
              onToggleExpand: onToggleExpand,
              onSelect: onSelect,
              onOpenDetails: onOpenDetails,
            )
            .animate(delay: (40 * index).ms)
            .fadeIn(duration: 220.ms, curve: Curves.easeOut)
            .moveY(
              begin: 10,
              end: 0,
              duration: 240.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.node,
    required this.expandedIds,
    required this.onToggleExpand,
    this.selectedId,
    this.onSelect,
    this.onOpenDetails,
  });

  final AccountTreeNode node;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggleExpand;
  final String? selectedId;
  final ValueChanged<Account>? onSelect;
  final ValueChanged<Account>? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final account = node.account;
    final typeColor = accountTypeColor(theme.colorScheme, account.accountType);
    final expanded = expandedIds.contains(account.uuid);
    final childEntries = expanded
        ? AccountTreeNode.flatten(
            node.children,
            expandedIds: expandedIds,
            selectedId: selectedId,
          )
        : const <AccountTreeFlatEntry>[];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: typeColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10,
              ),
              child: InkWell(
                onTap: node.hasChildren
                    ? () => onToggleExpand(account.uuid)
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
                              maxLines: 1,
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
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: typeColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                if (node.hasChildren) ...[
                                  Text(
                                    ' · ',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    l10n.accountingSectionChildrenCount(
                                      _countDescendants(node),
                                    ),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
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
            if (expanded && childEntries.isNotEmpty) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              for (var i = 0; i < childEntries.length; i++) ...[
                _AccountChildRow(
                  entry: childEntries[i],
                  typeColor: typeColor,
                  onToggleExpand: childEntries[i].node.hasChildren
                      ? () => onToggleExpand(childEntries[i].account.uuid)
                      : null,
                  onOpenDetails: onOpenDetails == null
                      ? null
                      : () => onOpenDetails!(childEntries[i].account),
                  onSelect: onSelect == null
                      ? null
                      : () => onSelect!(childEntries[i].account),
                ),
                if (i < childEntries.length - 1)
                  Divider(
                    height: 1,
                    indent:
                        AppSpacing.lg +
                        (childEntries[i].depth + 1) * AppSpacing.md,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int _countDescendants(AccountTreeNode node) {
    var count = 0;
    void walk(AccountTreeNode n) {
      for (final child in n.children) {
        count++;
        walk(child);
      }
    }

    walk(node);
    return count;
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
    final depthInset = (entry.depth + 1) * AppSpacing.md;
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
            start: AppSpacing.md + depthInset,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: account.isGroup
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: account.isActive
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
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
      constraints: const BoxConstraints(minWidth: 56),
      padding: EdgeInsets.symmetric(
        horizontal: emphasis ? 10 : 8,
        vertical: emphasis ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: emphasis ? 13 : 12,
        ),
      ),
    );
  }
}
