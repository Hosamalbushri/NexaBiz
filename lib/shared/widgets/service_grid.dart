import 'package:flutter/material.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import 'service_add_card.dart';
import 'service_card.dart';

/// Responsive grid of [ServiceCard] widgets with an optional trailing add tile.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.modules,
    required this.onModuleSelected,
    this.onAddPressed,
    this.addLabel,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback? onAddPressed;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = AppBreakpoints.isDesktop(width)
            ? 4
            : AppBreakpoints.isTablet(width)
                ? 3
                : 2;
        final childAspectRatio = AppBreakpoints.isMobile(width) ? 0.82 : 0.95;
        final showAdd = onAddPressed != null;
        final itemCount = modules.length + (showAdd ? 1 : 0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            if (showAdd && index == modules.length) {
              return ServiceAddCard(
                onTap: onAddPressed!,
                label: addLabel,
              );
            }
            final module = modules[index];
            return ServiceCard(
              module: module,
              onTap: () => onModuleSelected(module),
            );
          },
        );
      },
    );
  }
}
