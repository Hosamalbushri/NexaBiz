import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import '../../core/widgets/app_status_badge.dart';

/// Card representing a single business module on the service launcher /
/// dashboard.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.module,
    required this.onTap,
    this.compact = false,
    this.selected = false,
    this.showSubtitle = true,
    this.walletStyle = false,
    this.animate = true,
  });

  final AppModule module;
  final VoidCallback onTap;

  /// Forces the smallest layout (customize sheets).
  final bool compact;

  /// Highlights the card as selected (used by dashboard customize).
  final bool selected;

  /// When false, hides description and uses the professional dashboard tile.
  final bool showSubtitle;

  /// Flat wallet-home tile (solid surface, outline icon accent).
  final bool walletStyle;

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = module.label(context);
    final subtitle = module.description(context);
    final enabled = module.isEnabled;
    final isDark = theme.brightness == Brightness.dark;

    final double preferredIconBox;
    final double preferredIconSize;
    final double radius;
    final double preferredTitleSize;
    final FontWeight titleWeight;
    if (compact) {
      preferredIconBox = 40;
      preferredIconSize = 20;
      radius = AppRadius.md;
      preferredTitleSize = 12.5;
      titleWeight = FontWeight.w600;
    } else if (walletStyle || !showSubtitle) {
      preferredIconBox = walletStyle ? 52 : 56;
      preferredIconSize = walletStyle ? 30 : 28;
      radius = AppRadius.lg;
      preferredTitleSize = walletStyle ? 12.0 : 13.5;
      titleWeight = FontWeight.w700;
    } else {
      preferredIconBox = 64;
      preferredIconSize = 30;
      radius = AppRadius.lg;
      preferredTitleSize = 16;
      titleWeight = FontWeight.w700;
    }

    final tileColor = walletStyle
        ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F4F7))
        : colorScheme.surface;
    final tileBorder = selected
        ? colorScheme.primary
        : walletStyle
        ? (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colorScheme.outlineVariant.withValues(alpha: 0.35))
        : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55);

    final card = Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: title,
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(radius),
            splashColor: colorScheme.primary.withValues(alpha: 0.10),
            highlightColor: colorScheme.primary.withValues(alpha: 0.04),
            child: Ink(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: tileBorder,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: walletStyle
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.08 : 0.04,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    final maxW = constraints.maxWidth;
                    final canShowSubtitle =
                        showSubtitle &&
                        !compact &&
                        !walletStyle &&
                        subtitle != null &&
                        maxH >= 140;

                    final titleReserve = compact
                        ? 28.0
                        : walletStyle
                        ? 34.0
                        : (canShowSubtitle ? 42.0 : 30.0);
                    final gap = compact || walletStyle || !showSubtitle
                        ? 4.0
                        : 10.0;
                    final availableForIcon =
                        (maxH - titleReserve - gap).clamp(24.0, preferredIconBox);
                    final iconBox = availableForIcon.clamp(24.0, maxW).toDouble();
                    final iconSize = walletStyle
                        ? iconBox.clamp(24.0, preferredIconSize).toDouble()
                        : (iconBox *
                                      (preferredIconSize / preferredIconBox))
                                  .clamp(14.0, preferredIconSize)
                              .toDouble();
                    final titleSize = maxH < 90
                        ? (preferredTitleSize - 1.5).clamp(
                            11.0,
                            preferredTitleSize,
                          )
                        : preferredTitleSize;

                    if (walletStyle) {
                      return _WalletTileContent(
                        module: module,
                        iconBox: iconBox,
                        iconSize: iconSize,
                        title: title,
                        titleSize: titleSize,
                        titleWeight: titleWeight,
                        gap: gap,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        theme: theme,
                        selected: selected,
                        compact: compact,
                      );
                    }

                    return _DefaultTileContent(
                      module: module,
                      iconBox: iconBox,
                      iconSize: iconSize,
                      title: title,
                      subtitle: subtitle,
                      titleSize: titleSize,
                      titleWeight: titleWeight,
                      gap: gap,
                      canShowSubtitle: canShowSubtitle,
                      enabled: enabled,
                      l10n: l10n,
                      colorScheme: colorScheme,
                      theme: theme,
                      isDark: isDark,
                    );
                  },
                ),
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
        .animate()
        .fadeIn(duration: 220.ms)
        .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic);
  }
}

/// Professional wallet-style dashboard tile.
class _WalletTileContent extends StatelessWidget {
  const _WalletTileContent({
    required this.module,
    required this.iconBox,
    required this.iconSize,
    required this.title,
    required this.titleSize,
    required this.titleWeight,
    required this.gap,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
    required this.selected,
    required this.compact,
  });

  final AppModule module;
  final double iconBox;
  final double iconSize;
  final String title;
  final double titleSize;
  final FontWeight titleWeight;
  final double gap;
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Ambient glow behind icon.
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: iconBox * 1.6,
              height: iconBox * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.10 : 0.06),
                    primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Rounded-square icon container.
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(iconBox * 0.38),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.90)
                      : Colors.white,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  module.icon,
                  color: primary,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    fontSize: titleSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selected)
          PositionedDirectional(
            top: 5,
            end: 5,
            child: Container(
              width: compact ? 16 : 18,
              height: compact ? 16 : 18,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                size: compact ? 10 : 12,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Default service card content (service launcher / non-dashboard).
class _DefaultTileContent extends StatelessWidget {
  const _DefaultTileContent({
    required this.module,
    required this.iconBox,
    required this.iconSize,
    required this.title,
    this.subtitle,
    required this.titleSize,
    required this.titleWeight,
    required this.gap,
    required this.canShowSubtitle,
    required this.enabled,
    required this.l10n,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  final AppModule module;
  final double iconBox;
  final double iconSize;
  final String title;
  final String? subtitle;
  final double titleSize;
  final FontWeight titleWeight;
  final double gap;
  final bool canShowSubtitle;
  final bool enabled;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.18 : 0.09,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              module.icon,
              color: colorScheme.primary,
              size: iconSize,
            ),
          ),
          SizedBox(height: gap),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: titleWeight,
                letterSpacing: -0.2,
                height: 1.2,
                fontSize: 14,
              ),
            ),
          ),
          if (canShowSubtitle) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.80),
                  height: 1.35,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
          if (!enabled) ...[
            const SizedBox(height: 4),
            AppStatusBadge(
              label: l10n.moduleComingSoon,
              tone: AppStatusTone.neutral,
              animate: false,
            ),
          ],
        ],
      ),
    );
  }
}
