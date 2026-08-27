import 'package:flutter/material.dart';
import '../../app/constants/app_constants.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';

/// Builder signature providing context, layout constraints, and breakpoint tier.
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  AppBreakpointTier tier,
);

/// Lightweight responsive container providing tier context to child builders.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tier = AppBreakpoints.getTier(width);
        return builder(context, constraints, tier);
      },
    );
  }
}

/// Standardized multi-tier responsive layout widget.
class AppResponsiveLayout extends StatelessWidget {
  const AppResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (AppBreakpoints.isDesktop(width) && desktop != null) {
          return desktop!(context);
        }
        if (AppBreakpoints.isTablet(width) && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

/// Responsive form container that automatically lays out fields into 1, 2, or 3 columns.
class AppResponsiveForm extends StatelessWidget {
  const AppResponsiveForm({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, tier) {
        final columns = switch (tier) {
          AppBreakpointTier.compact => 1,
          AppBreakpointTier.medium => 2.clamp(1, maxColumns),
          AppBreakpointTier.expanded || AppBreakpointTier.wide => maxColumns,
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

        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

/// Wraps page or section content in a centered container with a maximum width
/// cap on tablet/desktop/web screens (defaults to [AppConstants.maxContentWidth]).
class AppContentConstraint extends StatelessWidget {
  const AppContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

