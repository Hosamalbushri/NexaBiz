import 'package:flutter/material.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/fiscal_year.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/models/fiscal_year_exception.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';

/// Periods table + FX summary for one fiscal year.
class FiscalYearDetailsPage extends ConsumerWidget {
  const FiscalYearDetailsPage({super.key, required this.fiscalYearUuid});

  final String fiscalYearUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fyAsync = ref.watch(fiscalYearByUuidProvider(fiscalYearUuid));
    final periodsAsync = ref.watch(fiscalYearPeriodsProvider(fiscalYearUuid));
    final closingsAsync = ref.watch(fiscalYearClosingsProvider(fiscalYearUuid));
    final auth = ref.watch(authStateProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingFiscalYearDetails,
        showBackButton: true,
      ),
      body: fyAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (fy) {
          if (fy == null) {
            return AppErrorState(message: l10n.somethingWentWrong);
          }
          return ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              Text(
                fy.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fy.code} · ${dateFmt.format(fy.startDate.toLocal())}'
                ' – ${dateFmt.format(fy.endDate.toLocal())}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountingFiscalYearFxSummary,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              closingsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (closings) {
                  var gain = 0.0;
                  var loss = 0.0;
                  for (final c in closings) {
                    if (c.status == PeriodClosingStatus.completed) {
                      gain += c.fxGain;
                      loss += c.fxLoss;
                    }
                  }
                  final net = gain - loss;
                  return Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FxRow(
                            label: l10n.accountingFiscalYearFxGains,
                            value: formatAppAmount(context, gain),
                          ),
                          _FxRow(
                            label: l10n.accountingFiscalYearFxLosses,
                            value: formatAppAmount(context, loss),
                          ),
                          _FxRow(
                            label: l10n.accountingFiscalYearFxNet,
                            value: formatAppAmount(context, net),
                            bold: true,
                          ),
                          if (fy.fxRevaluationEnabled) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.accountingFiscalYearFxDeferredHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              periodsAsync.when(
                loading: () => const AppLoading(),
                error: (e, _) => AppErrorState(message: e.toString()),
                data: (periods) {
                  return Column(
                    children: [
                      for (final period in periods) ...[
                        _PeriodTile(
                          period: period,
                          dateFmt: dateFmt,
                          canOpen: auth.hasPermission(
                            'accounting.fiscal_years.open_period',
                          ),
                          canClose: auth.hasPermission(
                            'accounting.fiscal_years.close_period',
                          ),
                          canReopen: auth.hasPermission(
                            'accounting.fiscal_years.reopen_period',
                          ),
                          onOpen: () => _openPeriod(context, ref, period),
                          onClose: () => _closePeriod(context, ref, period),
                          onReopen: () => _reopenPeriod(context, ref, period),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _actor(WidgetRef ref) {
    return ref.read(authStateProvider).session?.user.name ?? 'local';
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(fiscalYearPeriodsProvider(fiscalYearUuid));
    ref.invalidate(fiscalYearClosingsProvider(fiscalYearUuid));
    ref.invalidate(fiscalYearSummariesProvider);
    ref.invalidate(fiscalYearByUuidProvider(fiscalYearUuid));
  }

  Future<void> _openPeriod(
    BuildContext context,
    WidgetRef ref,
    AccountingPeriod period,
  ) async {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountingPeriodOpenConfirmTitle(period.name)),
          content: Text(
            l10n.accountingPeriodOpenConfirmMessage(
              dateFmt.format(period.startDate.toLocal()),
              dateFmt.format(period.endDate.toLocal()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(openAccountingPeriodUseCaseProvider).call(
            periodUuid: period.uuid,
            openedBy: _actor(ref),
          );
      _invalidate(ref);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingPeriodOpenSuccess,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _closePeriod(
    BuildContext context,
    WidgetRef ref,
    AccountingPeriod period,
  ) async {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(periodClosingServiceProvider);
    PeriodClosingPreflight preflight;
    try {
      preflight = await service.preflight(period.uuid);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
      return;
    }
    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountingPeriodCloseTitle(period.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountingPeriodCloseUnposted(
                  preflight.unpostedJournalCount,
                ),
              ),
              if (preflight.missingExchangeRateCodes.isNotEmpty)
                Text(
                  l10n.accountingPeriodCloseMissingRates(
                    preflight.missingExchangeRateCodes.join(', '),
                  ),
                ),
              Text(
                '${l10n.accountingFiscalYearFxEnabled}: '
                '${preflight.fxRevaluationEnabled}',
              ),
              if (!preflight.canClose) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.accountingPeriodCloseBlocked,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: preflight.canClose
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(l10n.accountingPeriodClose),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await service.close(periodUuid: period.uuid, closedBy: _actor(ref));
      _invalidate(ref);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingPeriodCloseSuccess,
        isSuccess: true,
      );
    } on FiscalYearException catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _reopenPeriod(
    BuildContext context,
    WidgetRef ref,
    AccountingPeriod period,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountingPeriodReopenTitle(period.name)),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: l10n.accountingPeriodReopenReason,
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(reopenAccountingPeriodUseCaseProvider).call(
            periodUuid: period.uuid,
            reopenedBy: _actor(ref),
            reason: reason,
          );
      _invalidate(ref);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingPeriodReopenSuccess,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }
}

class _FxRow extends StatelessWidget {
  const _FxRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.period,
    required this.dateFmt,
    required this.canOpen,
    required this.canClose,
    required this.canReopen,
    required this.onOpen,
    required this.onClose,
    required this.onReopen,
  });

  final AccountingPeriod period;
  final DateFormat dateFmt;
  final bool canOpen;
  final bool canClose;
  final bool canReopen;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusLabel = switch (period.status) {
      AccountingPeriodStatus.closed => l10n.accountingPeriodStatusClosed,
      AccountingPeriodStatus.open => l10n.accountingPeriodStatusOpen,
      AccountingPeriodStatus.closing => l10n.accountingPeriodStatusClosing,
      AccountingPeriodStatus.reopened => l10n.accountingPeriodStatusReopened,
    };
    final tone = switch (period.status) {
      AccountingPeriodStatus.open || AccountingPeriodStatus.reopened =>
        AppStatusTone.success,
      AccountingPeriodStatus.closing => AppStatusTone.warning,
      AccountingPeriodStatus.closed => AppStatusTone.neutral,
    };

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${period.periodNumber}. ${period.name}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppStatusBadge(label: statusLabel, tone: tone, animate: false),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${dateFmt.format(period.startDate.toLocal())}'
              ' – ${dateFmt.format(period.endDate.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (period.status == AccountingPeriodStatus.closed && canOpen)
                  AppButton(
                    label: l10n.accountingPeriodOpen,
                    onPressed: onOpen,
                    variant: AppButtonVariant.tonal,
                  ),
                if (period.allowsPosting && canClose)
                  AppButton(
                    label: l10n.accountingPeriodClose,
                    onPressed: onClose,
                    variant: AppButtonVariant.outlined,
                  ),
                if (period.status == AccountingPeriodStatus.closed &&
                    canReopen)
                  AppButton(
                    label: l10n.accountingPeriodReopen,
                    onPressed: onReopen,
                    variant: AppButtonVariant.text,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
