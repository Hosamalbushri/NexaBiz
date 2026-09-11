import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Single item descriptor for module hub pages.
class AppModuleHubItem {
  const AppModuleHubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Duration animationDelay;
}

/// Single item tile for module hub service grids.
class AppModuleHubTile extends StatelessWidget {
  const AppModuleHubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool animate;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final card = Semantics(
      container: true,
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: AppShadows.card(brightness),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.16),
                          colorScheme.secondary.withValues(alpha: 0.10),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(icon, color: colorScheme.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!animate) {
      return card;
    }

    return card
        .animate(delay: animationDelay)
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.04, end: 0, duration: 260.ms);
  }
}

/// Responsive grid layout for module hub pages.
class AppModuleHubGrid extends StatelessWidget {
  const AppModuleHubGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = AppSpacing.md,
    this.mainAxisSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

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

        final childAspectRatio = AppBreakpoints.isMobile(width) ? 0.80 : 0.90;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Dual-mode layout widget rendering either a Grid or List of module items.
class AppModuleHubView extends StatelessWidget {
  const AppModuleHubView({
    super.key,
    required this.isGrid,
    required this.children,
  });

  final bool isGrid;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return AppModuleHubGrid(children: children);
    }

    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          children[i],
        ],
      ],
    );
  }
}

/// Standard Section Header with title, subtitle, and action toggle.
class AppModuleHubHeader extends StatelessWidget {
  const AppModuleHubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}
