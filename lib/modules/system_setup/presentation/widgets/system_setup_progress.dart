import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.systemSetupProgressLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress.percentComplete / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.systemSetupPercent(progress.percentComplete),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
  });

  final SetupStepState step;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = switch (step.status) {
      SetupStepStatus.completed => Icons.check_circle,
      SetupStepStatus.failed => Icons.error_outline,
      SetupStepStatus.skipped => Icons.remove_circle_outline,
      SetupStepStatus.inProgress => Icons.timelapse,
      SetupStepStatus.pending => Icons.radio_button_unchecked,
    };
    final color = switch (step.status) {
      SetupStepStatus.completed => scheme.primary,
      SetupStepStatus.failed => scheme.error,
      SetupStepStatus.skipped => scheme.outline,
      SetupStepStatus.inProgress => scheme.tertiary,
      SetupStepStatus.pending => scheme.onSurfaceVariant,
    };

    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: color),
      title: Text(setupStepTitle(l10n, step.id)),
      subtitle: Text(setupStepStatusLabel(l10n, step.status)),
      onTap: onTap,
    );
  }
}
