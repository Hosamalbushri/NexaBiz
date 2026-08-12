import 'package:flutter/material.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/widgets/app_button.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// Pick and reorder which modules appear on the Dashboard.
///
/// List-based UI (same pattern as inventory customize) — distinct from the
/// quick-actions customize sheet.
class DashboardCustomizeSheet extends StatefulWidget {
  const DashboardCustomizeSheet({
    super.key,
    required this.availableModules,
    required this.initiallySelectedIds,
  });

  final List<AppModule> availableModules;
  final List<String> initiallySelectedIds;

  @override
  State<DashboardCustomizeSheet> createState() =>
      _DashboardCustomizeSheetState();
}

class _DashboardCustomizeSheetState extends State<DashboardCustomizeSheet> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initiallySelectedIds);
  }

  void _toggle(AppModule module) {
    setState(() {
      if (_selectedIds.contains(module.id)) {
        _selectedIds.remove(module.id);
      } else {
        _selectedIds.add(module.id);
      }
    });
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
    final byId = {
      for (final module in widget.availableModules) module.id: module,
    };
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final unselected = [
      for (final module in widget.availableModules)
        if (!_selectedIds.contains(module.id)) module,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.dashboardCustomizeTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.dashboardCustomizeServicesHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.availableModules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l10n.dashboardNoModulesAvailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          if (selected.isNotEmpty) ...[
            Text(
              l10n.dashboardPinnedServices,
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
                final module = selected[index];
                return Material(
                  key: ValueKey<String>(module.id),
                  color: colorScheme.surface,
                  child: ListTile(
                    leading: Icon(module.icon, color: colorScheme.primary),
                    title: Text(module.label(context)),
                    subtitle: module.description(context) == null
                        ? null
                        : Text(
                            module.description(context)!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.dashboardRemoveService,
                          onPressed: () => _toggle(module),
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
              l10n.dashboardAvailableServices,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final module in unselected)
              ListTile(
                leading: Icon(
                  module.icon,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(module.label(context)),
                subtitle: module.description(context) == null
                    ? null
                    : Text(
                        module.description(context)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: IconButton(
                  tooltip: l10n.dashboardAddService,
                  onPressed: () => _toggle(module),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l10n.cancel,
                variant: AppButtonVariant.outlined,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: l10n.dashboardSaveServices,
                expand: true,
                onPressed: () =>
                    Navigator.of(context).pop(List<String>.from(_selectedIds)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
