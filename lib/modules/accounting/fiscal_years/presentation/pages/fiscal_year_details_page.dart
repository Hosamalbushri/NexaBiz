import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/models/fiscal_year_exception.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

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

    return fyAsync.when(
      loading: () => AppDetailsPage(
        title: l10n.accountingFiscalYearDetails,
        isLoading: true,
      ),
      error: (e, _) => AppDetailsPage(
        title: l10n.accountingFiscalYearDetails,
        error: e.toString(),
        onRetry: () => ref.invalidate(fiscalYearByUuidProvider(fiscalYearUuid)),
      ),
      data: (fy) {
        if (fy == null) {
          return AppDetailsPage(
            title: l10n.accountingFiscalYearDetails,
            error: l10n.somethingWentWrong,
          );
        }
        return AppDetailsPage(
          title: fy.name,
          subtitle: '${fy.code} · ${dateFmt.format(fy.startDate.toLocal())}'
              ' – ${dateFmt.format(fy.endDate.toLocal())}',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          ),
        );
      },
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
            AppButton(
              label: l10n.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            AppButton(
              label: l10n.confirm,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(openAccountingPeriodUseCaseProvider)
          .call(periodUuid: period.uuid, openedBy: _actor(ref));
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
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            AppButton(
              label: l10n.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            AppButton(
              label: l10n.accountingPeriodClose,
              onPressed: preflight.canClose
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
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
            AppButton(
              label: l10n.cancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            AppButton(
              label: l10n.confirm,
              onPressed: () => Navigator.pop(dialogContext, true),
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
      await ref
          .read(reopenAccountingPeriodUseCaseProvider)
          .call(
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
  const _FxRow({required this.label, required this.value, this.bold = false});

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
      AccountingPeriodStatus.open ||
      AccountingPeriodStatus.reopened => AppStatusTone.success,
      AccountingPeriodStatus.closing => AppStatusTone.warning,
      AccountingPeriodStatus.closed => AppStatusTone.neutral,
    };

    return Semantics(
      label: '${period.periodNumber}. ${period.name}, $statusLabel',
      child: Material(
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
                  AppStatusBadge(
                    label: statusLabel,
                    tone: tone,
                    animate: false,
                  ),
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
      ),
    );
  }
}
