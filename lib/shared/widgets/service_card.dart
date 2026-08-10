import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import '../../core/widgets/app_status_badge.dart';

/// Card representing a single business module on the service launcher.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.module,
    required this.onTap,
    this.compact = false,
    this.selected = false,
    this.showSubtitle = true,
    this.animate = true,
  });

  final AppModule module;
  final VoidCallback onTap;

  /// Forces a denser layout (icon + name only).
  final bool compact;

  /// Highlights the card as selected (used by dashboard customize).
  final bool selected;

  /// When false, never shows the module description.
  final bool showSubtitle;

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = module.label(context);
    final subtitle = module.description(context);
    final enabled = module.isEnabled;
    final brightness = theme.brightness;

    final card = Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: AppShadows.card(brightness),
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      compact ? AppSpacing.xs : AppSpacing.sm,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final autoCompact =
                            compact || constraints.maxHeight < 150;
                        final iconBox = compact
                            ? 40.0
                            : autoCompact
                                ? 56.0
                                : 72.0;
                        final iconSize = compact
                            ? 22.0
                            : autoCompact
                                ? 28.0
                                : 36.0;
                        final gap = compact
                            ? AppSpacing.xs
                            : autoCompact
                                ? AppSpacing.sm
                                : AppSpacing.md;
                        final canShowSubtitle = showSubtitle &&
                            !compact &&
                            subtitle != null &&
                            !autoCompact;

                        return SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary
                                          .withValues(alpha: 0.16),
                                      colorScheme.secondary
                                          .withValues(alpha: 0.10),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                                child: SizedBox(
                                  width: iconBox,
                                  height: iconBox,
                                  child: Icon(
                                    module.icon,
                                    color: colorScheme.primary,
                                    size: iconSize,
                                  ),
                                ),
                              ),
                              SizedBox(height: gap),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.15,
                                  fontSize: compact
                                      ? 12
                                      : autoCompact
                                          ? 14
                                          : null,
                                ),
                              ),
                              if (canShowSubtitle) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                              if (!enabled) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AppStatusBadge(
                                  label: l10n.moduleComingSoon,
                                  tone: AppStatusTone.neutral,
                                  animate: false,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (selected)
                    PositionedDirectional(
                      top: compact ? 4 : 8,
                      end: compact ? 4 : 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: compact ? 16 : 20,
                        color: colorScheme.primary,
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
        .animate()
        .fadeIn(duration: 220.ms)
        .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
