import 'package:flutter/material.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import 'service_card.dart';

/// Responsive grid of [ServiceCard] widgets.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.modules,
    required this.onModuleSelected,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;

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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
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
