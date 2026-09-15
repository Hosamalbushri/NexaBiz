import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'app_layout_tokens.dart';
import 'app_responsive.dart';

/// Unified grid layout system supporting responsive column calculations.
class AppGrid extends StatelessWidget {
  const AppGrid({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.wideColumns = 4,
    this.spacing = AppLayoutTokens.dashboardGridGap,
    this.runSpacing = AppLayoutTokens.dashboardGridGap,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final int wideColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, tier) {
        final columns = switch (tier) {
          AppBreakpointTier.compact => compactColumns,
          AppBreakpointTier.medium => mediumColumns,
          AppBreakpointTier.expanded => expandedColumns,
          AppBreakpointTier.wide => wideColumns,
        };

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }

        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
