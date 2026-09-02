import 'package:flutter/material.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';

/// Responsive form grid layout container for NexaBiz ERP.
///
/// Automatically rearranges form field children into:
/// - Mobile (< 600px): 1 column (vertical stack)
/// - Tablet (600px - 1000px): 2 columns
/// - Desktop (>= 1000px): 3 to 4 columns (capped by [maxColumns])
class AppFormGrid extends StatelessWidget {
  const AppFormGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.columnSpacing = AppSpacing.md,
    this.rowSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final int maxColumns;
  final double columnSpacing;
  final double rowSpacing;

  int _calculateColumns(double width) {
    if (width < AppBreakpoints.mobile) {
      return 1;
    }
    if (width < AppBreakpoints.tablet) {
      return 2;
    }
    if (width < AppBreakpoints.largeDesktop) {
      return maxColumns.clamp(1, 3);
    }
    return maxColumns.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _calculateColumns(constraints.maxWidth);
        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: rowSpacing),
                children[i],
              ],
            ],
          );
        }

        final rows = <List<Widget>>[];
        for (var i = 0; i < children.length; i += cols) {
          rows.add(
            children.sublist(
              i,
              (i + cols > children.length) ? children.length : i + cols,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: rowSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: columnSpacing),
                    Expanded(
                      child: c < rows[r].length
                          ? rows[r][c]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
