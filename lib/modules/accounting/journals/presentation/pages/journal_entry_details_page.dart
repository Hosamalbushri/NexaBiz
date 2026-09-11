import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_exception_messages.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Full journal entry detail (header + currency-grouped lines).
class JournalEntryDetailsPage extends ConsumerWidget {
  const JournalEntryDetailsPage({super.key, required this.entryUuid});

  final String entryUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
      error: (e, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingJournalDetails,
          showBackButton: true,
        ),
        body: AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(journalEntryByUuidProvider(entryUuid)),
        ),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.accountingJournalDetails,
              showBackButton: true,
            ),
            body: AppEmptyState(
              title: l10n.accountingJournalNotFound,
              icon: Icons.search_off_rounded,
            ),
          );
        }

        final linked =
            entry.sourceType != null && entry.sourceType!.trim().isNotEmpty;

        // Group lines by currency
        final Map<String, List<JournalLine>> groupedLines = {};
        for (final line in entry.lines) {
          final code = line.currencyCode.trim().toUpperCase();
          groupedLines.putIfAbsent(code, () => []).add(line);
        }

        final totalBaseDebit = entry.lines.fold<double>(
          0.0,
          (s, l) => s + l.baseDebit,
        );
        final totalBaseCredit = entry.lines.fold<double>(
          0.0,
          (s, l) => s + l.baseCredit,
        );

        return AppDetailPagePattern(
          title: entry.voucherNumber,
          actions: [
            if (!linked)
              IconButton(
                tooltip: l10n.accountingJournalEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    AccountingRoutes.pushJournalEdit(context, entry.uuid),
              ),
          ],
          summaryBanner: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header Card ---
              _HeaderCard(
                entry: entry,
                linked: linked,
                dateFormat: dateFormat,
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Currency-Grouped Lines ---
              for (final group in groupedLines.entries) ...[
                _CurrencyGroupCard(
                  currencyCode: group.key,
                  lines: group.value,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // --- Base Currency Totals Footer ---
              const SizedBox(height: AppSpacing.xs),
              _BaseTotalsFooter(
                totalBaseDebit: totalBaseDebit,
                totalBaseCredit: totalBaseCredit,
              ),

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

// ─── Header Card ────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.entry,
    required this.linked,
    required this.dateFormat,
  });

  final JournalEntry entry;
  final bool linked;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
          AppDetailInfoRow(
            label: l10n.accountingJournalFieldDate,
            value: dateFormat.format(entry.entryDate.toLocal()),
          ),
          AppDetailInfoRow(
            label: l10n.accountingJournalFieldCurrency,
            value: entry.currencyCode,
          ),
          if (entry.description != null &&
              entry.description!.trim().isNotEmpty)
            AppDetailInfoRow(
              label: l10n.accountingJournalFieldDescription,
              value: entry.description!,
            ),
          if (linked)
            AppDetailInfoRow(
              label: l10n.accountingJournalFieldStatus,
              value: l10n.accountingJournalSourceLinked(entry.sourceType!),
            ),
        ],
      ),
    );
  }
}

// ─── Currency Group Card ────────────────────────────────────────────────────

class _CurrencyGroupCard extends StatelessWidget {
  const _CurrencyGroupCard({
    required this.currencyCode,
    required this.lines,
  });

  final String currencyCode;
  final List<JournalLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = AppCurrencies.byCode(currencyCode);

    final double groupDebit = lines.fold(0.0, (sum, line) => sum + line.debit);
    final double groupCredit = lines.fold(0.0, (sum, line) => sum + line.credit);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Currency Header Strip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg - 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currency.nameAr} (${currency.code})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مدين: ${groupDebit.toStringAsFixed(2)} ${currency.symbol}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'دائن: ${groupCredit.toStringAsFixed(2)} ${currency.symbol}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lines List
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                for (final line in lines) ...[
                  _JournalLineRow(line: line, currencySymbol: currency.symbol),
                  if (line != lines.last) const Divider(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Journal Line Row ───────────────────────────────────────────────────────

class _JournalLineRow extends ConsumerWidget {
  const _JournalLineRow({
    required this.line,
    required this.currencySymbol,
  });

  final JournalLine line;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final accountAsync = ref.watch(accountByUuidProvider(line.accountUuid));

    final isDebit = line.debit > 0;
    final amount = isDebit ? line.debit : line.credit;
    final baseAmount = isDebit ? line.baseDebit : line.baseCredit;

    final accountTitle = accountAsync.maybeWhen(
      data: (account) => account == null
          ? line.accountUuid
          : '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}',
      orElse: () => line.accountUuid,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + account name
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.blue.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isDebit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: isDebit ? Colors.blue.shade800 : Colors.amber.shade900,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  accountTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          if (line.lineDescription != null &&
              line.lineDescription!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Text(
                line.lineDescription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // Amount row
          Padding(
            padding: const EdgeInsets.only(right: 36, top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isDebit ? "مدين" : "دائن"}: ${amount.toStringAsFixed(2)} $currencySymbol',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDebit ? Colors.blue.shade900 : Colors.amber.shade900,
                  ),
                ),
                if (line.exchangeRateToBase > 0 && line.exchangeRateToBase != 1.0)
                  Flexible(
                    child: Text(
                      'معادل: ${baseAmount.toStringAsFixed(2)} (×${line.exchangeRateToBase.toStringAsFixed(2)})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Base Currency Totals Footer ────────────────────────────────────────────

class _BaseTotalsFooter extends StatelessWidget {
  const _BaseTotalsFooter({
    required this.totalBaseDebit,
    required this.totalBaseCredit,
  });

  final double totalBaseDebit;
  final double totalBaseCredit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isBalanced = (totalBaseDebit - totalBaseCredit).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isBalanced
              ? Colors.green.shade300
              : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBalanced
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: isBalanced
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isBalanced ? 'القيد متوازن' : 'القيد غير متوازن',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBalanced
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${totalBaseDebit.toStringAsFixed(2)} / ${totalBaseCredit.toStringAsFixed(2)}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
