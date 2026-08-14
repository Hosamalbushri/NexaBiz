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
    final EdgeInsets padding;
    final double preferredTitleSize;
    final FontWeight titleWeight;
    if (compact) {
      preferredIconBox = 40;
      preferredIconSize = 20;
      radius = AppRadius.md;
      padding = const EdgeInsets.all(AppSpacing.sm);
      preferredTitleSize = 12.5;
      titleWeight = FontWeight.w600;
    } else if (walletStyle || !showSubtitle) {
      preferredIconBox = walletStyle ? 96 : 56;
      preferredIconSize = walletStyle ? 58 : 28;
      radius = AppRadius.md;
      padding = const EdgeInsets.fromLTRB(6, 8, 6, 6);
      preferredTitleSize = walletStyle ? 13.5 : 13.5;
      titleWeight = FontWeight.w700;
    } else {
      preferredIconBox = 64;
      preferredIconSize = 30;
      radius = AppRadius.lg;
      padding = const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      );
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
              ? Colors.white.withValues(alpha: 0.06)
              : colorScheme.outlineVariant.withValues(alpha: 0.4))
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
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: padding,
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
                              ? 26.0
                              : (canShowSubtitle ? 52.0 : 34.0);
                          final gap = compact || walletStyle || !showSubtitle
                              ? 6.0
                              : 10.0;
                          final availableForIcon =
                              (maxH - titleReserve - gap).clamp(
                                24.0,
                                preferredIconBox,
                              );
                          final iconBox = availableForIcon
                              .clamp(24.0, maxW)
                              .toDouble();
                          // Wallet tiles: use nearly the full reserved icon area.
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

                          final iconWidget = walletStyle
                              ? Icon(
                                  module.icon,
                                  color: colorScheme.primary,
                                  size: iconSize,
                                )
                              : Container(
                                  width: iconBox,
                                  height: iconBox,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: isDark ? 0.18 : 0.09,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  child: Icon(
                                    module.icon,
                                    color: colorScheme.primary,
                                    size: iconSize,
                                  ),
                                );

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              iconWidget,
                              SizedBox(height: gap),
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: titleWeight,
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                    fontSize: titleSize,
                                  ),
                                ),
                              ),
                              if (canShowSubtitle) ...[
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.25,
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
                          );
                        },
                      ),
                    ),
                    if (selected)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: compact ? 16 : 18,
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
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
