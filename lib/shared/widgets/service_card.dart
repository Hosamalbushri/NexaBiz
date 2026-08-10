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
  });

  final AppModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = module.label(context);
    final subtitle = module.description(context);
    final enabled = module.isEnabled;
    final brightness = theme.brightness;

    return Semantics(
      button: true,
      enabled: enabled,
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
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: AppShadows.card(brightness),
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 150;
                    final iconBox = compact ? 56.0 : 72.0;
                    final iconSize = compact ? 28.0 : 36.0;
                    final gap = compact ? AppSpacing.sm : AppSpacing.md;
                    final showSubtitle = subtitle != null && !compact;

                    return Column(
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
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
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
                            fontSize: compact ? 14 : null,
                          ),
                        ),
                        if (showSubtitle) ...[
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
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    )
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
