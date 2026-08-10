import 'package:flutter/material.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/widgets/service_card.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_spacing.dart';

/// Lets the user pick which enabled modules appear on the Dashboard.
///
/// Uses the same [ServiceCard] visual language as the dashboard, in compact size.
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
  late final List<String> _selectedIds;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.dashboardCustomizeServices,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.dashboardCustomizeServicesHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = AppBreakpoints.isDesktop(width)
                    ? 5
                    : AppBreakpoints.isTablet(width)
                        ? 4
                        : 3;

                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableModules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final module = widget.availableModules[index];
                    final selected = _selectedIds.contains(module.id);
                    return ServiceCard(
                      module: module,
                      compact: true,
                      selected: selected,
                      showSubtitle: false,
                      animate: false,
                      onTap: () => _toggle(module),
                    );
                  },
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),
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
                onPressed: () => Navigator.of(context)
                    .pop(List<String>.from(_selectedIds)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
