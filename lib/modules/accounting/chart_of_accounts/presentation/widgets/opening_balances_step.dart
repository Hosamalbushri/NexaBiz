import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import '../../domain/entities/account.dart';
import '../../domain/models/account_import_row.dart'
    show AccountImportException;
import '../../domain/models/opening_balance_line.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_opening_setup_provider.dart';
import '../providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_rate_providers.dart';
import 'opening_balances_table.dart';

/// Step 2: multi-currency opening balances for any posting account.
class OpeningBalancesStep extends ConsumerWidget {
  const OpeningBalancesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountOpeningSetupProvider);
    final notifier = ref.read(accountOpeningSetupProvider.notifier);
    final accountsAsync = ref.watch(accountsProvider);
    final ratesAsync = ref.watch(currencyRateListProvider);
    final defaultCurrency = ref
            .watch(companyProfileProvider)
            .valueOrNull
            ?.defaultCurrencyCode
            .trim()
            .toUpperCase() ??
        'SAR';

    final configuredCurrencies = ratesAsync.maybeWhen(
      data: (items) => [for (final item in items) item.currency],
      orElse: () => <AppCurrency>[AppCurrencies.byCode(defaultCurrency)],
    );
    final allowedCodes = {
      for (final currency in configuredCurrencies) currency.code,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountingOpeningSetupStepBalancesHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _BalancesFormatHintCard(),
        const SizedBox(height: AppSpacing.md),
        accountsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.somethingWentWrong),
          data: (accounts) {
            final posting = [
              for (final a in accounts)
                if (a.canPost) a,
            ];
            final selectedIds = {
              for (final line in state.balanceLines)
                if (line.accountId.isNotEmpty) line.accountId,
            };
            final availableToAdd = [
              for (final account in posting)
                if (!selectedIds.contains(account.uuid)) account,
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: DropdownButtonFormField<Account>(
                    // ignore: deprecated_member_use
                    value: null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.accountingOpeningSetupAddAccount,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: [
                      for (final account in availableToAdd)
                        DropdownMenuItem(
                          value: account,
                          child: Text(
                            '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: state.isBusy || availableToAdd.isEmpty
                        ? null
                        : (account) {
                            if (account != null) {
                              notifier.addAccountToBalances(
                                account,
                                defaultCurrencyCode: defaultCurrency,
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.accountingOpeningSetupImportBalancesExcel,
                  icon: Icons.upload_file_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: state.isBusy
                      ? null
                      : () => unawaited(
                            _pickBalancesFile(
                              context,
                              notifier,
                              allowedCodes: allowedCodes,
                              defaultCurrencyCode: defaultCurrency,
                            ),
                          ),
                ),
                if (state.balanceFileName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.selectedFileName}: ${state.balanceFileName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                OpeningBalancesTables(
                  groups: _groupByAccount(state.balanceLines),
                  configuredCurrencies: configuredCurrencies,
                  defaultCurrencyCode: defaultCurrency,
                  enabled: !state.isBusy,
                  onChanged: notifier.updateBalanceLine,
                  onRemoveLine: notifier.removeBalanceLine,
                  onRemoveAccount: notifier.removeAccountBalances,
                  onAddCurrencyLine: ({
                    required accountId,
                    required accountCode,
                    required accountName,
                  }) {
                    notifier.addNextCurrencyLine(
                      accountId: accountId,
                      accountCode: accountCode,
                      accountName: accountName,
                      allowedCurrencyCodes: allowedCodes.toList(),
                      defaultCurrencyCode: defaultCurrency,
                    );
                  },
                ),
              ],
            );
          },
        ),
        if (state.errorCode != null && state.stepIndex == 1) ...[
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
          label: l10n.accountingOpeningSetupContinueToReview,
          icon: Icons.arrow_forward_rounded,
          expand: true,
          onPressed: state.balanceLines.isEmpty
              ? null
              : () => notifier.setStep(2),
        ),
      ],
    );
  }

  List<OpeningBalanceAccountGroup> _groupByAccount(
    List<OpeningBalanceLine> lines,
  ) {
    final order = <String>[];
    final map = <String, List<OpeningBalanceLine>>{};
    for (final line in lines) {
      if (line.accountId.isEmpty) {
        continue;
      }
      if (!map.containsKey(line.accountId)) {
        order.add(line.accountId);
        map[line.accountId] = [];
      }
      map[line.accountId]!.add(line);
    }
    return [
      for (final id in order)
        OpeningBalanceAccountGroup(
          accountId: id,
          accountCode: map[id]!.first.accountCode,
          accountName: map[id]!.first.accountName,
          lines: map[id]!,
        ),
    ];
  }

  Future<void> _pickBalancesFile(
    BuildContext context,
    AccountOpeningSetupNotifier notifier, {
    required Set<String> allowedCodes,
    required String defaultCurrencyCode,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.invalidFile,
        isSuccess: false,
      );
      return;
    }
    await notifier.loadBalanceExcel(
      fileName: file.name,
      bytes: bytes,
      allowedCurrencyCodes: allowedCodes,
      defaultCurrencyCode: defaultCurrencyCode,
    );
  }

  String _errorMessage(AppLocalizations l10n, String code, String? details) {
    return switch (code) {
      AccountImportException.bothOpeningSides =>
        l10n.accountingImportErrorBothSides,
      AccountImportException.duplicateCurrency =>
        l10n.accountingOpeningSetupErrorDuplicateCurrency(
          details ?? '',
        ),
      AccountImportException.accountNotFound =>
        l10n.accountingOpeningSetupErrorAccountNotFound(details ?? ''),
      AccountImportException.currencyNotConfigured =>
        l10n.accountingOpeningSetupErrorCurrencyNotConfigured(details ?? ''),
      AccountImportException.accountRequired =>
        l10n.accountingOpeningSetupErrorAccountRequired,
      AccountImportException.noValidRows =>
        l10n.accountingOpeningSetupErrorNoBalanceRows,
      AccountImportException.emptyWorkbook => l10n.emptyWorkbook,
      AccountImportException.decodeFailed => l10n.invalidFile,
      _ => details?.isNotEmpty == true ? details! : code,
    };
  }
}

class _BalancesFormatHintCard extends StatelessWidget {
  const _BalancesFormatHintCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountingOpeningSetupBalancesFormatTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.accountingOpeningSetupBalancesFormatNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
