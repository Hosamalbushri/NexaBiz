import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_exception_messages.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';

/// Full journal entry detail (header + lines).
class JournalEntryDetailsPage extends ConsumerWidget {
  const JournalEntryDetailsPage({super.key, required this.entryUuid});

  final String entryUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(journalEntryByUuidProvider(entryUuid));
    final dateFormat = DateFormat.yMMMd();

    return async.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingJournalDetails,
          showBackButton: true,
        ),
        body: const AppLoading(),
      ),
      error: (_, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingJournalDetails,
          showBackButton: true,
        ),
        body: Center(child: Text(l10n.somethingWentWrong)),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.accountingJournalDetails,
              showBackButton: true,
            ),
            body: Center(child: Text(l10n.accountingJournalNotFound)),
          );
        }

        final linked =
            entry.sourceType != null && entry.sourceType!.trim().isNotEmpty;
        final totalDebit = entry.lines.fold<double>(0, (s, l) => s + l.debit);
        final totalCredit = entry.lines.fold<double>(0, (s, l) => s + l.credit);

        return Scaffold(
          appBar: CustomAppBar(
            title: entry.voucherNumber,
            showBackButton: true,
            actions: [
              if (!linked)
                IconButton(
                  tooltip: l10n.accountingJournalEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => AccountingRoutes.pushJournalEdit(
                    context,
                    entry.uuid,
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.voucherType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AppStatusBadge(
                          label: entry.isPosted
                              ? l10n.accountingJournalPosted
                              : l10n.accountingJournalUnposted,
                          tone: entry.isPosted
                              ? AppStatusTone.success
                              : AppStatusTone.warning,
                          animate: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _row(
                      l10n.accountingJournalFieldDate,
                      dateFormat.format(entry.entryDate.toLocal()),
                    ),
                    _row(
                      l10n.accountingJournalFieldCurrency,
                      entry.currencyCode,
                    ),
                    if (entry.description != null &&
                        entry.description!.trim().isNotEmpty)
                      _row(
                        l10n.accountingJournalFieldDescription,
                        entry.description!,
                      ),
                    if (linked)
                      _row(
                        l10n.accountingJournalFieldStatus,
                        l10n.accountingJournalSourceLinked(
                          entry.sourceType!,
                        ),
                      ),
                    _row(
                      l10n.accountingJournalTotals,
                      '${totalDebit.toStringAsFixed(2)} / ${totalCredit.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountingJournalLines,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final line in entry.lines) ...[
                AppCard(
                  child: _LineTile(line: line),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.accountingJournalVoid,
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: () => _voidEntry(context, ref, entry.uuid),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _voidEntry(
    BuildContext context,
    WidgetRef ref,
    String uuid,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountingJournalVoidConfirmTitle),
        content: Text(l10n.accountingJournalVoidConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountingJournalVoid),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(softDeleteJournalEntryUseCaseProvider).call(uuid);
      ref.invalidate(journalEntriesProvider);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingJournalVoidedSuccess,
        isSuccess: true,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        AccountingRoutes.goJournals(context);
      }
    } on JournalException catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: journalExceptionMessage(l10n, e),
        isSuccess: false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: journalExceptionMessage(l10n, e),
        isSuccess: false,
      );
    }
  }
}

class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line});

  final JournalLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountAsync = ref.watch(accountByUuidProvider(line.accountUuid));
    final accountLabel = accountAsync.maybeWhen(
      data: (account) => account == null
          ? line.accountUuid
          : '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}',
      orElse: () => line.accountUuid,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          accountLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${l10n.accountingJournalDebit}: ${line.debit.toStringAsFixed(2)}',
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${l10n.accountingJournalCredit}: ${line.credit.toStringAsFixed(2)}',
            ),
          ],
        ),
        if (line.lineDescription != null &&
            line.lineDescription!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            line.lineDescription!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
