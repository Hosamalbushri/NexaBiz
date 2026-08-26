import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/system_setup_state.dart';
import 'system_setup_labels.dart';

class SystemSetupProgressHeader extends StatelessWidget {
  const SystemSetupProgressHeader({super.key, required this.progress});

  final SetupProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final percent = progress.percentComplete;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.systemSetupProgressLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                FractionallySizedBox(
                  widthFactor: (percent / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 4),
          Text(
            l10n.systemSetupStepsCompletedCount(
              progress.requiredDone,
              progress.requiredTotal,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SystemSetupStepTile extends StatelessWidget {
  const SystemSetupStepTile({
    super.key,
    required this.step,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final SetupStepState step;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompleted = step.status == SetupStepStatus.completed;

    final stepNumber = switch (step.id) {
      SetupStepId.locale => '1',
      SetupStepId.primaryCurrency => '2',
      SetupStepId.companyProfile => '3',
      SetupStepId.localAccount => '4',
      SetupStepId.seedData => '5',
    };

    final stepIcon = switch (step.id) {
      SetupStepId.locale => Icons.language_rounded,
      SetupStepId.primaryCurrency => Icons.payments_outlined,
      SetupStepId.companyProfile => Icons.business_rounded,
      SetupStepId.localAccount => Icons.admin_panel_settings_outlined,
      SetupStepId.seedData => Icons.dataset_outlined,
    };

    return Stack(
      children: [
        if (!isLast)
          Positioned(
            top: 48,
            bottom: 0,
            left: Localizations.localeOf(context).languageCode == 'ar' ? null : 27,
            right: Localizations.localeOf(context).languageCode == 'ar' ? 27 : null,
            child: Container(
              width: 2.5,
              color: isCompleted
                  ? scheme.primary.withValues(alpha: 0.6)
                  : scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Material(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : (isCompleted
                    ? scheme.surfaceContainerLow.withValues(alpha: 0.8)
                    : scheme.surface),
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : (isCompleted
                          ? scheme.primary.withValues(alpha: 0.35)
                          : scheme.outlineVariant.withValues(alpha: 0.3)),
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isCompleted
                    ? scheme.primary
                    : (selected
                        ? scheme.primary.withValues(alpha: 0.2)
                        : scheme.surfaceContainerHighest),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : (isCompleted ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5)),
                  width: selected ? 2.2 : 1.2,
                ),
                boxShadow: isCompleted || selected
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded, color: scheme.onPrimary, size: 22)
                    : Text(
                        stepNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  stepIcon,
                  size: 18,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    setupStepTitle(l10n, step.id),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                setupStepStatusLabel(l10n, step.status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCompleted
                      ? scheme.primary
                      : (selected ? scheme.primary : scheme.onSurfaceVariant),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: selected ? scheme.primary : scheme.outline,
            ),
            onTap: onTap,
          ),
        ),
      ),
    ),
  ],
);
  }
}
