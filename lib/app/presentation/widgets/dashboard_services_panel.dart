import 'package:flutter/material.dart';

import '../../../core/modules/app_module.dart';
import '../../../shared/widgets/service_grid.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/dashboard_services_provider.dart';
import 'dashboard_stats_slider.dart';

/// Dashboard stack inspired by wallet home: cover-flow stats + service tiles.
class DashboardServicesPanel extends StatelessWidget {
  const DashboardServicesPanel({
    super.key,
    required this.modules,
    required this.onModuleSelected,
    required this.onCustomize,
    required this.customizeLabel,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback onCustomize;
  final String customizeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardStatsSlider(embedded: true),
        const SizedBox(height: AppSpacing.md),
        _PromoStrip(
          title: l10n.dashboardSubtitle,
          accent: colorScheme.primary,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              l10n.dashboardMyServices,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onCustomize,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(customizeLabel),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceGrid(
          modules: modules,
          showSubtitle: false,
          addLabel: customizeLabel,
          onAddPressed: onCustomize,
          onModuleSelected: onModuleSelected,
          fillWidth: true,
          walletStyle: true,
          maxSlots: kMaxDashboardServices,
        ),
      ],
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({
    required this.title,
    required this.accent,
    required this.isDark,
  });

  final String title;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;
    final on = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insights_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: on.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
