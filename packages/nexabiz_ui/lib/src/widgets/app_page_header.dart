import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';

/// Canonical page header composite for NexaBiz ERP screens.
///
/// Layout structure:
/// - Right Side (`Alignment.centerRight`): Back Button & Header Actions
/// - Center (`Alignment.center`): Title & Subtitle (when [centerTitle] is true)
/// - Left Side (`Alignment.centerLeft`): Filter Button (or custom leading widget)
///
/// Both Back and Filter buttons use the exact same [_HeaderActionButton] primitive.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton,
    this.onBack,
    this.onFilterTap,
    this.filterCount = 0,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadcnTheme = shadcn.Theme.of(context);

    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBackButton ?? canPop;

    final backButton = shouldShowBack
        ? _HeaderActionButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'رجوع',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          )
        : null;

    final filterButton = onFilterTap != null
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderActionButton(
                icon: Icons.tune_rounded,
                tooltip: 'تصفية',
                onPressed: onFilterTap,
                isActive: filterCount > 0,
              ),
              if (filterCount > 0)
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          )
        : null;

    final leftWidget = leading ?? filterButton;

    final rightCluster = <Widget>[
      if (backButton != null) backButton,
      if (actions != null) ...actions!,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            Row(
              mainAxisAlignment:
                  centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                for (int i = 0; i < breadcrumbs!.length; i++) ...[
                  Text(
                    breadcrumbs![i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: i == breadcrumbs!.length - 1
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: i == breadcrumbs!.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (i < breadcrumbs!.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Top Header Row with centered title, left-aligned filter, and right-aligned back button
          Stack(
            alignment: Alignment.center,
            children: [
              if (leftWidget != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: leftWidget,
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: leftWidget != null || rightCluster.isNotEmpty ? 52.0 : 0.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ) ??
                          shadcnTheme.typography.large.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign:
                            centerTitle ? TextAlign.center : TextAlign.start,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ) ??
                            shadcnTheme.typography.small.copyWith(
                              color: shadcnTheme.colorScheme.mutedForeground,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (rightCluster.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < rightCluster.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        rightCluster[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Header action button mirroring the exact [CustomAppBarAction] design.
class _HeaderActionButton extends StatefulWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final accent = widget.isActive ? scheme.primary : scheme.primary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Material(
            color: scheme.primary.withValues(alpha: widget.isActive ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (val) => setState(() => _pressed = val),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
