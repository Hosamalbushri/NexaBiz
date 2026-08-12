import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../models/quick_action_definition.dart';

/// Choose which quick actions appear and drag to reorder them.
class QuickActionsCustomizeSheet extends StatefulWidget {
  const QuickActionsCustomizeSheet({
    super.key,
    required this.availableActions,
    required this.initiallySelectedIds,
  });

  final List<QuickActionDefinition> availableActions;
  final List<String> initiallySelectedIds;

  @override
  State<QuickActionsCustomizeSheet> createState() =>
      _QuickActionsCustomizeSheetState();
}

class _QuickActionsCustomizeSheetState
    extends State<QuickActionsCustomizeSheet> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(
      widget.initiallySelectedIds,
    ).take(kMaxQuickActions).toList(growable: true);
  }

  void _toggle(QuickActionDefinition action) {
    if (_selectedIds.contains(action.id)) {
      setState(() => _selectedIds.remove(action.id));
      return;
    }
    if (_selectedIds.length >= kMaxQuickActions) {
      showAppSnackBar(
        context,
        message: AppLocalizations.of(
          context,
        ).quickActionsMaxReached(kMaxQuickActions),
        isSuccess: false,
      );
      return;
    }
    setState(() => _selectedIds.add(action.id));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final id = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(newIndex, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final atLimit = _selectedIds.length >= kMaxQuickActions;
    final byId = {
      for (final action in widget.availableActions) action.id: action,
    };
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final unselected = [
      for (final action in widget.availableActions)
        if (!_selectedIds.contains(action.id)) action,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.quickActionsCustomizeTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.quickActionsCustomizeHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.quickActionsPinnedCount(_selectedIds.length, kMaxQuickActions),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: atLimit ? colorScheme.error : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (selected.isNotEmpty) ...[
          Text(
            l10n.quickActionsPinned,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: selected.length,
            onReorderItem: _onReorder,
            itemBuilder: (context, index) {
              final action = selected[index];
              return Material(
                key: ValueKey<String>(action.id),
                color: colorScheme.surface,
                child: ListTile(
                  leading: Icon(action.icon, color: colorScheme.primary),
                  title: Text(action.title(l10n)),
                  subtitle: Text(
                    action.subtitle(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.quickActionsRemove,
                        onPressed: () => _toggle(action),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        if (unselected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.quickActionsAvailable,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final action in unselected)
            ListTile(
              enabled: !atLimit,
              leading: Icon(
                action.icon,
                color: atLimit
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(action.title(l10n)),
              subtitle: Text(
                action.subtitle(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: l10n.quickActionsAdd,
                onPressed: atLimit ? null : () => _toggle(action),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.quickActionsSave,
          expand: true,
          onPressed: () =>
              Navigator.pop(context, List<String>.from(_selectedIds)),
        ),
      ],
    );
  }
}
