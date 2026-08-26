import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/modules/inventory/shared/presentation/models/inventory_service_definition.dart';

/// Choose which inventory services appear on the hub and drag to reorder them.
class InventoryCustomizeSheet extends StatefulWidget {
  const InventoryCustomizeSheet({
    super.key,
    required this.availableServices,
    required this.initiallySelectedIds,
  });

  final List<InventoryServiceDefinition> availableServices;
  final List<String> initiallySelectedIds;

  @override
  State<InventoryCustomizeSheet> createState() =>
      _InventoryCustomizeSheetState();
}

class _InventoryCustomizeSheetState extends State<InventoryCustomizeSheet> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initiallySelectedIds);
  }

  void _toggle(InventoryServiceDefinition service) {
    setState(() {
      if (_selectedIds.contains(service.id)) {
        _selectedIds.remove(service.id);
      } else {
        _selectedIds.add(service.id);
      }
    });
  }

  void _onReorderItem(int oldIndex, int newIndex) {
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
      for (final service in widget.availableServices) service.id: service,
    };
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final unselected = [
      for (final service in widget.availableServices)
        if (!_selectedIds.contains(service.id)) service,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.inventoryCustomizeServices,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.inventoryCustomizeServicesHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.availableServices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l10n.inventoryNoServicesAvailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          if (selected.isNotEmpty) ...[
            Text(
              l10n.inventoryPinnedServices,
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
              onReorderItem: _onReorderItem,
              itemBuilder: (context, index) {
                final service = selected[index];
                return Material(
                  key: ValueKey<String>(service.id),
                  color: colorScheme.surface,
                  child: ListTile(
                    leading: Icon(service.icon, color: colorScheme.primary),
                    title: Text(service.title(l10n)),
                    subtitle: Text(
                      service.subtitle(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.inventoryRemoveService,
                          onPressed: () => _toggle(service),
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
              l10n.inventoryAvailableServices,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final service in unselected)
              ListTile(
                leading: Icon(
                  service.icon,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(service.title(l10n)),
                subtitle: Text(
                  service.subtitle(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: l10n.inventoryAddService,
                  onPressed: () => _toggle(service),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.inventorySaveServices,
          expand: true,
          onPressed: () =>
              Navigator.pop(context, List<String>.from(_selectedIds)),
        ),
      ],
    );
  }
}
