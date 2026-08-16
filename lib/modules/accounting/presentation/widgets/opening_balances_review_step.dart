import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/models/account_import_row.dart'
    show AccountImportException;
import '../../domain/services/account_import_opening_journal.dart';
import '../providers/account_opening_setup_provider.dart';
import '../providers/currency_rate_providers.dart';

/// Step 3: per-currency review and post opening journal vs Capital 3100.
class OpeningBalancesReviewStep extends ConsumerWidget {
  const OpeningBalancesReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountOpeningSetupProvider);
    final notifier = ref.read(accountOpeningSetupProvider.notifier);
    final defaultCurrency = ref
            .watch(companyProfileProvider)
            .valueOrNull
            ?.defaultCurrencyCode
            .trim()
            .toUpperCase() ??
        'SAR';
    final ratesAsync = ref.watch(currencyRateListProvider);
    final allowedCodes = ratesAsync.maybeWhen(
      data: (items) => {for (final item in items) item.currency.code},
      orElse: () => {defaultCurrency},
    );
    final summaries = state.currencySummaries(defaultCurrency);
    final withAmounts = state.balanceLines.where((l) => l.hasAmount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountingOpeningSetupStepReviewHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Text(
            l10n.accountingOpeningSetupCapitalOffset(
              AccountImportOpeningJournal.capitalAccountCode,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (withAmounts.isEmpty)
          AppCard(
            child: Text(l10n.accountingOpeningSetupNoAmountsToPost),
          )
        else ...[
          Text(
            l10n.accountingOpeningSetupReviewSummaryTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final summary in summaries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.currencyCode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.accountingImportOpeningDebit}: ${_fmt(summary.totalDebit)}',
                    ),
                    Text(
                      '${l10n.accountingImportOpeningCredit}: ${_fmt(summary.totalCredit)}',
                    ),
                    Text(
                      l10n.accountingOpeningSetupNetVsCapital(
                        _fmt(summary.netDebit.abs()),
                        summary.netDebit >= 0
                            ? l10n.accountingImportOpeningCredit
                            : l10n.accountingImportOpeningDebit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.accountingOpeningSetupLinesCount(withAmounts.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (state.isBusy && state.stepIndex == 2) ...[
          const SizedBox(height: AppSpacing.md),
          AppLoading(
            style: AppLoadingStyle.linear,
            message: l10n.accountingOpeningSetupPosting,
            progress: state.progress,
          ),
        ],
        if (state.postResult == true) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: Text(l10n.accountingOpeningSetupPostSuccess),
          ),
        ],
        if (state.errorCode != null && state.stepIndex == 2) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
            child: Text(
              _errorMessage(l10n, state.errorCode!, state.errorDetails),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.accountingOpeningSetupPostJournal,
          icon: Icons.playlist_add_check_rounded,
          expand: true,
          isLoading: state.isBusy && state.stepIndex == 2,
          onPressed: !state.canPostOpening
              ? null
              : () => unawaited(
                    notifier.postOpening(
                      voucherType: l10n.accountingImportOpeningVoucherType,
                      journalDescription:
                          l10n.accountingOpeningSetupJournalDescription,
                      allowedCurrencyCodes: allowedCodes,
                    ),
                  ),
        ),
      ],
    );
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _errorMessage(AppLocalizations l10n, String code, String? details) {
    return switch (code) {
      AccountImportException.bothOpeningSides =>
        l10n.accountingImportErrorBothSides,
      AccountImportException.duplicateCurrency =>
        l10n.accountingOpeningSetupErrorDuplicateCurrency(details ?? ''),
      AccountImportException.capitalMissing =>
        l10n.accountingImportErrorCapitalMissing,
      AccountImportException.noBalances =>
        l10n.accountingOpeningSetupNoAmountsToPost,
      AccountImportException.currencyNotConfigured =>
        l10n.accountingOpeningSetupErrorCurrencyNotConfigured(details ?? ''),
      AccountImportException.accountRequired =>
        l10n.accountingOpeningSetupErrorAccountRequired,
      _ => details?.isNotEmpty == true ? details! : code,
    };
  }
}
