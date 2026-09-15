import 'package:flutter/widgets.dart';

import '../theme/tokens/tokens.dart';
import 'app_breakpoints.dart';
import 'app_layout_tokens.dart';

/// Builder signature providing context, box constraints, and current breakpoint tier.
typedef AppResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  AppBreakpointTier tier,
);

/// Lightweight responsive container providing context and tier to child builders.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final AppResponsiveWidgetBuilder builder;

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

/// Unified multi-tier responsive layout builder supporting compact, medium, expanded, and wide tiers.
class AppResponsive extends StatelessWidget {
  const AppResponsive({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.wide,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  final WidgetBuilder? wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tier = AppBreakpoints.getTier(width);

        return switch (tier) {
          AppBreakpointTier.wide => (wide ?? expanded ?? medium ?? compact)(context),
          AppBreakpointTier.expanded => (expanded ?? medium ?? compact)(context),
          AppBreakpointTier.medium => (medium ?? compact)(context),
          AppBreakpointTier.compact => compact(context),
        };
      },
    );
  }
}

/// Legacy compatible mobile/tablet/desktop responsive builder.
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
    return AppResponsive(
      compact: mobile,
      medium: tablet ?? mobile,
      expanded: desktop ?? tablet ?? mobile,
      wide: desktop ?? tablet ?? mobile,
    );
  }
}

/// Automatically lays out child form fields into 1, 2, or 3 columns based on screen tier.
class AppResponsiveForm extends StatelessWidget {
  const AppResponsiveForm({
    super.key,
    required this.children,
    this.spacing = AppLayoutTokens.formFieldGap,
    this.runSpacing = AppLayoutTokens.formFieldGap,
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
