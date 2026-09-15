import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_icon_button.dart';

/// Resolved font size for page header titles based on title length,
/// matching the exact [CustomAppBarTitleSize] logic of the application.
double _resolveTitleFontSize(String title) {
  final length = title.trim().length;
  if (length <= 14) return 22.0;
  if (length <= 24) return 18.0;
  return 16.0;
}

/// Canonical page header composite for NexaBiz ERP screens built on [shadcn_flutter],
/// visually matching the application's canonical [CustomAppBar] formatting and scaling.
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
    this.useSurfaceContainer = true,
    this.onSearchTap,
    this.isSearching = false,
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
  final bool useSurfaceContainer;

  // Search parameters
  final VoidCallback? onSearchTap;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBackButton ?? canPop;

    final backButton = shouldShowBack
        ? AppIconButton(
            variant: AppIconButtonVariant.chip,
            iconSize: 18.0,
            icon: isRtl
                ? shadcn.LucideIcons.arrowRight
                : shadcn.LucideIcons.arrowLeft,
            tooltip: 'رجوع',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          )
        : null;

    final filterButton = onFilterTap != null
        ? AppIconButton(
            variant: AppIconButtonVariant.chip,
            iconSize: 18.0,
            icon: shadcn.LucideIcons.slidersHorizontal,
            tooltip: 'تصفية',
            badgeCount: filterCount > 0 ? filterCount : null,
            onPressed: onFilterTap,
          )
        : null;

    final searchButton = onSearchTap != null
        ? AppIconButton(
            variant: AppIconButtonVariant.chip,
            iconSize: 18.0,
            icon: isSearching ? shadcn.LucideIcons.x : shadcn.LucideIcons.search,
            tooltip: isSearching ? 'إغلاق البحث' : 'بحث',
            onPressed: onSearchTap,
          )
        : null;

    final startCluster = <Widget>[
      ?backButton,
      ?leading,
    ];

    final endCluster = <Widget>[
      ?searchButton,
      ?filterButton,
      ...?actions,
    ];

    final fontSize = _resolveTitleFontSize(title);

    final titleWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: centerTitle
          ? Alignment.center
          : AlignmentDirectional.centerStart,
      child: Text(
        title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        style: theme.typography.h3.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.05,
          color: colorScheme.foreground,
        ),
      ),
    );

    final headerContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              for (int i = 0; i < breadcrumbs!.length; i++) ...[
                Text(
                  breadcrumbs![i],
                  style: theme.typography.small.copyWith(
                    color: i == breadcrumbs!.length - 1
                        ? colorScheme.primary
                        : colorScheme.mutedForeground,
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
                      shadcn.LucideIcons.chevronRight,
                      size: 14,
                      color: colorScheme.mutedForeground,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        // Top Header Row matching CustomAppBar geometry and layout
        Stack(
          alignment: Alignment.center,
          children: [
            if (startCluster.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < startCluster.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      startCluster[i],
                    ],
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: startCluster.isNotEmpty || endCluster.isNotEmpty ? 52.0 : 0.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: centerTitle
                          ? Alignment.center
                          : AlignmentDirectional.centerStart,
                      child: Text(
                        subtitle!,
                        textAlign:
                            centerTitle ? TextAlign.center : TextAlign.start,
                        maxLines: 1,
                        style: theme.typography.xSmall.copyWith(
                          fontSize: 12.0,
                          color: colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (endCluster.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < endCluster.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      endCluster[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ],
    );

    if (!useSurfaceContainer) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: headerContent,
      );
    }

    final backgroundColor = isDark
        ? colorScheme.muted
        : colorScheme.card;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: 19.2,
            offset: const Offset(0, 3.6),
          ),
        ],
      ),
      child: headerContent,
    );
  }
}
