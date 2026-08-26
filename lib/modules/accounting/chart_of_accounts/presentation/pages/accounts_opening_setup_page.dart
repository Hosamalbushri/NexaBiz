import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../providers/account_opening_setup_provider.dart';
import '../widgets/accounts_import_step.dart';
import '../widgets/opening_balances_review_step.dart';
import '../widgets/opening_balances_step.dart';

/// Hub: Import accounts → Opening balances → Review & post.
class AccountsOpeningSetupPage extends ConsumerWidget {
  const AccountsOpeningSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountOpeningSetupProvider);
    final notifier = ref.read(accountOpeningSetupProvider.notifier);
    final step = state.stepIndex.clamp(0, 2);
    final labels = [
      l10n.accountingOpeningSetupStepImport,
      l10n.accountingOpeningSetupStepBalances,
      l10n.accountingOpeningSetupStepReview,
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.accountingOpeningSetupTitle,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: l10n.accountingOpeningSetupReset,
            onPressed: state.isBusy ? null : notifier.resetSession,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppConstants.pageInsets(context).copyWith(bottom: 0),
            child: _OpeningSetupStepBar(
              labels: labels,
              currentStep: step,
              enabled: !state.isBusy,
              onStepSelected: notifier.setStep,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: AppConstants.pageInsets(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.accountingOpeningSetupSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  switch (step) {
                    0 => const AccountsImportStep(),
                    1 => const OpeningBalancesStep(),
                    _ => const OpeningBalancesReviewStep(),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight top step tabs — avoids Material [Stepper] semantics layout bugs
/// when content lives outside the stepper.
class _OpeningSetupStepBar extends StatelessWidget {
  const _OpeningSetupStepBar({
    required this.labels,
    required this.currentStep,
    required this.enabled,
    required this.onStepSelected,
  });

  final List<String> labels;
  final int currentStep;
  final bool enabled;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _StepChip(
                  index: i,
                  label: labels[i],
                  selected: currentStep == i,
                  completed: currentStep > i,
                  enabled: enabled,
                  onTap: () => onStepSelected(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.selected,
    required this.completed,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final bool completed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected
        ? scheme.primary
        : completed
            ? scheme.primaryContainer
            : scheme.surface;
    final fg = selected
        ? scheme.onPrimary
        : completed
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (completed && !selected)
                Icon(Icons.check_rounded, size: 16, color: fg)
              else
                Text(
                  '${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
